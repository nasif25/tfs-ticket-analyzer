# TFS Ticket Analyzer with Claude AI Integration

A comprehensive **cross-platform** tool that analyzes your TFS/Azure DevOps tickets with **AI-powered insights**. Uses Claude AI for enhanced analysis including intelligent priority assessment, smart summarization, and actionable recommendations. Supports both traditional analysis and AI-enhanced modes with multiple authentication methods and output formats.

## 🎯 **Quick Command Reference**

**Windows PowerShell:**
```powershell
# Basic usage with simplified parameters
.\tfs-analyzer.ps1 1 -Browser        # Today's tickets in browser
.\tfs-analyzer.ps1 3 -Claude -Html   # 3 days AI analysis to HTML
.\tfs-analyzer.ps1 7 -Text          # Week summary to text file
.\tfs-analyzer.ps1 12 -Hours -Browser # Last 12 hours in browser
.\tfs-analyzer.ps1 6 -Hours -Claude -Html # Last 6 hours with AI to HTML
.\tfs-analyzer.ps1 1 -NoAI -Details # AI disabled with debug
```

**Linux/Mac Bash:**
```bash
# Basic usage with simplified parameters
./tfs-analyzer.sh 1 --browser                    # Today's tickets in browser
./tfs-analyzer.sh 3 --claude --html              # 3 days AI analysis to HTML
./tfs-analyzer.sh 7 --text                       # Week summary to text file
./tfs-analyzer.sh 12 --hours --browser           # Last 12 hours in browser
./tfs-analyzer.sh 6 --hours --claude --html      # Last 6 hours with AI to HTML
./tfs-analyzer.sh 1 --no-ai -d                   # AI disabled with debug
```

**Python (All Platforms):**
```bash
# Basic usage with simplified parameters
python tfs-analyzer.py 1 --browser               # Today's tickets in browser
python tfs-analyzer.py 3 --claude --html         # 3 days AI analysis to HTML
python tfs-analyzer.py 7 --text                  # Week summary to text file
python tfs-analyzer.py 12 --hours --browser      # Last 12 hours in browser
python tfs-analyzer.py 6 --hours --claude --html # Last 6 hours with AI to HTML
python tfs-analyzer.py 1 --no-ai -d              # AI disabled with debug
```

**Simplified Parameters:**

| Function | PowerShell | Bash | Python |
|----------|------------|------|--------|
| Force AI analysis | `-Claude` | `--claude` | `--claude` |
| AI disabled | `-NoAI` | `--no-ai` | `--no-ai` |
| Open in browser | `-Browser` | `--browser` | `--browser` |
| Save HTML file | `-Html` | `--html` | `--html` |
| Save text file | `-Text` | `--text` | `--text` |
| Send via email | `-Email` | `--email` | `--email` |
| Detailed output | `-Details` | `-d, --details` | `-d, --details` |
| Time to analyze | `[number]` | `[number]` | `[number]` |
| Use hours instead of days | `-Hours` | `--hours` | `--hours` |

## 🖥️ Platform Support

| Platform | Script | Status |
|----------|--------|--------|
| **Windows** | `tfs-analyzer.ps1` | ✅ Full featured |
| **Linux** | `tfs-analyzer.sh` or `tfs-analyzer.py` | ✅ Full featured |
| **macOS** | `tfs-analyzer.sh` or `tfs-analyzer.py` | ✅ Full featured |

## 📁 File Structure

### **Core Analyzers (Choose One)**
- **`tfs-analyzer.ps1`** - Windows PowerShell version (recommended for Windows)
- **`tfs-analyzer.py`** - Python version (works on all platforms)
- **`tfs-analyzer.sh`** - Bash version (Linux/Mac native)

### **Easy Setup Wizards (Recommended for Beginners)**
- **`easy-setup.ps1`** - Windows PowerShell guided setup wizard
- **`easy-setup.sh`** - Linux/macOS Bash guided setup wizard
- **`easy-setup.py`** - Python cross-platform guided setup wizard

### **Automation Schedulers**
- **`tfs-scheduler-daily.ps1`** - Windows daily automation (requires Administrator)
- **`tfs-scheduler-smart.ps1`** - Windows smart scheduling (requires Administrator)
- **`tfs-scheduler.sh`** - Linux/Mac automation setup

### **Dependencies**
- **`requirements.txt`** - Python package dependencies

## 🚀 Quick Start

### 1. Prerequisites

**For AI-Enhanced Analysis (Optional but Recommended):**
1. **Install Claude Code**: Download from [claude.ai/code](https://claude.ai/code)
2. **Azure CLI** (recommended): Install from [docs.microsoft.com/en-us/cli/azure/install-azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
3. **Authenticate with Azure CLI**: Run `az login --allow-no-subscriptions`

### 2. First-time Setup

**🎯 For Beginners - Easy Setup Wizard (Recommended):**

**Windows PowerShell:**
```powershell
# Interactive step-by-step setup wizard
.\easy-setup.ps1

# Note: If setting up automation, run PowerShell as Administrator
```

**Linux/macOS Bash:**
```bash
# Make executable (first time only)
chmod +x easy-setup.sh

# Run interactive setup wizard
./easy-setup.sh
```

**Python (All Platforms):**
```bash
# Install dependencies first
pip install -r requirements.txt

# Run interactive setup wizard
python easy-setup.py
```

**The wizard will guide you through:**
- ✓ TFS connection setup
- ✓ Authentication configuration (Azure CLI or PAT)
- ✓ User preferences and display name
- ✓ Output method selection
- ✓ AI analysis preference (enable/disable Claude AI)
- ✓ Optional daily automation
- ✓ Connection testing

**🔧 For Advanced Users - Manual Setup:**

**Windows:**
```powershell
# Basic setup with authentication configuration
.\tfs-analyzer.ps1 setup

# Setup Claude AI integration (optional)
.\tfs-analyzer.ps1 setup-claude
```

**Linux/Mac (Bash):**
```bash
# Basic setup with authentication configuration
./tfs-analyzer.sh setup

# Setup Claude AI integration (optional)
./tfs-analyzer.sh setup-claude
```

**Python (Any Platform):**
```bash
# Install dependencies first
pip install -r requirements.txt

# Basic setup
python tfs-analyzer.py --setup

# Setup Claude AI integration (optional)  
python tfs-analyzer.py --setup-claude
```

You'll be prompted for:
- **TFS/Azure DevOps URL**: `https://tfs.YOUR_ORGANIZATION.com/tfs/YOUR_ORGANIZATION`
- **Project Name**: `YOUR_PROJECT`
- **Authentication Method**: Azure CLI (recommended), PAT, or Windows Auth
- **Personal Access Token**: Your TFS PAT (if not using Azure CLI)
- **Display Name**: For @mention detection
- **Claude AI Setup**: Optional AI enhancement configuration

### 3. Daily Analysis

**Windows:**
```powershell
# AI-enhanced analysis (last 24 hours) - show in browser
.\tfs-analyzer.ps1 1 -Claude -Browser

# AI disabled (last 3 days) - save HTML file
.\tfs-analyzer.ps1 3 -NoAI -Html

# Use configured default (AI or without) - save text summary
.\tfs-analyzer.ps1 7 -Text

# Verbose mode with detailed output
.\tfs-analyzer.ps1 1 -Details -Claude
```

**Linux/Mac (Bash):**
```bash
# AI-enhanced analysis
./tfs-analyzer.sh 1 --claude --browser       # AI analysis, show in browser
./tfs-analyzer.sh 3 --no-ai --html           # AI disabled, HTML file
./tfs-analyzer.sh 7 --text                   # Default mode, text summary
./tfs-analyzer.sh 1 -d --claude              # AI analysis with detailed output
```

**Python (Any Platform):**
```bash
# AI-enhanced analysis
python tfs-analyzer.py 1 --claude --browser  # AI analysis, show in browser
python tfs-analyzer.py 3 --no-ai --html      # AI disabled, HTML file
python tfs-analyzer.py 7 --text              # Default mode, text summary
python tfs-analyzer.py 1 -d --claude         # AI analysis with detailed output
```

## 🔄 Automation Setup

> **⚠️ Important Limitation**: Each scheduler type maintains only ONE active configuration at a time. Running a scheduler script will **replace any existing schedule** with the new configuration. If you need multiple schedules with different preferences (e.g., different times, output methods, or AI modes), you'll need to manually create additional scheduled tasks/cron jobs with unique names.

### **Windows Automation**

> **⚠️ Administrator Required**: Windows scheduler scripts must be run as Administrator.
> Right-click PowerShell → "Run as Administrator"

**Daily Schedule (Fixed Time):**
```powershell
# Daily at 8:00 AM with browser output
.\tfs-scheduler-daily.ps1 -Time "08:00" -OutputMethod browser

# Daily at midnight with HTML output
.\tfs-scheduler-daily.ps1 -Time "00:30" -OutputMethod html

# Daily at 8:00 AM with AI disabled (traditional analysis only)
.\tfs-scheduler-daily.ps1 -Time "08:00" -OutputMethod browser -NoAI
```

**Smart Schedule (Recommended):**
```powershell
# Runs at startup OR daily (whichever comes first)
.\tfs-scheduler-smart.ps1 -OutputMethod browser

# With custom daily backup time
.\tfs-scheduler-smart.ps1 -OutputMethod browser -Time "09:00"

# With AI disabled (traditional analysis only)
.\tfs-scheduler-smart.ps1 -OutputMethod browser -NoAI

# Remove automation
.\tfs-scheduler-smart.ps1 -Remove
```

### **Linux/Mac Automation**

**Interactive Setup:**
```bash
# Choose automation type and output method
./tfs-scheduler.sh
```

**Manual Setup:**
```bash
# Interactive setup (recommended)
./tfs-scheduler.sh

# Or specify time and output
./tfs-scheduler.sh --time 08:00 --output browser
./tfs-scheduler.sh --time 09:30 --output html

# With AI disabled (traditional analysis only)
./tfs-scheduler.sh --time 08:00 --output browser --no-ai

# Remove automation
./tfs-scheduler.sh --remove
```

## 📊 Output Options

- **Browser**: Opens HTML report in default browser
- **HTML File**: Saves HTML report to Documents/Downloads folder
- **Text File**: Saves plain text summary
- **Console**: Displays formatted results in terminal
- **Email**: Sends HTML report via SMTP (Office 365/Gmail/Yahoo auto-configured)

## ✨ Features

### 🤖 **AI-Powered Analysis (Enhanced!)**
- 🧠 **Claude AI Integration** - Advanced ticket analysis using Claude via Azure DevOps MCP server
- 🔍 **Smart Prioritization** - AI-driven priority assessment with detailed reasoning
- 📝 **Intelligent Summarization** - Context-aware content summaries and key point extraction
- 💡 **Action Recommendations** - AI-generated next steps and impact analysis
- 🔄 **Enhanced Fallback Support** - Graceful degradation to traditional analysis with detailed error reporting
- 🚨 **Detailed Error Messages** - Specific error reasons displayed in all output formats (console, HTML, text, email)

### 🔐 **Enhanced Authentication**
- ☁️ **Azure CLI Authentication** - Seamless integration with `az login --allow-no-subscriptions` (recommended)
- 🔑 **Personal Access Token** - Secure PAT-based authentication with fallback support
- 🪟 **Windows Authentication** - Native Windows/Kerberos authentication for on-premise TFS
- 🔄 **Automatic Fallback** - Smart authentication fallback chain for reliability

### 📊 **Traditional Analysis**
- 🎯 **Intelligent Priority Scoring** - HIGH/MEDIUM/LOW classification with keyword analysis
- 💬 **Comment Analysis** - Extracts decisions and action items from recent comments
- 📋 **Acceptance Criteria** - Highlights important requirements and test scenarios
- 🔗 **@Mention Detection** - Finds tickets where you're mentioned
- ⚡ **Cross-Platform** - Works on Windows, Linux, and macOS
- 📧 **Email Delivery** - Automated HTML reports via email
- 🔄 **Smart Automation** - Multiple scheduling options

## 🛠️ Dependencies

### **Windows (PowerShell)**
- PowerShell 5.1+ or PowerShell 7+
- Internet access to TFS server
- No additional packages required

### **Linux/Mac (Bash)**
- Bash 4.0+ (or zsh on macOS)
- curl command-line tool
- cron service (for automation)

### **Python (All Platforms)**
- Python 3.6 or higher
- Install with: `pip install -r requirements.txt`

**Python Package Dependencies:**
- `requests>=2.25.0` - HTTP requests to TFS API
- `configparser>=5.0.0` - Configuration file handling
- `requests-ntlm>=1.1.0` - Windows/Kerberos authentication (optional)
- `colorama>=0.4.4` - Colored console output (optional)
- `python-dateutil>=2.8.0` - Advanced date parsing (optional)

### **TFS Requirements**
- Team Foundation Server with REST API access
- Personal Access Token with "Work Items (Read)" permission
- Network connectivity to TFS server

## 🔧 Configuration

Configuration is stored locally within the project directory for better security and portability:

### **File Locations**
- **All Platforms**: `PROJECT_ROOT/.config/.tfs-analyzer-config`
- **Claude Configuration**: `PROJECT_ROOT/.config/.tfs-analyzer-claude-config`
- **Claude Code MCP**: `PROJECT_ROOT/.config/claude-code-config.json`

> **📁 Note**: Configuration files are stored in the project's `.config` directory and are automatically excluded from version control via `.gitignore` for security.

### **Configuration Format**

**PowerShell Version:**
```ini
TFS_URL=https://tfs.YOUR_ORGANIZATION.com/tfs/YOUR_ORGANIZATION
PROJECT_NAME=YOUR_PROJECT
PAT=your_personal_access_token_here
USER_DISPLAY_NAME=Your Display Name
```

**Bash Version:**
```bash
TFS_URL="https://tfs.YOUR_ORGANIZATION.com/tfs/YOUR_ORGANIZATION"
PROJECT_NAME="YOUR_PROJECT"
PAT="your_personal_access_token_here"
USER_DISPLAY_NAME="Your Display Name"
DEFAULT_OUTPUT="browser"
USE_WINDOWS_AUTH="false"
```

**Python Version:**
```ini
[tfs]
tfs_url = https://tfs.YOUR_ORGANIZATION.com/tfs/YOUR_ORGANIZATION
project_name = YOUR_PROJECT
pat = your_personal_access_token_here
user_display_name = Your Display Name
default_output = console
use_windows_auth = false
```

## 🔐 Personal Access Token Setup

1. Go to TFS: `https://tfs.YOUR_ORGANIZATION.com/tfs/YOUR_ORGANIZATION`
2. Click your profile → Security → Personal Access Tokens
3. Create new token with **Work Items (Read)** permission
4. Save the token securely

## 📋 What It Analyzes

### **Data Sources**
- **Assigned Tickets**: All work items assigned to you
- **@Mention Tickets**: Work items where you're mentioned in comments
- **Recent Activity**: Configurable time range (last N days)

### **Work Item Types Analyzed**
- Bugs, Tasks, Product Backlog Items, Epics
- User Stories, Features, Test Cases
- Custom work item types

### **Priority Scoring Logic**

| Factor | High Score | Medium Score | Low Score |
|--------|------------|--------------|-----------|
| **State** | In Progress, Active | New, Committed | To Do, Done |
| **Type** | Bug | Task, PBI | Epic |
| **Keywords** | SHOWSTOPPER, CRITICAL | ERROR, BROKEN | Normal text |
| **Priority Field** | 1 (Highest) | 2-3 | 4+ (Lowest) |
| **Severity** | 1-Critical, 2-High | 3-Medium | 4-Low |

### **Intelligent Content Analysis**
- **📋 Summary**: AI-powered overview of ticket purpose and scope
- **📌 Key Points**: Requirements, acceptance criteria, test scenarios
- **⚖️ Recent Decisions**: Extracted decisions and status changes
- **▶️ Action Items**: Next steps and pending tasks
- **🔍 Root Cause Analysis**: For bugs, identifies likely causes
- **📈 Impact Assessment**: Business and technical impact evaluation

## 🎯 Usage Examples

**Windows PowerShell:**
```powershell
# Initial setup
.\tfs-analyzer.ps1 setup

# Daily standup prep with AI
.\tfs-analyzer.ps1 1 -Claude -Browser

# Weekly review
.\tfs-analyzer.ps1 7 -Html

# Email daily summary
.\tfs-analyzer.ps1 1 -Email

# Traditional analysis
.\tfs-analyzer.ps1 3 -NoAI -Text

# Setup daily automation
.\tfs-scheduler-daily.ps1 -Time "08:00" -OutputMethod browser

# Setup smart automation
.\tfs-scheduler-smart.ps1 -OutputMethod browser
```

**Linux/Mac Bash:**
```bash
# Initial setup
./tfs-analyzer.sh setup

# Daily analysis
./tfs-analyzer.sh 1 --output browser

# Setup automation
./tfs-scheduler.sh --time 08:00 --output browser

# Test authentication
./tfs-analyzer.sh test-auth
```

**Python Cross-Platform:**
```bash
# Install dependencies
pip install -r requirements.txt

# Setup
python tfs-analyzer.py --setup

# Daily analysis
python tfs-analyzer.py 1 --output browser

# Verbose mode for debugging
python tfs-analyzer.py 1 --verbose --output console
```

## 🔍 Troubleshooting

### **Common Issues**

**❌ "No configuration found"**
```bash
# Run setup first
.\tfs-analyzer.ps1 setup           # Windows
./tfs-analyzer.sh setup            # Linux/Mac
python tfs-analyzer.py --setup     # Python
```

**❌ "Failed to connect to TFS"**
- Verify TFS URL format: `https://tfs.YOUR_ORGANIZATION.com/tfs/YOUR_ORGANIZATION`
- Check PAT permissions (Work Items - Read required)
- Test PAT in browser: visit TFS URL while logged in

**❌ "No tickets found"**
- Try longer time range: `.\tfs-analyzer.ps1 7`
- Verify you have assigned tickets or @mentions
- Check display name matches TFS exactly

**❌ "Authentication failed"**
- Regenerate PAT in TFS Security settings
- Ensure PAT hasn't expired
- Try Windows authentication: `.\tfs-analyzer.ps1 setup -UseWindowsAuth`

### **Platform-Specific Issues**

**Windows:**
- Run PowerShell as Administrator for automation setup
- Check execution policy: `Set-ExecutionPolicy RemoteSigned`

**Linux/Mac:**
- Ensure scripts are executable: `chmod +x *.sh`
- Check cron service: `systemctl status cron` (Linux)
- Verify curl is installed: `curl --version`

**Python:**
- Install missing dependencies: `pip install -r requirements.txt`
- Check Python version: `python --version` (3.6+ required)
- Use virtual environment if needed

## 📄 Output File Locations

**Windows:**
- HTML: `%USERPROFILE%\Documents\TFS-Daily-Summary.html`
- Text: `%USERPROFILE%\Documents\TFS-Daily-Summary.txt`

**Linux/Mac:**
- HTML: `~/Downloads/TFS-Daily-Summary.html` (or `~/Documents/`)
- Text: `~/Downloads/TFS-Daily-Summary.txt` (or `~/Documents/`)

## 🔧 Advanced Configuration

### **Authentication Methods**
```powershell
# Personal Access Token (Recommended)
.\tfs-analyzer.ps1 setup

# Windows/Kerberos Authentication
.\tfs-analyzer.ps1 setup -UseWindowsAuth

# Test authentication
.\tfs-analyzer.ps1 test-auth
```

### **Debug Modes**
```powershell
# Enable debug output
.\tfs-analyzer.ps1 1 -Debug -ShowInBrowser

# Verbose processing
.\tfs-analyzer.ps1 1 -Details -SaveHtml

# Silent mode
.\tfs-analyzer.ps1 1 -Quiet -SaveText
```

### **Custom Queries**
```powershell
# Custom WIQL query
.\tfs-analyzer.ps1 -CustomQuery "SELECT * FROM workitems WHERE [State] = 'Active'"

# Filter by work item types  
.\tfs-analyzer.ps1 3 -WorkItemTypes "Bug,Task" -ShowInBrowser
```

## 🤖 Claude AI Integration

### **Setup Requirements**
1. **Claude Code CLI**: Download and install from [claude.ai/code](https://claude.ai/code)
2. **Azure DevOps MCP Server**: Automatically configured during setup
3. **Authentication**: Uses Azure CLI or falls back to PAT

### **AI Enhancement Features**
- **Intelligent Priority Assessment**: AI analyzes ticket content for smarter priority scoring
- **Content Summarization**: Extracts key information and provides context-aware summaries
- **Action Recommendations**: Suggests specific next steps based on ticket analysis
- **Impact Assessment**: Evaluates business and technical impact
- **Decision Tracking**: Identifies important decisions from comments and history

### **Configuration Files**
- **Main Config**: `PROJECT_ROOT/.config/.tfs-analyzer-config`
- **Claude Config**: `PROJECT_ROOT/.config/.tfs-analyzer-claude-config`  
- **Claude Code MCP**: `PROJECT_ROOT/.config/claude-code-config.json`

### **Enhanced Error Reporting**
When Claude AI analysis fails, all three platforms now provide **detailed error reporting**:
- **Specific Error Messages**: Shows exactly why Claude failed (CLI not found, authentication issues, timeouts, etc.)
- **Cross-Platform Consistency**: Same error messages across Windows, Linux/Mac, and Python versions
- **Multiple Display Formats**: Errors shown in console, HTML, text, and email outputs
- **Actionable Solutions**: Each error includes specific steps to resolve the issue

**Common Error Messages:**
- `Claude Code CLI not found. Run setup-claude first.`
- `No valid authentication method available. Configure Azure CLI or PAT.`
- `Command timed out after 120 seconds`
- `Authentication verification failed.`

### **Fallback Strategy**
If Claude AI analysis fails:
1. **Detailed Error Display**: Shows specific failure reason in all output formats
2. **Automatic fallback** to traditional analysis with error explanation
3. **Graceful error handling** and user notification
4. **Full functionality maintained** without AI features
5. **Error persistence** in summary reports for troubleshooting

## 📚 Additional Information

### **Authentication Methods**

**Azure CLI (Recommended)**
```powershell
# Login to Azure CLI (tenant-level access for Azure DevOps)
az login --allow-no-subscriptions

# Configure for specific organization
az devops configure --defaults organization=https://tfs.deltek.com/tfs/Deltek project=TIP

# Test authentication
.\tfs-analyzer.ps1 test-auth
```

**Personal Access Token**
1. Go to your TFS/Azure DevOps organization
2. User Settings → Personal Access Tokens
3. Create token with "Work Items (Read)" permission
4. Use during setup or as fallback

### **Email Setup**
When using email output, you'll be prompted for:
- Email address (supports Office 365, Gmail, Yahoo auto-configuration)
- Password or app-specific password
- SMTP settings (auto-configured for common providers)

### **Automation Management**

**Windows:**
```powershell
# View scheduled tasks
Get-ScheduledTask -TaskName "*TFS*"

# Run task immediately
Start-ScheduledTask -TaskName "TFS-Daily-Ticket-Analysis-NoSMTP"

# Remove automation
.\tfs-scheduler-daily.ps1 -Remove
.\tfs-scheduler-smart.ps1 -Remove
```

**Linux/Mac:**
```bash
# List cron jobs
crontab -l

# Edit cron jobs
crontab -e

# Remove TFS automation
./tfs-scheduler.sh --remove
```

## 🆕 Latest Updates

### **Version 2.3.0 - Local Configuration & Enhanced Error Reporting**
- ✅ **Local Configuration Storage**: All configuration files now stored in project's `.config` directory for better security and portability
- ✅ **Enhanced Security**: Configuration files automatically excluded from version control
- ✅ **Detailed Claude Error Messages**: All platforms now show specific reasons when Claude AI analysis fails
- ✅ **Cross-Platform Error Consistency**: Same error messages across PowerShell, Bash, and Python versions
- ✅ **Error Display in All Formats**: Error reasons shown in console, HTML, text, and email outputs
- ✅ **Improved Claude Code CLI Integration**: Updated to use `--print --output-format json` with stdin
- ✅ **Enhanced Timeout Handling**: 120-second timeout with specific timeout error messages
- ✅ **Better Authentication Feedback**: Clear messages for Azure CLI vs PAT authentication failures

### **Previous Updates**
- ✅ **Simplified Parameters**: Clean long-form flags for all operations (debug `-d` is the only short flag)
- ✅ **Cross-Platform Claude AI**: Full Claude integration on Windows, Linux/Mac, and Python
- ✅ **Enhanced Authentication**: Azure CLI integration with PAT fallback
- ✅ **Smart Automation**: Flexible scheduling with startup and daily triggers

---

This enhanced TFS/Azure DevOps ticket analyzer provides AI-powered analysis with comprehensive fallback options, multiple authentication methods, and flexible automation for any development team using Team Foundation Server or Azure DevOps.

## 🔧 Troubleshooting

### **Configuration Migration (v2.3.0+)**

**🆕 Local Configuration Storage**
Starting with v2.3.0, all configuration files are stored locally in the project's `.config` directory instead of user directories for better security and portability.

**❓ "No configuration found" after update**
If you had previous configurations, you'll need to run setup again:
```powershell
# Windows
.\tfs-analyzer.ps1 setup

# Linux/Mac
./tfs-analyzer.sh setup

# Python
python tfs-analyzer.py --setup
```

**📁 Configuration File Locations (New)**
- **All Configurations**: `PROJECT_ROOT/.config/`
- **Automatically excluded** from version control via `.gitignore`
- **More secure**: No sensitive data in user directories
- **Portable**: Configuration travels with the project

### **Claude AI Issues**

**🆕 Enhanced Error Reporting**
All platforms now show **detailed error messages** when Claude AI analysis fails. The error will appear in your output (console, HTML, text, or email) with specific reasons and solutions.

**❌ "Claude Code CLI not found. Run setup-claude first."**
```powershell
# Install Claude Code from claude.ai/code
# Verify installation
claude-code --help

# Re-run Claude setup
.\tfs-analyzer.ps1 setup-claude          # Windows
./tfs-analyzer.sh setup-claude           # Linux/Mac
python tfs-analyzer.py --setup-claude    # Python
```

**❌ "No valid authentication method available. Configure Azure CLI or PAT."**
```bash
# Option 1: Azure CLI (Recommended)
az login

# Option 2: PAT Configuration
.\tfs-analyzer.ps1 setup                 # Windows - reconfigure with PAT
./tfs-analyzer.sh setup                  # Linux/Mac
python tfs-analyzer.py --setup           # Python
```

**❌ "Command timed out after 120 seconds"**
- Large datasets may cause timeouts
- Try analyzing fewer days: `.\tfs-analyzer.ps1 1 -Claude`
- Use traditional analysis for large datasets: `.\tfs-analyzer.ps1 7 -NoAI`

**❌ "Authentication verification failed."**
- Check Azure CLI login: `az account show`
- Verify PAT hasn't expired
- Test authentication: `.\tfs-analyzer.ps1 test-auth`

**❌ General Claude Analysis Issues**
- Script automatically falls back to traditional analysis with error details
- Check detailed error message in output
- Use `-Details` flag for additional debug information
- Test with `-NoAI` to bypass AI analysis temporarily

### **Authentication Issues**

**❌ "Azure CLI authentication failed"**
```powershell
# Re-login to Azure CLI (tenant-level access)
az login --allow-no-subscriptions

# Verify account
az account show

# Test connection
.\tfs-analyzer.ps1 test-auth
```

**❌ "All authentication methods failed"**
- Ensure you have proper permissions
- Verify TFS URL format
- Check network connectivity
- Try different authentication method in setup

### **Enhanced Commands**

**Windows PowerShell:**
```powershell
# Setup and configuration
.\tfs-analyzer.ps1 setup           # Main setup with auth choice
.\tfs-analyzer.ps1 setup-claude    # Claude AI integration
.\tfs-analyzer.ps1 setup-output    # Output preferences
.\tfs-analyzer.ps1 test-auth       # Test all authentication methods

# Analysis modes
.\tfs-analyzer.ps1 1               # Use configured default
.\tfs-analyzer.ps1 3 -Claude        # Force AI analysis
.\tfs-analyzer.ps1 7 -NoAI          # Traditional analysis only
.\tfs-analyzer.ps1 1 -Details       # Detailed debug output

# Output options
.\tfs-analyzer.ps1 1 -Browser       # Open in browser
.\tfs-analyzer.ps1 3 -Html          # Save HTML file
.\tfs-analyzer.ps1 7 -Text          # Save text file
.\tfs-analyzer.ps1 1 -Email         # Send via email

# Combined options (mix and match)
.\tfs-analyzer.ps1 3 -Claude -Html  # AI analysis + HTML output
.\tfs-analyzer.ps1 1 -Browser -Details # Browser + debug info
.\tfs-analyzer.ps1 7 -NoAI -Text    # Traditional + text output
.\tfs-analyzer.ps1 2 -Claude -Browser -Details # AI + browser + debug
```

**Linux/Mac Bash:**
```bash
# Setup and configuration
./tfs-analyzer.sh setup             # Main setup with auth choice
./tfs-analyzer.sh setup-claude      # Claude AI integration
./tfs-analyzer.sh test-auth         # Test authentication

# Analysis modes
./tfs-analyzer.sh 1                     # Use configured default
./tfs-analyzer.sh 3 --claude            # Force AI analysis
./tfs-analyzer.sh 7 --no-ai             # Traditional analysis only
./tfs-analyzer.sh 1 -d                  # Detailed debug output

# Output options
./tfs-analyzer.sh 1 --browser           # Open in browser
./tfs-analyzer.sh 3 --html              # Save HTML file
./tfs-analyzer.sh 7 --text              # Save text file
./tfs-analyzer.sh 1 --email             # Send via email

# Combined options (mix and match)
./tfs-analyzer.sh 3 --claude --html     # AI analysis + HTML output
./tfs-analyzer.sh 1 --browser -d        # Browser + debug info
./tfs-analyzer.sh 7 --no-ai --text      # Traditional + text output
./tfs-analyzer.sh 2 --claude --browser -d # AI + browser + debug
```

**Python (All Platforms):**
```bash
# Setup and configuration
python tfs-analyzer.py --setup      # Main setup with auth choice
python tfs-analyzer.py --setup-claude # Claude AI integration
python tfs-analyzer.py --test-auth  # Test authentication

# Analysis modes
python tfs-analyzer.py 1                # Use configured default
python tfs-analyzer.py 3 --claude       # Force AI analysis
python tfs-analyzer.py 7 --no-ai        # Traditional analysis only
python tfs-analyzer.py 1 -d             # Detailed debug output

# Output options
python tfs-analyzer.py 1 --browser      # Open in browser
python tfs-analyzer.py 3 --html         # Save HTML file
python tfs-analyzer.py 7 --text         # Save text file
python tfs-analyzer.py 1 --email        # Send via email

# Combined options (mix and match)
python tfs-analyzer.py 3 --claude --html  # AI analysis + HTML output
python tfs-analyzer.py 1 --browser -d     # Browser + debug info
python tfs-analyzer.py 7 --no-ai --text   # AI disabled + text output
python tfs-analyzer.py 2 --claude --browser -d # AI + browser + debug
```

---

## 📋 **Version History & Changelog**

### **Version 2.3.1** (Latest - August 2025)

#### **🔧 Bug Fixes**
- **FIXED: Authentication Issues for On-premises TFS**
  - Resolved authentication inconsistency between `test-claude` and main script execution
  - Fixed Azure CLI authentication for Azure AD-integrated on-premises TFS servers
  - Improved authentication detection logic to properly handle tenant-level Azure CLI authentication
  - Updated PowerShell requests to use `-UseDefaultCredentials` when appropriate

#### **✨ Improvements** 
- **Enhanced Debug Output Control**
  - Debug messages now only appear when using `-Details` flag (PowerShell), `-d` flag (Bash/Python)
  - Cleaner console output for regular usage
  - Improved troubleshooting with comprehensive debug information when requested

#### **🛠️ Technical Changes**
- Added `Invoke-TfsRestMethod` helper function for consistent authentication handling
- Implemented script-level variable scoping for debug output control
- Enhanced `Write-DebugOutput` function with proper parameter handling
- Updated all REST API calls to use unified authentication approach

### **Version 2.3.0** (August 2025)

#### **🔒 Security & Configuration**
- **Moved all configuration to local project directory** (`.config/` folder)
- Enhanced `.gitignore` with comprehensive security exclusions  
- Updated all scripts to use local configuration storage
- Improved configuration portability and security

#### **🚀 New Features**
- **Cross-platform Claude AI integration** with MCP server support
- **Interactive authentication setup** with guided prompts
- **Enhanced error handling** and user-friendly error messages
- **Simplified parameter names** for easier daily usage

#### **🔧 Fixes**
- Fixed Unicode character display issues across all platforms
- Removed duplicate words from Unicode character replacements
- Enhanced Azure CLI integration with `--allow-no-subscriptions` support
- Improved cross-platform compatibility

---

## 🔐 **Authentication Troubleshooting**

### **For On-premises TFS with Azure AD Integration**

If you're using on-premises TFS that's integrated with Azure AD (like `https://tfs.yourcompany.com`):

1. **Run Azure CLI authentication** (recommended):
   ```bash
   az login --allow-no-subscriptions
   ```

2. **Test the authentication**:
   ```powershell
   # PowerShell
   .\tfs-analyzer.ps1 test-claude
   
   # Bash/Linux/Mac  
   ./tfs-analyzer.sh test-claude
   
   # Python
   python tfs-analyzer.py --test-claude
   ```

3. **If you get authentication errors**:
   - Verify you can access your TFS server in a browser
   - Ensure you're logged in with the correct Azure AD account
   - Try running setup again: `.\tfs-analyzer.ps1 setup`

### **Authentication Methods by Environment**

| Environment | Recommended Method | Alternative |
|-------------|-------------------|-------------|
| **Azure DevOps Cloud** | Azure CLI (`az login`) | Personal Access Token |
| **On-premises TFS + Azure AD** | Azure CLI (`az login --allow-no-subscriptions`) | Personal Access Token |  
| **Traditional On-premises TFS** | Personal Access Token | Windows Authentication |

### **Getting More Help**

- Use `-Details` (PowerShell) or `-d` (Bash/Python) for debug information
- Check the generated debug file: `TFS-Debug-Data.txt`  
- Verify your TFS URL format and project name in the configuration