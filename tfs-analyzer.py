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
        """Get platform-appropriate config directory"""
        if sys.platform == 'win32':
            return Path.home()
        elif sys.platform == 'darwin':  # macOS
            return Path.home() / '.config'
        else:  # Linux and other Unix-like systems
            return Path.home() / '.config'
    
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
        
    def setup_config(self, use_windows_auth: bool = False):
        """Interactive configuration setup"""
        print("🔧 TFS Ticket Analyzer Setup")
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
        print("\n📊 Default Output Method:")
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
        
        print(f"\n✅ Configuration saved to: {self.config_manager.config_file}")
        print("🚀 Ready to analyze TFS tickets!")
    
    def _setup_email_config(self, config_data: Dict[str, str]):
        """Setup email configuration"""
        print("\n📧 Email Configuration:")
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
    
    def test_auth(self) -> bool:
        """Test TFS authentication"""
        if not self.config:
            print("❌ No configuration found. Run setup first.")
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
                print("✅ Authentication successful!")
                return True
            else:
                print(f"❌ Authentication failed: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ Connection failed: {e}")
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
            print(f"❌ Error retrieving work items: {e}")
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
                line.startswith('•') or any(line.startswith(f"{i}.") for i in range(1, 10))):
                key_lines.append(line)
        
        return '\n'.join(key_lines[:5]) if key_lines else description[:200] + "..."
    
    def _get_action_recommendation(self, work_type: str, state: str) -> str:
        """Get action recommendation based on work item type and state"""
        recommendations = {
            ('Bug', 'New'): "🔍 Investigate and reproduce the issue",
            ('Bug', 'Active'): "⚡ Continue debugging and provide status updates",
            ('Bug', 'In Progress'): "🚧 Focus on completing the fix",
            ('Task', 'To Do'): "📅 Schedule work and move to Active",
            ('Task', 'Active'): "⚡ Continue work and provide status updates", 
            ('Task', 'In Progress'): "🚧 Focus on completing current tasks"
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
    
    def generate_output(self, work_items: List[Dict[str, Any]], output_type: str, days: int):
        """Generate output in specified format"""
        if not work_items:
            print("No work items found for the specified criteria.")
            return
        
        # Analyze and sort work items
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
            self._generate_html_output(analyzed_items, days, output_type == 'browser')
        elif output_type == 'text':
            self._generate_text_output(analyzed_items, days)
        elif output_type == 'console':
            self._generate_console_output(analyzed_items, days)
        elif output_type == 'email':
            self._send_email_output(analyzed_items, days)
    
    def _generate_html_output(self, analyzed_items: List[Dict], days: int, open_browser: bool = False):
        """Generate HTML output"""
        html_content = self._build_html_report(analyzed_items, days)
        
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
        
        print(f"📄 HTML report saved to: {output_file}")
        
        if open_browser:
            webbrowser.open(f'file://{output_file.absolute()}')
            print("🌐 Report opened in browser")
    
    def _generate_text_output(self, analyzed_items: List[Dict], days: int):
        """Generate text output"""
        lines = []
        lines.append(f"TFS Ticket Analysis - Last {days} days")
        lines.append("=" * 50)
        lines.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        lines.append(f"Total items: {len(analyzed_items)}")
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
        
        print(f"📄 Text report saved to: {output_file}")
    
    def _generate_console_output(self, analyzed_items: List[Dict], days: int):
        """Generate console output with colors"""
        print(f"\n🎯 TFS Ticket Analysis - Last {days} days")
        print("=" * 60)
        print(f"📅 Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"📊 Total items: {len(analyzed_items)}")
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
            print(f"   📝 Type: {fields.get('System.WorkItemType', 'Unknown')}")
            print(f"   📊 State: {fields.get('System.State', 'Unknown')}")
            print(f"   🔢 ID: {work_item.get('id', 'Unknown')}")
            print(f"   ⭐ Score: {item_data['priority_score']}")
            print(f"   💡 Action: {item_data['analysis']['action_items']}")
            print()
    
    def _build_html_report(self, analyzed_items: List[Dict], days: int) -> str:
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
        <h1>🎯 TFS Ticket Analysis</h1>
        <p>Last {days} days • Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
    </div>
    
    <div class="summary">
        <h2>📊 Summary</h2>
        <p><strong>Total Items:</strong> {len(analyzed_items)}</p>
        <p><strong>High Priority:</strong> {len([i for i in analyzed_items if i['priority_level'] == 'HIGH'])}</p>
        <p><strong>Medium Priority:</strong> {len([i for i in analyzed_items if i['priority_level'] == 'MEDIUM'])}</p>
        <p><strong>Low Priority:</strong> {len([i for i in analyzed_items if i['priority_level'] == 'LOW'])}</p>
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
            <strong>💡 Action:</strong> {item_data['analysis']['action_items']}<br>
            <strong>📈 Impact:</strong> {item_data['analysis']['impact_assessment']}
        </div>
    </div>
"""
        
        html_template += """
</body>
</html>
"""
        return html_template
    
    def _send_email_output(self, analyzed_items: List[Dict], days: int):
        """Send email with HTML report"""
        if not all(k in self.config for k in ['email_address', 'email_password', 'smtp_server', 'smtp_port']):
            print("❌ Email configuration missing. Run setup first.")
            return
        
        html_content = self._build_html_report(analyzed_items, days)
        
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
            
            print(f"📧 Email sent successfully to {self.config['email_address']}")
            
        except Exception as e:
            print(f"❌ Failed to send email: {e}")

def setup_cron_job(output_method: str = 'console', time_str: str = '08:00'):
    """Setup cron job for daily analysis (Linux/Mac)"""
    if sys.platform == 'win32':
        print("❌ Cron jobs not supported on Windows. Use Task Scheduler instead.")
        return
    
    script_path = Path(__file__).absolute()
    cron_command = f'{time_str.split(":")[1]} {time_str.split(":")[0]} * * * /usr/bin/python3 "{script_path}" 1 --output {output_method}'
    
    print(f"Add this line to your crontab (crontab -e):")
    print(f"{cron_command}")
    print(f"\nThis will run daily at {time_str}")

def main():
    parser = argparse.ArgumentParser(description='Cross-platform TFS Ticket Analyzer')
    parser.add_argument('days', nargs='?', default=1, type=int, help='Number of days to analyze')
    parser.add_argument('--setup', action='store_true', help='Run configuration setup')
    parser.add_argument('--setup-output', action='store_true', help='Configure default output method')
    parser.add_argument('--test-auth', action='store_true', help='Test TFS authentication')
    parser.add_argument('--output', choices=['browser', 'html', 'text', 'console', 'email'], help='Output method')
    parser.add_argument('--windows-auth', action='store_true', help='Use Windows authentication')
    parser.add_argument('--setup-cron', action='store_true', help='Setup daily cron job (Linux/Mac)')
    parser.add_argument('--cron-time', default='08:00', help='Cron job time (HH:MM format)')
    parser.add_argument('--verbose', action='store_true', help='Verbose output')
    parser.add_argument('--version', action='version', version='TFS Analyzer 2.0.0')
    
    args = parser.parse_args()
    
    if len(sys.argv) == 1:
        parser.print_help()
        return
    
    analyzer = TFSAnalyzer()
    
    if args.setup:
        analyzer.setup_config(args.windows_auth)
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
    
    # Determine output method
    output_method = args.output
    if not output_method:
        output_method = analyzer.config.get('default_output', 'console')
    
    if args.verbose:
        print(f"🔍 Analyzing last {args.days} days...")
        print(f"📊 Output method: {output_method}")
    
    # Get and analyze work items
    work_items = analyzer.get_work_items(args.days)
    analyzer.generate_output(work_items, output_method, args.days)

if __name__ == '__main__':
    main()