# TFS Ticket Analyzer

A comprehensive **cross-platform** tool that analyzes your TFS tickets (both assigned and @mentioned) and provides intelligent priority rankings and action recommendations with multiple output formats.

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

### **Automation Schedulers**
- **`tfs-scheduler-daily.ps1`** - Windows daily automation
- **`tfs-scheduler-smart.ps1`** - Windows smart scheduling (startup + daily)
- **`tfs-scheduler.sh`** - Linux/Mac automation setup

### **Dependencies**
- **`requirements.txt`** - Python package dependencies

## 🚀 Quick Start

### 1. First-time Setup

**Windows:**
```powershell
.\tfs-analyzer.ps1 setup
```

**Linux/Mac (Bash):**
```bash
./tfs-analyzer.sh setup
```

**Python (Any Platform):**
```bash
# Install dependencies first
pip install -r requirements.txt

# Run setup
python tfs-analyzer.py --setup
```

You'll be prompted for:
- **TFS URL**: `https://tfs.YOUR_ORGANIZATION.com/tfs/YOUR_ORGANIZATION`
- **Project Name**: `YOUR_PROJECT`
- **Personal Access Token**: Your TFS PAT
- **Display Name**: For @mention detection

### 2. Daily Analysis

**Windows:**
```powershell
# Analyze last 24 hours - show in browser
.\tfs-analyzer.ps1 1 -ShowInBrowser

# Analyze last 3 days - save HTML file
.\tfs-analyzer.ps1 3 -SaveHtml

# Analyze last week - save text summary
.\tfs-analyzer.ps1 7 -SaveText
```

**Linux/Mac (Bash):**
```bash
# Analyze last 24 hours - show in browser
./tfs-analyzer.sh 1 --output browser

# Analyze last 3 days - save HTML file
./tfs-analyzer.sh 3 --output html

# Analyze last week - save text summary
./tfs-analyzer.sh 7 --output text
```

**Python (Any Platform):**
```bash
# Analyze last 24 hours - show in browser
python tfs-analyzer.py 1 --output browser

# Analyze last 3 days - save HTML file
python tfs-analyzer.py 3 --output html

# Analyze last week - save text summary
python tfs-analyzer.py 7 --output text
```

## 🔄 Automation Setup

### **Windows Automation**

**Daily Schedule (Fixed Time):**
```powershell
# Daily at 8:00 AM with browser output
.\tfs-scheduler-daily.ps1 -Time "08:00" -OutputMethod browser

# Daily at midnight with HTML output
.\tfs-scheduler-daily.ps1 -Time "00:30" -OutputMethod html
```

**Smart Schedule (Recommended):**
```powershell
# Runs at startup OR daily (whichever comes first)
.\tfs-scheduler-smart.ps1 -OutputMethod browser

# With custom daily backup time
.\tfs-scheduler-smart.ps1 -OutputMethod browser -Time "09:00"

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
# Daily at 8:00 AM with browser output
./tfs-scheduler.sh --time 08:00 --output browser

# Daily at 9:30 AM with HTML file output
./tfs-scheduler.sh --time 09:30 --output html

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

- 🎯 **Intelligent Priority Scoring** - HIGH/MEDIUM/LOW classification
- 🔍 **Content Analysis** - AI-powered ticket summaries and insights
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

Configuration is stored in platform-appropriate locations:

### **File Locations**
- **Windows**: `%USERPROFILE%\.tfs-analyzer-config`
- **Linux/Mac**: `~/.config/.tfs-analyzer-config`

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

# Daily standup prep
.\tfs-analyzer.ps1 1 -ShowInBrowser

# Weekly review
.\tfs-analyzer.ps1 7 -SaveHtml

# Email daily summary
.\tfs-analyzer.ps1 1 -SendEmail

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
.\tfs-analyzer.ps1 1 -Verbose -SaveHtml

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

## 📚 Additional Information

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

This cross-platform TFS ticket analyzer provides comprehensive ticket analysis and flexible automation options for any development team using Team Foundation Server.