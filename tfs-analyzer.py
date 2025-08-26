#!/usr/bin/env python3
"""
Cross-platform TFS Ticket Analyzer
Supports Linux, macOS, and Windows

A comprehensive Python tool that analyzes your TFS tickets (both assigned and @mentioned) 
and provides intelligent priority rankings and action recommendations.
"""

import argparse
import json
import os
import sys
import subprocess
import webbrowser
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any
import configparser
import smtplib
from email.mime.text import MimeText
from email.mime.multipart import MimeMultipart
import tempfile
import shlex

try:
    import requests
    from requests.auth import HTTPBasicAuth
except ImportError:
    print("Error: 'requests' library not found. Install with: pip install requests")
    sys.exit(1)

class CrossPlatformConfig:
    """Handle configuration across different platforms"""
    
    def __init__(self):
        self.config_dir = self._get_config_dir()
        self.config_file = self.config_dir / '.tfs-analyzer-config'
        self.ensure_config_dir()
    
    def _get_config_dir(self) -> Path:
        """Get project-local config directory"""
        script_dir = Path(__file__).parent
        return script_dir / '.config'
    
    def ensure_config_dir(self):
        """Create config directory if it doesn't exist"""
        self.config_dir.mkdir(parents=True, exist_ok=True)
    
    def load_config(self) -> Dict[str, str]:
        """Load configuration from file"""
        if not self.config_file.exists():
            return {}
        
        config = configparser.ConfigParser()
        config.read(self.config_file)
        
        if 'tfs' not in config:
            return {}
            
        return dict(config['tfs'])
    
    def save_config(self, config_data: Dict[str, str]):
        """Save configuration to file"""
        config = configparser.ConfigParser()
        config['tfs'] = config_data
        
        with open(self.config_file, 'w') as f:
            config.write(f)
        
        # Set restrictive permissions on Unix-like systems
        if sys.platform != 'win32':
            os.chmod(self.config_file, 0o600)

class TFSAnalyzer:
    """Main TFS analysis class"""
    
    def __init__(self):
        self.config_manager = CrossPlatformConfig()
        self.config = self.config_manager.load_config()
        self.session = requests.Session()
        self.claude_config_file = Path(__file__).parent / '.config' / 'claude-code-config.json'
        
    def setup_config(self, use_windows_auth: bool = False):
        """Interactive configuration setup"""
        print("TFS Ticket Analyzer Setup TFS Ticket Analyzer Setup")
        print("=" * 40)
        
        tfs_url = input("TFS URL (e.g., https://tfs.company.com/tfs/Collection): ").strip()
        project_name = input("Project Name (e.g., MyProject): ").strip()
        
        config_data = {
            'tfs_url': tfs_url,
            'project_name': project_name,
            'use_windows_auth': str(use_windows_auth).lower()
        }
        
        if not use_windows_auth:
            pat = input("Personal Access Token: ").strip()
            config_data['pat'] = pat
            
        display_name = input("Your Display Name (for @mention detection): ").strip()
        config_data['user_display_name'] = display_name
        
        # Output method configuration
        print("\nDefault Output Method Default Output Method:")
        print("1. Browser (opens HTML in default browser)")
        print("2. HTML File (saves to Documents/Downloads)")
        print("3. Text File (saves plain text summary)")
        print("4. Console (displays in terminal)")
        print("5. Email (sends via SMTP)")
        
        choice = input("Choose default output method (1-5): ").strip()
        output_methods = {
            '1': 'browser',
            '2': 'html',
            '3': 'text', 
            '4': 'console',
            '5': 'email'
        }
        config_data['default_output'] = output_methods.get(choice, 'console')
        
        if choice == '5':
            self._setup_email_config(config_data)
        
        self.config_manager.save_config(config_data)
        self.config = config_data
        
        print(f"\n[OK] Configuration saved to: {self.config_manager.config_file}")
        print("Ready! Ready to analyze TFS tickets!")
    
    def _setup_email_config(self, config_data: Dict[str, str]):
        """Setup email configuration"""
        print("\nEmail Configuration Email Configuration:")
        email = input("Email Address: ").strip()
        password = input("Email Password: ").strip()
        
        # Common SMTP configurations
        smtp_configs = {
            'gmail.com': ('smtp.gmail.com', 587),
            'outlook.com': ('smtp.office365.com', 587),
            'office365.com': ('smtp.office365.com', 587),
            'yahoo.com': ('smtp.mail.yahoo.com', 587)
        }
        
        domain = email.split('@')[1].lower()
        if domain in smtp_configs:
            smtp_server, smtp_port = smtp_configs[domain]
            print(f"Using {smtp_server}:{smtp_port} for {domain}")
        else:
            smtp_server = input("SMTP Server: ").strip()
            smtp_port = int(input("SMTP Port (587/465): ").strip())
        
        config_data.update({
            'email_address': email,
            'email_password': password,
            'smtp_server': smtp_server,
            'smtp_port': str(smtp_port)
        })
    
    def test_claude_configuration(self):
        """Test Claude AI configuration with interactive setup guidance"""
        print("Testing Claude AI Configuration...")
        print("")
        
        # Step 1: Check if basic configuration exists
        if not self.config_manager.config_file.exists():
            print("[WARNING] No basic configuration found.")
            print("You need to run the initial setup first.")
            print("")
            setup_basic = input("Would you like to run the basic setup now? (y/n): ").strip().lower()
            if setup_basic == 'y':
                self.setup_config()
                return
            else:
                print("[ERROR] Cannot test Claude without basic configuration.")
                return
        
        print("[OK] Basic configuration found")
        
        # Step 2: Test authentication availability
        print("")
        print("Checking Authentication...")
        
        az_auth_working = False
        pat_available = False
        
        # Test Azure CLI
        try:
            result = subprocess.run(['az', 'account', 'get-access-token', '--resource', 'https://dev.azure.com'], 
                                  capture_output=True, text=True, check=True)
            if result.stdout and 'accessToken' in result.stdout:
                print("[OK] Azure CLI is authenticated and working")
                az_auth_working = True
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass
        
        # Test PAT availability  
        if self.config.get('pat') and self.config['pat'].strip():
            print("[OK] Personal Access Token is configured")
            pat_available = True
        
        # If no authentication method is available, guide user to set it up
        if not az_auth_working and not pat_available:
            print("[WARNING] No authentication method is available!")
            print("")
            print("AUTHENTICATION SETUP REQUIRED:")
            print("You need at least one authentication method to use Claude AI.")
            print("")
            print("OPTION 1 (RECOMMENDED): Azure CLI")
            print("  1. Run: az login --allow-no-subscriptions")
            print("  2. Follow the browser authentication prompts")
            print("  3. Come back and run: python tfs-analyzer.py --test-claude")
            print("")
            print("OPTION 2: Personal Access Token (PAT)")
            print("  1. Run: python tfs-analyzer.py --setup")
            print("  2. Choose to configure PAT when prompted")
            print("  3. Come back and run: python tfs-analyzer.py --test-claude")
            print("")
            
            auth_choice = input("Would you like to set up Azure CLI authentication now? (y/n): ").strip().lower()
            if auth_choice == 'y':
                print("")
                print("Starting Azure CLI authentication...")
                print("This will open your browser for authentication...")
                
                try:
                    az_result = subprocess.run(['az', 'login', '--allow-no-subscriptions'], check=True)
                    if az_result.returncode == 0:
                        print("[OK] Azure CLI authentication completed!")
                        print("Run '--test-claude' again to verify the setup.")
                    else:
                        print("[ERROR] Azure CLI authentication failed.")
                        print("You can try the PAT setup instead: python tfs-analyzer.py --setup")
                except (subprocess.CalledProcessError, FileNotFoundError) as e:
                    print(f"[ERROR] Could not start Azure CLI authentication: {e}")
                    print("Please install Azure CLI or run: python tfs-analyzer.py --setup")
            else:
                print("You can set up authentication later with:")
                print("  - az login --allow-no-subscriptions (for Azure CLI)")
                print("  - python tfs-analyzer.py --setup (for PAT)")
            return
        
        # Step 3: Test Claude Code CLI
        print("")
        print("Testing Claude Code CLI...")
        
        try:
            subprocess.run(['claude-code', '--version'], 
                         capture_output=True, check=True)
            print("[OK] Claude Code CLI is available")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("[ERROR] Claude Code CLI not found")
            print("")
            print("CLAUDE CODE INSTALLATION REQUIRED:")
            print("1. Visit: https://claude.ai/code")
            print("2. Download and install Claude Code")
            print("3. Restart your terminal")
            print("4. Run: python tfs-analyzer.py --test-claude")
            return
        
        # Step 4: Test full Claude integration
        print("")
        print("Testing Claude AI Integration...")
        
        # Try a basic test of the authentication and MCP setup
        try:
            success, error_msg = self.invoke_claude_analysis([], 1, "console")
            if not success and "Claude Code CLI not found" not in error_msg:
                print("[OK] Claude AI integration is working")
                print("")
                print("[SUCCESS] Claude AI is fully configured and ready!")
                print("")
                print("Next Steps:")
                print("- Test with: python tfs-analyzer.py 1 -c -b")
                print("- Use -d flag for troubleshooting if needed")
                print("")
                print("Ready! Claude AI will enhance your ticket analysis!")
            else:
                print(f"[WARNING] Claude AI configuration has issues: {error_msg}")
                print("")
                print("Try these troubleshooting steps:")
                print("1. Run: python tfs-analyzer.py --setup-claude")
                print("2. Verify Azure DevOps connectivity")
                print("3. Check Claude Code installation")
                print("4. Use -d flag for debug information")
        except Exception as e:
            print(f"[WARNING] Error testing Claude integration: {e}")
            print("")
            print("Try these troubleshooting steps:")
            print("1. Run: python tfs-analyzer.py --setup-claude")
            print("2. Verify Azure DevOps connectivity")
            print("3. Check Claude Code installation")
            print("4. Use -d flag for debug information")
    
    def setup_claude_config(self):
        """Setup Claude AI integration"""
        print("Claude AI Integration Setup")
        print("=" * 40)
        print("This will configure AI-powered ticket analysis with enhanced insights.")
        print()
        
        # Step 1: Test Claude Code availability
        try:
            result = subprocess.run(['claude-code', '--help'], 
                                 capture_output=True, text=True, check=True)
            print("[OK] Claude Code CLI found")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("[ERROR] Claude Code CLI not found. Please install Claude Code first:")
            print()
            print("Installation Installation Steps:")
            print("1. Visit: https://claude.ai/code")
            print("2. Download and install Claude Code")
            print("3. Follow the setup instructions")
            print("4. Restart your terminal")
            print("5. Run this setup again: python tfs-analyzer.py --setup-claude")
            print()
            return False
        
        # Step 2: Load existing configuration
        if not self.config:
            print("[ERROR] Main configuration not found. Please run: python tfs-analyzer.py --setup")
            return False
        
        print()
        print("Claude AI Features Claude AI Features:")
        print("- Intelligent priority assessment with AI reasoning")
        print("- Smart content summarization and key point extraction")
        print("- Actionable recommendations for next steps")
        print("- Impact analysis and risk assessment")
        print("- Enhanced decision tracking from ticket history")
        print()
        
        enable_claude = input("Enable Claude AI analysis by default? (y/n): ").strip().lower()
        use_claude_by_default = enable_claude in ['y', 'yes']
        
        # Step 3: Configure authentication
        print()
        print("Authentication Configuration Authentication Configuration:")
        print("Claude Code supports multiple authentication methods:")
        print("1. Azure CLI (Recommended) - Uses your current Azure login")
        print("2. Personal Access Token - Uses stored PAT from main config")
        print()
        
        # Test available authentication methods
        azure_cli_auth = False
        pat_available = bool(self.config.get('pat'))
        
        try:
            subprocess.run(['az', 'account', 'show'], 
                         capture_output=True, text=True, check=True)
            azure_cli_auth = True
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass
        
        print("Default Output Method Authentication Status:")
        if azure_cli_auth:
            print("[OK] Azure CLI: Authenticated and ready")
        else:
            print("[ERROR] Azure CLI: Not authenticated (run 'az login --allow-no-subscriptions')")
        
        if pat_available:
            print("[OK] PAT: Available from main configuration") 
        else:
            print("[ERROR] PAT: Not configured")
        
        print()
        auth_choice = input("Choose primary authentication method (1 for Azure CLI, 2 for PAT): ").strip()
        use_azure_cli = auth_choice == "1"
        
        if use_azure_cli and not azure_cli_auth:
            print("[WARNING]  Azure CLI selected but not authenticated.")
            print("Please run: az login --allow-no-subscriptions")
            print()
            continue_anyway = input("Continue with PAT as fallback? (y/n): ").strip().lower()
            if continue_anyway not in ['y', 'yes']:
                print("Setup cancelled. Please run 'az login --allow-no-subscriptions' and try again.")
                return False
            use_azure_cli = False
        
        if not use_azure_cli and not pat_available:
            print("[ERROR] No valid authentication method available.")
            print("Please either:")
            print("1. Run 'az login --allow-no-subscriptions' to authenticate Azure CLI, or")
            print("2. Run 'python tfs-analyzer.py --setup' to configure PAT")
            return False
        
        # Step 4: Configure Azure DevOps Organization URL
        print()
        print("Azure DevOps Configuration Azure DevOps Configuration:")
        azure_devops_org_url = input("Enter your Azure DevOps Organization URL (e.g., https://dev.azure.com/yourorg): ").strip()
        
        if not azure_devops_org_url:
            print("[ERROR] Azure DevOps Organization URL is required for Claude AI integration.")
            return False
        
        # Validate URL format
        try:
            from urllib.parse import urlparse
            parsed = urlparse(azure_devops_org_url)
            if not parsed.scheme or not parsed.netloc:
                raise ValueError("Invalid URL")
            if parsed.scheme != 'https':
                print("[WARNING]  Warning: HTTPS is recommended for security")
        except ValueError:
            print("[ERROR] Invalid URL format. Please enter a valid Azure DevOps URL.")
            return False
        
        # Step 5: Create Claude Code configuration
        print("Setting up Claude Code MCP server configuration...")
        
        # Ensure Claude config directory exists
        self.claude_config_file.parent.mkdir(parents=True, exist_ok=True)
        
        claude_config = {
            "mcpServers": {
                "azure-devops": {
                    "command": "npx",
                    "args": ["@anthropic/mcp-server-azure-devops"],
                    "env": {
                        "AZURE_DEVOPS_ORG_URL": azure_devops_org_url
                    }
                }
            }
        }
        
        # Save Claude Code configuration
        try:
            with open(self.claude_config_file, 'w') as f:
                json.dump(claude_config, f, indent=4)
            print(f"[OK] Claude Code MCP configuration created")
            
            # Create backup in script directory
            backup_path = Path(__file__).parent / 'claude-code-config.json'
            try:
                with open(backup_path, 'w') as f:
                    json.dump(claude_config, f, indent=4)
                print(f"[OK] Backup configuration created at: {backup_path}")
            except Exception:
                pass
                
        except Exception as e:
            print(f"[ERROR] Failed to save Claude configuration: {e}")
            return False
        
        # Step 6: Update main config with Claude AI settings
        self.config['use_claude_ai'] = 'true' if use_claude_by_default else 'false'
        self.config['azure_devops_org_url'] = azure_devops_org_url
        self.config['use_azure_cli'] = 'true' if use_azure_cli else 'false'
        self.config_manager.save_config(self.config)
        print("[OK] Claude AI configuration saved")
        
        # Step 7: Run comprehensive verification
        print()
        print("Running Configuration Verification Running Configuration Verification...")
        verification_passed = self.test_claude_configuration()
        
        if verification_passed:
            print()
            print("[SUCCESS] Claude AI integration setup completed successfully!")
            print()
            print("Next Steps Next Steps:")
            print("- Test with: python tfs-analyzer.py 1 -c -b")
            print("- Use -d flag for troubleshooting if needed")
            print("- Run --test-auth to verify authentication setup")
            print()
            print("Ready! Claude AI is now ready to enhance your ticket analysis!")
        else:
            print("[WARNING]  Setup completed with warnings. Some features may not work properly.")
            print()
            print("Troubleshooting Tips  Troubleshooting Tips:")
            print("- Run: python tfs-analyzer.py --test-claude")
            print("- Check authentication with: az login --allow-no-subscriptions")
            print("- Verify Claude Code installation")
            print("- Use -d flag for debug information")
        
        return True
    
    def test_auth(self) -> bool:
        """Test TFS authentication"""
        if not self.config:
            print("[ERROR] No configuration found. Run setup first.")
            return False
            
        try:
            url = f"{self.config['tfs_url']}/{self.config['project_name']}/_apis/wit/workitems?api-version=6.0"
            
            if self.config.get('use_windows_auth', 'false').lower() == 'true':
                # Use current user credentials (Windows/Kerberos)
                from requests_ntlm import HttpNtlmAuth
                import getpass
                username = getpass.getuser()
                self.session.auth = HttpNtlmAuth(username, '')
            else:
                # Use PAT authentication
                self.session.auth = HTTPBasicAuth('', self.config['pat'])
            
            response = self.session.get(url)
            
            if response.status_code == 200:
                print("[OK] Authentication successful!")
                return True
            else:
                print(f"[ERROR] Authentication failed: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"[ERROR] Connection failed: {e}")
            return False
    
    def get_work_items(self, days: int) -> List[Dict[str, Any]]:
        """Retrieve work items from TFS"""
        if not self.config:
            raise Exception("Configuration not found. Run setup first.")
        
        # Calculate date range
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        # Build WIQL query
        wiql_query = f"""
        SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType],
               [System.AssignedTo], [System.Priority], [Microsoft.VSTS.Common.Severity],
               [System.Description], [System.Tags], [System.CreatedDate], [System.ChangedDate]
        FROM workitems 
        WHERE [System.TeamProject] = '{self.config['project_name']}'
        AND ([System.AssignedTo] = '{self.config['user_display_name']}'
             OR [System.History] CONTAINS '@{self.config['user_display_name']}')
        AND [System.ChangedDate] >= '{start_date.isoformat()}'
        ORDER BY [System.Priority] ASC, [System.ChangedDate] DESC
        """
        
        # Execute WIQL query
        wiql_url = f"{self.config['tfs_url']}/{self.config['project_name']}/_apis/wit/wiql?api-version=6.0"
        
        wiql_request = {"query": wiql_query}
        
        try:
            response = self.session.post(wiql_url, json=wiql_request)
            response.raise_for_status()
            
            work_items_result = response.json()
            work_item_ids = [item['id'] for item in work_items_result.get('workItems', [])]
            
            if not work_item_ids:
                return []
            
            # Get detailed work item information
            ids_param = ','.join(map(str, work_item_ids))
            details_url = f"{self.config['tfs_url']}/{self.config['project_name']}/_apis/wit/workitems?ids={ids_param}&$expand=all&api-version=6.0"
            
            details_response = self.session.get(details_url)
            details_response.raise_for_status()
            
            return details_response.json().get('value', [])
            
        except requests.RequestException as e:
            print(f"[ERROR] Error retrieving work items: {e}")
            return []
    
    def calculate_priority_score(self, work_item: Dict[str, Any]) -> tuple:
        """Calculate priority score and classification"""
        fields = work_item.get('fields', {})
        score = 0
        
        # State weight
        state = fields.get('System.State', '').lower()
        state_weights = {
            'in progress': 5, 'active': 4, 'new': 3, 
            'committed': 3, 'to do': 2, 'done': 1, 'closed': 1
        }
        score += state_weights.get(state, 0)
        
        # Work item type weight
        work_type = fields.get('System.WorkItemType', '').lower()
        type_weights = {'bug': 3, 'task': 2, 'product backlog item': 2, 'epic': 1}
        score += type_weights.get(work_type, 0)
        
        # Priority field
        priority = fields.get('System.Priority')
        if priority:
            score += max(0, 5 - int(priority))
        
        # Severity field
        severity = fields.get('Microsoft.VSTS.Common.Severity')
        if severity:
            severity_weights = {'1 - critical': 4, '2 - high': 3, '3 - medium': 2, '4 - low': 1}
            score += severity_weights.get(severity.lower(), 0)
        
        # Keyword analysis
        title = fields.get('System.Title', '').lower()
        description = fields.get('System.Description', '').lower()
        text_content = f"{title} {description}"
        
        high_keywords = ['showstopper', 'critical', 'urgent', 'blocker', 'production', 'down', 'crash']
        medium_keywords = ['error', 'exception', 'fail', 'broken', 'issue']
        
        if any(keyword in text_content for keyword in high_keywords):
            score += 3
        elif any(keyword in text_content for keyword in medium_keywords):
            score += 2
        
        # Classify priority
        if score >= 8:
            priority_level = "HIGH"
        elif score >= 5:
            priority_level = "MEDIUM" 
        else:
            priority_level = "LOW"
            
        return score, priority_level
    
    def analyze_content(self, work_item: Dict[str, Any]) -> Dict[str, str]:
        """Perform intelligent content analysis"""
        fields = work_item.get('fields', {})
        
        title = fields.get('System.Title', '')
        description = fields.get('System.Description', '')
        work_type = fields.get('System.WorkItemType', '')
        state = fields.get('System.State', '')
        
        analysis = {
            'summary': f"{work_type}: {title}",
            'key_points': self._extract_key_points(description),
            'action_items': self._get_action_recommendation(work_type, state),
            'impact_assessment': self._assess_impact(work_type, title, description)
        }
        
        return analysis
    
    def _extract_key_points(self, description: str) -> str:
        """Extract key points from description"""
        if not description:
            return "No description provided"
        
        # Simple extraction - look for bullet points, numbered lists, or key phrases
        lines = description.split('\n')
        key_lines = []
        
        for line in lines:
            line = line.strip()
            if (line.startswith('-') or line.startswith('*') or 
                line.startswith('-') or any(line.startswith(f"{i}.") for i in range(1, 10))):
                key_lines.append(line)
        
        return '\n'.join(key_lines[:5]) if key_lines else description[:200] + "..."
    
    def _get_action_recommendation(self, work_type: str, state: str) -> str:
        """Get action recommendation based on work item type and state"""
        recommendations = {
            ('Bug', 'New'): "Investigate and reproduce the issue",
            ('Bug', 'Active'): "Continue debugging and provide status updates",
            ('Bug', 'In Progress'): "Focus on completing the fix",
            ('Task', 'To Do'): "Schedule work and move to Active",
            ('Task', 'Active'): "Continue work and provide status updates", 
            ('Task', 'In Progress'): "Focus on completing current tasks"
        }
        
        return recommendations.get((work_type, state), f"Continue work on {work_type.lower()}")
    
    def _assess_impact(self, work_type: str, title: str, description: str) -> str:
        """Assess potential impact of the work item"""
        text = f"{title} {description}".lower()
        
        if work_type.lower() == 'bug':
            if any(word in text for word in ['crash', 'error', 'exception', 'fail']):
                return "High - Potential system stability impact"
            elif any(word in text for word in ['ui', 'display', 'visual']):
                return "Medium - User experience impact"
            else:
                return "Low to Medium - Functional impact"
        else:
            if any(word in text for word in ['performance', 'security', 'data']):
                return "High - Core system impact"
            else:
                return "Medium - Feature/functionality impact"
    
    def invoke_claude_analysis(self, work_items: List[Dict[str, Any]], days: int, output_type: str) -> tuple[bool, str]:
        """Invoke Claude AI for enhanced analysis"""
        # Count total work items for progress indication
        total_count = len(work_items)
        
        # Progress indicator setup
        print(f"Claude AI will analyze {total_count} ticket(s) for enhanced insights...")
        print("  [INFO] This may take a few minutes depending on ticket count and complexity", file=sys.stderr)
        print("  [AI] Analyzing all tickets with Claude AI...", end="", flush=True, file=sys.stderr)
        
        # Step 1: Verify Claude Code is available
        try:
            subprocess.run(['claude-code', '--version'], 
                         capture_output=True, check=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            error_msg = "Claude Code CLI not found. Run setup-claude first."
            return False, error_msg
        
        # Step 2: Verify authentication
        auth_available = False
        try:
            # Try Azure CLI first
            subprocess.run(['az', 'account', 'show'], 
                         capture_output=True, text=True, check=True)
            print("[OK] Using Azure CLI authentication for Claude analysis")
            auth_available = True
        except (subprocess.CalledProcessError, FileNotFoundError):
            # Fall back to PAT
            if self.config.get('pat'):
                print("[OK] Using Personal Access Token for Claude analysis")
                os.environ['AZURE_DEVOPS_PAT'] = self.config['pat']
                auth_available = True
            else:
                error_msg = "No valid authentication method available. Configure Azure CLI or PAT."
                return False, error_msg
        
        if not auth_available:
            error_msg = "Authentication verification failed."
            return False, error_msg
        
        # Step 3: Verify Claude Code MCP configuration
        if not self.claude_config_file.exists():
            print("[WARNING]  Claude Code MCP configuration not found. This may cause issues.")
            print(f"Consider running: python {Path(__file__).name} --setup-claude")
        
        # Create analysis request
        analysis_request = f"""
Please analyze the following TFS work items from the last {days} days and provide:

1. Enhanced Priority Analysis - Review each work item and provide intelligent priority rankings
2. Action Recommendations - Suggest specific next steps for each item  
3. Risk Assessment - Identify potential risks or blockers
4. Summary Insights - Overall patterns and key focus areas

Work Items Data:
{json.dumps(work_items, indent=2)}

Please format the response as structured analysis with clear sections for each work item, including priority level (HIGH/MEDIUM/LOW), recommended actions, and risk factors.
"""
        
        # Create temporary files
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as temp_request:
            temp_request.write(analysis_request)
            temp_request_path = temp_request.name
        
        try:
            # Invoke Claude Code using stdin with timeout
            result = subprocess.run(
                ['claude-code', '--print', '--output-format', 'json'], 
                input=analysis_request,
                capture_output=True, 
                text=True,
                timeout=120
            )
            
            if result.returncode == 0 and result.stdout.strip():
                print(" Done", file=sys.stderr)
                print(f"[OK] Claude AI analysis completed for all {total_count} tickets!")
                
                # Generate enhanced output
                self._generate_enhanced_output(work_items, result.stdout, days, output_type)
                return True, ""
            else:
                print(" Failed", file=sys.stderr)
                error_msg = "Claude returned empty response"
                if result.stderr:
                    error_detail = ' '.join(result.stderr.split('\n')[:3]).strip()
                    if error_detail:
                        error_msg = f"{error_msg}: {error_detail}"
                return False, error_msg
                
        except subprocess.TimeoutExpired:
            print(" Failed", file=sys.stderr)
            error_msg = "Command timed out after 120 seconds"
            return False, error_msg
        except Exception as e:
            print(" Failed", file=sys.stderr)
            error_msg = f"Claude Code execution failed: {str(e)}"
            return False, error_msg
        finally:
            # Cleanup
            try:
                os.unlink(temp_request_path)
            except:
                pass
    
    def _generate_enhanced_output(self, work_items: List[Dict[str, Any]], claude_response: str, days: int, output_type: str):
        """Generate enhanced output with Claude AI insights"""
        print("Enhanced with Claude AI analysis Generating enhanced analysis with Claude AI insights")
        
        if output_type in ['browser', 'html']:
            self._generate_enhanced_html_output(work_items, claude_response, days, output_type == 'browser')
        elif output_type == 'text':
            self._generate_enhanced_text_output(work_items, claude_response, days)
        elif output_type == 'console':
            self._generate_enhanced_console_output(work_items, claude_response, days)
        elif output_type == 'email':
            self._send_enhanced_email_output(work_items, claude_response, days)
        else:
            self._generate_enhanced_console_output(work_items, claude_response, days)
    
    def _generate_enhanced_console_output(self, work_items: List[Dict[str, Any]], claude_response: str, days: int):
        """Generate enhanced console output with Claude insights"""
        print(f"\nClaude AI Integration Setup TFS Ticket Analysis with Claude AI - Last {days} days")
        print("=" * 70)
        print(f"Schedule Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Default Output Method Total items: {len(work_items)}")
        print(f"Enhanced with Claude AI analysis Enhanced with Claude AI analysis")
        print()
        
        # Display Claude's insights first
        print("Claude AI Features Claude AI Insights:")
        print("-" * 30)
        # Show first 20 lines of Claude's response
        claude_lines = claude_response.split('\n')[:20]
        for line in claude_lines:
            if line.strip():
                print(f"   {line}")
        if len(claude_response.split('\n')) > 20:
            print("   ... (see detailed analysis in full report)")
        print()
        
        # Then show enhanced analysis with Claude priority integration
        self._generate_enhanced_console_detailed_output(work_items, claude_response, days)
    
    def _generate_enhanced_console_detailed_output(self, work_items: List[Dict[str, Any]], claude_response: str, days: int):
        """Generate enhanced console output with Claude priority integration"""
        print("Enhanced Work Items Analysis:")
        print("=" * 40)
        
        priority_colors = {
            'HIGH': '\033[91m',     # Red
            'MEDIUM': '\033[93m',   # Yellow  
            'LOW': '\033[92m',      # Green
        }
        reset_color = '\033[0m'
        
        for item in work_items:
            work_item_id = str(item.get('id', ''))
            fields = item.get('fields', {})
            
            # Get traditional priority as fallback
            traditional_score, traditional_priority = self.calculate_priority_score(item)
            
            # Try to extract Claude's priority assessment for this work item ID
            claude_priority = None
            priority_source = "Traditional Analysis"
            
            if claude_response:
                # Look for this work item ID in Claude's response
                lines = claude_response.split('\n')
                for i, line in enumerate(lines):
                    if work_item_id in line or f"#{work_item_id}" in line or f"ID: {work_item_id}" in line:
                        # Check surrounding lines for priority keywords
                        context_start = max(0, i - 5)
                        context_end = min(len(lines), i + 10)
                        context_section = '\n'.join(lines[context_start:context_end])
                        
                        if 'HIGH' in context_section.upper():
                            claude_priority = 'HIGH'
                            priority_source = "Claude AI Assessment"
                            break
                        elif 'MEDIUM' in context_section.upper():
                            claude_priority = 'MEDIUM'
                            priority_source = "Claude AI Assessment"
                            break
                        elif 'LOW' in context_section.upper():
                            claude_priority = 'LOW'
                            priority_source = "Claude AI Assessment"
                            break
            
            # Use Claude's priority if available, otherwise use traditional
            final_priority = claude_priority if claude_priority else traditional_priority
            
            color = priority_colors.get(final_priority, '')
            
            print(f"{color}[{final_priority}]{reset_color} {fields.get('System.Title', 'No Title')}")
            print(f"   Type: {fields.get('System.WorkItemType', 'Unknown')}")
            print(f"   State: {fields.get('System.State', 'Unknown')}")
            print(f"   ID: {work_item_id}")
            print(f"   Priority Source: {priority_source}")
            if claude_priority:
                print(f"   Traditional Score: {traditional_score} ({traditional_priority})")
            print(f"   Score: {traditional_score}")
            
            analysis = self.analyze_content(item)
            print(f"   Action: {analysis['action_items']}")
            print()
    
    def _generate_enhanced_html_output(self, work_items: List[Dict[str, Any]], claude_response: str, days: int, open_browser: bool = False):
        """Generate enhanced HTML output with Claude priority integration"""
        output_file = f"/tmp/tfs_enhanced_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.html"
        
        # Count priorities for summary (using Claude priorities when available)
        high_count = medium_count = low_count = 0
        enhanced_items = []
        
        for item in work_items:
            work_item_id = str(item.get('id', ''))
            traditional_score, traditional_priority = self.calculate_priority_score(item)
            
            # Try to extract Claude's priority assessment
            claude_priority = None
            priority_source = "Traditional Analysis"
            
            if claude_response:
                lines = claude_response.split('\n')
                for i, line in enumerate(lines):
                    if work_item_id in line or f"#{work_item_id}" in line or f"ID: {work_item_id}" in line:
                        context_start = max(0, i - 5)
                        context_end = min(len(lines), i + 10)
                        context_section = '\n'.join(lines[context_start:context_end])
                        
                        if 'HIGH' in context_section.upper():
                            claude_priority = 'HIGH'
                            priority_source = "Claude AI Assessment"
                            break
                        elif 'MEDIUM' in context_section.upper():
                            claude_priority = 'MEDIUM'
                            priority_source = "Claude AI Assessment"
                            break
                        elif 'LOW' in context_section.upper():
                            claude_priority = 'LOW'
                            priority_source = "Claude AI Assessment"
                            break
            
            final_priority = claude_priority if claude_priority else traditional_priority
            
            # Count for summary
            if final_priority == 'HIGH':
                high_count += 1
            elif final_priority == 'MEDIUM':
                medium_count += 1
            else:
                low_count += 1
                
            enhanced_items.append({
                'item': item,
                'final_priority': final_priority,
                'priority_source': priority_source,
                'traditional_score': traditional_score
            })
        
        html_template = f'''<!DOCTYPE html>
<html>
<head>
    <title>Enhanced TFS Ticket Analysis with Claude AI</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }}
        .container {{ max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }}
        .header {{ text-align: center; color: #333; border-bottom: 2px solid #0078d4; padding-bottom: 10px; }}
        .summary {{ display: flex; justify-content: space-around; margin: 20px 0; }}
        .summary-card {{ padding: 15px; border-radius: 5px; text-align: center; color: white; }}
        .summary-high {{ background: #dc3545; }}
        .summary-medium {{ background: #ffc107; color: #212529; }}
        .summary-low {{ background: #28a745; }}
        .work-item {{ margin: 15px 0; padding: 15px; border-radius: 5px; border-left: 5px solid #ccc; background: #fafafa; }}
        .high {{ border-left-color: #dc3545; }}
        .medium {{ border-left-color: #ffc107; }}
        .low {{ border-left-color: #28a745; }}
        .priority {{ font-weight: bold; padding: 4px 8px; border-radius: 4px; color: white; display: inline-block; }}
        .priority.high {{ background: #dc3545; }}
        .priority.medium {{ background: #ffc107; color: #212529; }}
        .priority.low {{ background: #28a745; }}
        .title {{ font-size: 18px; font-weight: bold; margin: 10px 0; }}
        .details {{ color: #666; font-size: 14px; }}
        .claude-insights {{ background: #e7f3ff; padding: 10px; border-radius: 5px; margin: 10px 0; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Enhanced TFS Ticket Analysis with Claude AI</h1>
            <p>Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | Enhanced with Claude AI Priority Assessment</p>
        </div>
        
        <div class="summary">
            <div class="summary-card summary-high">High Priority: {high_count}</div>
            <div class="summary-card summary-medium">Medium Priority: {medium_count}</div>
            <div class="summary-card summary-low">Low Priority: {low_count}</div>
        </div>
        
        <div class="claude-insights">
            <h3>Claude AI Insights</h3>
            <pre>{"".join(claude_response.split("\\n")[:10])}</pre>
        </div>
        
        <h2>Work Items with Enhanced Priority Analysis</h2>'''
        
        for enhanced_item in enhanced_items:
            item = enhanced_item['item']
            fields = item.get('fields', {})
            final_priority = enhanced_item['final_priority']
            priority_source = enhanced_item['priority_source']
            traditional_score = enhanced_item['traditional_score']
            priority_class = final_priority.lower()
            
            html_template += f'''
    <div class="work-item {priority_class}">
        <span class="priority {priority_class}">{final_priority}</span>
        <div class="title">{fields.get('System.Title', 'No Title')}</div>
        <div class="details">
            <strong>Type:</strong> {fields.get('System.WorkItemType', 'Unknown')} | 
            <strong>State:</strong> {fields.get('System.State', 'Unknown')} | 
            <strong>ID:</strong> {item.get('id', 'Unknown')} | 
            <strong>Score:</strong> {traditional_score}<br>
            <strong>Priority Source:</strong> {priority_source}<br>
            <strong>Assigned To:</strong> {fields.get('System.AssignedTo', 'Unassigned')}<br>
            <strong>URL:</strong> <a href="{self.config.get('tfs_url', '')}/_workitems/edit/{item.get('id', '')}" target="_blank">View in TFS</a>
        </div>
    </div>'''
        
        html_template += '''
    </div>
</body>
</html>'''
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(html_template)
        
        print(f"Enhanced HTML report generated: {output_file}")
        
        if open_browser:
            import webbrowser
            webbrowser.open(f'file://{output_file}')
            print("Enhanced report opened in browser")
    
    def _generate_enhanced_text_output(self, work_items: List[Dict[str, Any]], claude_response: str, days: int):
        """Generate enhanced text output with Claude priority integration"""
        output_file = f"/tmp/tfs_enhanced_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("Enhanced TFS Ticket Analysis with Claude AI\n")
            f.write("=" * 50 + "\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("Enhanced with Claude AI Priority Assessment\n\n")
            
            f.write("Claude AI Insights:\n")
            f.write("-" * 20 + "\n")
            claude_lines = claude_response.split('\n')[:10]
            for line in claude_lines:
                if line.strip():
                    f.write(f"   {line}\n")
            f.write("\n")
            
            f.write("Work Items with Enhanced Priority Analysis:\n")
            f.write("=" * 45 + "\n\n")
            
            # Count priorities for summary
            high_count = medium_count = low_count = 0
            
            for item in work_items:
                work_item_id = str(item.get('id', ''))
                fields = item.get('fields', {})
                traditional_score, traditional_priority = self.calculate_priority_score(item)
                
                # Try to extract Claude's priority assessment
                claude_priority = None
                priority_source = "Traditional Analysis"
                
                if claude_response:
                    lines = claude_response.split('\n')
                    for i, line in enumerate(lines):
                        if work_item_id in line or f"#{work_item_id}" in line or f"ID: {work_item_id}" in line:
                            context_start = max(0, i - 5)
                            context_end = min(len(lines), i + 10)
                            context_section = '\n'.join(lines[context_start:context_end])
                            
                            if 'HIGH' in context_section.upper():
                                claude_priority = 'HIGH'
                                priority_source = "Claude AI Assessment"
                                break
                            elif 'MEDIUM' in context_section.upper():
                                claude_priority = 'MEDIUM'
                                priority_source = "Claude AI Assessment"
                                break
                            elif 'LOW' in context_section.upper():
                                claude_priority = 'LOW'
                                priority_source = "Claude AI Assessment"
                                break
                
                final_priority = claude_priority if claude_priority else traditional_priority
                
                # Count for summary
                if final_priority == 'HIGH':
                    high_count += 1
                elif final_priority == 'MEDIUM':
                    medium_count += 1
                else:
                    low_count += 1
                
                f.write(f"[{final_priority}] {fields.get('System.Title', 'No Title')}\n")
                f.write(f"   Type: {fields.get('System.WorkItemType', 'Unknown')}\n")
                f.write(f"   State: {fields.get('System.State', 'Unknown')}\n")
                f.write(f"   ID: {work_item_id}\n")
                f.write(f"   Priority Source: {priority_source}\n")
                if claude_priority:
                    f.write(f"   Traditional Score: {traditional_score} ({traditional_priority})\n")
                f.write(f"   Score: {traditional_score}\n")
                
                analysis = self.analyze_content(item)
                f.write(f"   Action: {analysis['action_items']}\n")
                f.write(f"   URL: {self.config.get('tfs_url', '')}/_workitems/edit/{work_item_id}\n")
                f.write("\n")
            
            f.write("\nSUMMARY:\n")
            f.write("-" * 10 + "\n")
            f.write(f"Total Tickets: {len(work_items)}\n")
            f.write(f"High Priority: {high_count}\n")
            f.write(f"Medium Priority: {medium_count}\n")
            f.write(f"Low Priority: {low_count}\n")
        
        print(f"Enhanced text report generated: {output_file}")
    
    def generate_output(self, work_items: List[Dict[str, Any]], output_type: str, days: int, use_claude: bool = False):
        """Generate output in specified format"""
        if not work_items:
            print("No work items found for the specified criteria.")
            return
        
        # Try Claude AI analysis first if requested
        claude_error_reason = None
        if use_claude:
            success, error_msg = self.invoke_claude_analysis(work_items, days, output_type)
            if success:
                print("[OK] Analysis completed with Claude AI enhancement")
                return
            else:
                print("[INFO]  Falling back to traditional analysis")
                claude_error_reason = error_msg
        
        # Analyze and sort work items (traditional method)
        analyzed_items = []
        for item in work_items:
            score, priority = self.calculate_priority_score(item)
            analysis = self.analyze_content(item)
            
            analyzed_items.append({
                'work_item': item,
                'priority_score': score,
                'priority_level': priority,
                'analysis': analysis
            })
        
        # Sort by priority score (highest first)
        analyzed_items.sort(key=lambda x: x['priority_score'], reverse=True)
        
        if output_type in ['browser', 'html']:
            self._generate_html_output(analyzed_items, days, output_type == 'browser', claude_error_reason)
        elif output_type == 'text':
            self._generate_text_output(analyzed_items, days, claude_error_reason)
        elif output_type == 'console':
            self._generate_console_output(analyzed_items, days, claude_error_reason)
        elif output_type == 'email':
            self._send_email_output(analyzed_items, days, claude_error_reason)
    
    def _generate_html_output(self, analyzed_items: List[Dict], days: int, open_browser: bool = False, claude_error_reason: str = None):
        """Generate HTML output"""
        html_content = self._build_html_report(analyzed_items, days, claude_error_reason)
        
        # Get appropriate output directory
        if sys.platform == 'win32':
            output_dir = Path.home() / 'Documents'
        else:
            output_dir = Path.home() / 'Downloads'
            if not output_dir.exists():
                output_dir = Path.home() / 'Documents'
                if not output_dir.exists():
                    output_dir = Path.home()
        
        output_file = output_dir / 'TFS-Daily-Summary.html'
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        print(f"[SAVED] HTML report saved to: {output_file}")
        
        if open_browser:
            webbrowser.open(f'file://{output_file.absolute()}')
            print("[BROWSER] Report opened in browser")
    
    def _generate_text_output(self, analyzed_items: List[Dict], days: int, claude_error_reason: str = None):
        """Generate text output"""
        lines = []
        lines.append(f"TFS Ticket Analysis - Last {days} days")
        lines.append("=" * 50)
        lines.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        lines.append(f"Total items: {len(analyzed_items)}")
        
        # Add Claude failure reason if present
        if claude_error_reason:
            lines.append("")
            lines.append("Claude Analysis Failure Reason:")
            lines.append(f"  - {claude_error_reason}")
        
        lines.append("")
        
        for item_data in analyzed_items:
            work_item = item_data['work_item']
            fields = work_item.get('fields', {})
            
            lines.append(f"[{item_data['priority_level']}] {fields.get('System.Title', 'No Title')}")
            lines.append(f"   Type: {fields.get('System.WorkItemType', 'Unknown')}")
            lines.append(f"   State: {fields.get('System.State', 'Unknown')}")
            lines.append(f"   ID: {work_item.get('id', 'Unknown')}")
            lines.append(f"   Score: {item_data['priority_score']}")
            lines.append(f"   Action: {item_data['analysis']['action_items']}")
            lines.append("")
        
        content = '\n'.join(lines)
        
        # Get appropriate output directory  
        if sys.platform == 'win32':
            output_dir = Path.home() / 'Documents'
        else:
            output_dir = Path.home() / 'Downloads'
            if not output_dir.exists():
                output_dir = Path.home() / 'Documents'
                if not output_dir.exists():
                    output_dir = Path.home()
        
        output_file = output_dir / 'TFS-Daily-Summary.txt'
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"[SAVED] Text report saved to: {output_file}")
    
    def _generate_console_output(self, analyzed_items: List[Dict], days: int, claude_error_reason: str = None):
        """Generate console output with colors"""
        print(f"\nTFS Ticket Analysis TFS Ticket Analysis - Last {days} days")
        print("=" * 60)
        print(f"Schedule Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Default Output Method Total items: {len(analyzed_items)}")
        print()
        
        priority_colors = {
            'HIGH': '\033[91m',     # Red
            'MEDIUM': '\033[93m',   # Yellow  
            'LOW': '\033[92m'       # Green
        }
        reset_color = '\033[0m'
        
        for item_data in analyzed_items:
            work_item = item_data['work_item']
            fields = work_item.get('fields', {})
            priority = item_data['priority_level']
            
            color = priority_colors.get(priority, '')
            
            print(f"{color}[{priority}]{reset_color} {fields.get('System.Title', 'No Title')}")
            print(f"   Type: {fields.get('System.WorkItemType', 'Unknown')}")
            print(f"   State: {fields.get('System.State', 'Unknown')}")
            print(f"   ID: {work_item.get('id', 'Unknown')}")
            print(f"   Score: {item_data['priority_score']}")
            print(f"   Action: {item_data['analysis']['action_items']}")
            print()
        
        # Display Claude failure reason if present
        if claude_error_reason:
            print("\033[93mClaude Analysis Failure Reason:\033[0m")  # Yellow text
            print(f"  - {claude_error_reason}")
            print()
    
    def _build_html_report(self, analyzed_items: List[Dict], days: int, claude_error_reason: str = None) -> str:
        """Build HTML report content"""
        html_template = f"""
<!DOCTYPE html>
<html>
<head>
    <title>TFS Ticket Analysis - Last {days} days</title>
    <meta charset="utf-8">
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; margin: 20px; }}
        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; }}
        .summary {{ background: #f8f9fa; padding: 15px; border-radius: 6px; margin: 20px 0; }}
        .work-item {{ margin: 15px 0; padding: 15px; border-left: 4px solid #ddd; background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
        .high {{ border-left-color: #dc3545; }}
        .medium {{ border-left-color: #ffc107; }}
        .low {{ border-left-color: #28a745; }}
        .priority {{ font-weight: bold; padding: 4px 8px; border-radius: 4px; color: white; display: inline-block; }}
        .priority.high {{ background: #dc3545; }}
        .priority.medium {{ background: #ffc107; color: #212529; }}
        .priority.low {{ background: #28a745; }}
        .title {{ font-size: 18px; font-weight: bold; margin: 10px 0; }}
        .details {{ color: #666; font-size: 14px; }}
        .analysis {{ background: #f8f9fa; padding: 10px; border-radius: 4px; margin: 10px 0; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>TFS Ticket Analysis TFS Ticket Analysis</h1>
        <p>Last {days} days - Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
    </div>
    
    <div class="summary">
        <h2>Default Output Method Summary</h2>
        <p><strong>Total Items:</strong> {len(analyzed_items)}</p>
        <p><strong>High Priority:</strong> {len([i for i in analyzed_items if i['priority_level'] == 'HIGH'])}</p>
        <p><strong>Medium Priority:</strong> {len([i for i in analyzed_items if i['priority_level'] == 'MEDIUM'])}</p>
        <p><strong>Low Priority:</strong> {len([i for i in analyzed_items if i['priority_level'] == 'LOW'])}</p>"""
        
        if claude_error_reason:
            html_template += f"""
        <div style='background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 4px; padding: 10px; margin: 10px 0;'>
            <strong>[WARNING] Claude Analysis Failure:</strong> {claude_error_reason}
        </div>"""
        
        html_template += """
    </div>
"""
        
        for item_data in analyzed_items:
            work_item = item_data['work_item']
            fields = work_item.get('fields', {})
            priority = item_data['priority_level'].lower()
            
            html_template += f"""
    <div class="work-item {priority}">
        <span class="priority {priority}">{item_data['priority_level']}</span>
        <div class="title">{fields.get('System.Title', 'No Title')}</div>
        <div class="details">
            <strong>Type:</strong> {fields.get('System.WorkItemType', 'Unknown')} | 
            <strong>State:</strong> {fields.get('System.State', 'Unknown')} | 
            <strong>ID:</strong> {work_item.get('id', 'Unknown')} | 
            <strong>Score:</strong> {item_data['priority_score']}
        </div>
        <div class="analysis">
            <strong>Action:</strong> {item_data['analysis']['action_items']}<br>
            <strong>Impact:</strong> {item_data['analysis']['impact_assessment']}
        </div>
    </div>
"""
        
        html_template += """
</body>
</html>
"""
        return html_template
    
    def _send_email_output(self, analyzed_items: List[Dict], days: int, claude_error_reason: str = None):
        """Send email with HTML report"""
        if not all(k in self.config for k in ['email_address', 'email_password', 'smtp_server', 'smtp_port']):
            print("[ERROR] Email configuration missing. Run setup first.")
            return
        
        html_content = self._build_html_report(analyzed_items, days, claude_error_reason)
        
        msg = MimeMultipart('alternative')
        msg['Subject'] = f"TFS Ticket Analysis - Last {days} days"
        msg['From'] = self.config['email_address']
        msg['To'] = self.config['email_address']
        
        html_part = MimeText(html_content, 'html')
        msg.attach(html_part)
        
        try:
            with smtplib.SMTP(self.config['smtp_server'], int(self.config['smtp_port'])) as server:
                server.starttls()
                server.login(self.config['email_address'], self.config['email_password'])
                server.send_message(msg)
            
            print(f"Email Configuration Email sent successfully to {self.config['email_address']}")
            
        except Exception as e:
            print(f"[ERROR] Failed to send email: {e}")

def setup_cron_job(output_method: str = 'console', time_str: str = '08:00'):
    """Setup cron job for daily analysis (Linux/Mac)"""
    if sys.platform == 'win32':
        print("[ERROR] Cron jobs not supported on Windows. Use Task Scheduler instead.")
        return
    
    script_path = Path(__file__).absolute()
    cron_command = f'{time_str.split(":")[1]} {time_str.split(":")[0]} * * * /usr/bin/python3 "{script_path}" 1 --output {output_method}'
    
    print(f"Add this line to your crontab (crontab -e):")
    print(f"{cron_command}")
    print(f"\nThis will run daily at {time_str}")

def main():
    parser = argparse.ArgumentParser(description='Cross-platform TFS Ticket Analyzer with Claude AI support')
    parser.add_argument('days', nargs='?', default=1, type=int, help='Number of days to analyze')
    
    # Setup commands
    parser.add_argument('--setup', action='store_true', help='Run configuration setup')
    parser.add_argument('--setup-claude', action='store_true', help='Setup Claude AI integration')
    parser.add_argument('--test-claude', action='store_true', help='Test Claude AI configuration')
    parser.add_argument('--setup-output', action='store_true', help='Configure default output method')
    parser.add_argument('--test-auth', action='store_true', help='Test TFS authentication')
    
    # Simplified parameters
    parser.add_argument('-b', '--browser', action='store_true', help='Open results in browser')
    parser.add_argument('-h', '--html', action='store_true', help='Save as HTML file')
    parser.add_argument('-t', '--text', action='store_true', help='Save as text file')
    parser.add_argument('-e', '--email', action='store_true', help='Send via email')
    parser.add_argument('-c', '--claude', action='store_true', help='Use Claude AI for enhanced analysis')
    parser.add_argument('--no-ai', action='store_true', help='Disable Claude AI (traditional analysis only)')
    parser.add_argument('-d', '--details', action='store_true', help='Show detailed processing information')
    
    # Traditional parameters for backward compatibility
    parser.add_argument('--output', choices=['browser', 'html', 'text', 'console', 'email'], help='Output method')
    parser.add_argument('--windows-auth', action='store_true', help='Use Windows authentication')
    parser.add_argument('--setup-cron', action='store_true', help='Setup daily cron job (Linux/Mac)')
    parser.add_argument('--cron-time', default='08:00', help='Cron job time (HH:MM format)')
    parser.add_argument('--verbose', action='store_true', help='Verbose output (same as --details)')
    parser.add_argument('--version', action='version', version='TFS Analyzer 2.1.0')
    
    args = parser.parse_args()
    
    if len(sys.argv) == 1:
        parser.print_help()
        return
    
    analyzer = TFSAnalyzer()
    
    if args.setup:
        analyzer.setup_config(args.windows_auth)
        return
    
    if args.setup_claude:
        analyzer.setup_claude_config()
        return
    
    if hasattr(args, 'test_claude') and args.test_claude:
        analyzer.test_claude_configuration()
        return
    
    if args.setup_output:
        analyzer.setup_config(args.windows_auth)  # This includes output setup
        return
        
    if args.test_auth:
        analyzer.test_auth()
        return
        
    if args.setup_cron:
        setup_cron_job(args.output or 'console', args.cron_time)
        return
    
    # Determine output method from simplified parameters first
    output_method = None
    if args.browser:
        output_method = 'browser'
    elif args.html:
        output_method = 'html'
    elif args.text:
        output_method = 'text'
    elif args.email:
        output_method = 'email'
    elif args.output:
        output_method = args.output
    else:
        output_method = analyzer.config.get('default_output', 'console')
    
    # Determine Claude AI usage
    use_claude = args.claude
    if args.claude:
        # Verify Claude setup when explicitly requested
        print("Testing Verifying Claude AI configuration...")
        if analyzer.test_claude_configuration():
            print("[OK] Claude AI verification passed - using AI analysis")
            use_claude = True
        else:
            print("[ERROR] Claude AI verification failed - falling back to traditional analysis")
            print()
            print("Troubleshooting Tips  Quick Fixes:")
            print("- Run: python tfs-analyzer.py --setup-claude")
            print("- Check: az login --allow-no-subscriptions")
            print("- Verify: Claude Code installation")
            print()
            use_claude = False
    elif args.no_ai:
        use_claude = False
    else:
        # Check if Claude AI is configured by default
        default_claude = analyzer.config.get('use_claude_ai', 'false').lower() == 'true'
        if default_claude:
            # Quick verification for default usage (less verbose)
            try:
                subprocess.run(['claude-code', '--version'], 
                             capture_output=True, check=True)
                # Test authentication
                auth_ok = False
                try:
                    subprocess.run(['az', 'account', 'show'], 
                                 capture_output=True, check=True)
                    auth_ok = True
                except (subprocess.CalledProcessError, FileNotFoundError):
                    if analyzer.config.get('pat'):
                        auth_ok = True
                
                if auth_ok:
                    use_claude = True
                else:
                    use_claude = False
                    print("[WARNING]  Claude AI configured by default but verification failed - using traditional analysis")
            except (subprocess.CalledProcessError, FileNotFoundError):
                use_claude = False
                print("[WARNING]  Claude AI configured by default but Claude Code not found - using traditional analysis")
        else:
            use_claude = False
    
    # Verbose output
    verbose = args.verbose or args.details
    if verbose:
        print(f"Testing Analyzing last {args.days} days...")
        print(f"Default Output Method Output method: {output_method}")
        print(f"Claude AI Integration Setup Claude AI: {'enabled' if use_claude else 'disabled'}")
    
    # Get and analyze work items
    work_items = analyzer.get_work_items(args.days)
    analyzer.generate_output(work_items, output_method, args.days, use_claude)

if __name__ == '__main__':
    main()