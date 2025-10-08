# TFS Ticket Analyzer - Testing Guide

This guide helps you test the TFS Ticket Analyzer on different platforms.

## Table of Contents
1. [Windows Testing](#windows-testing)
2. [Linux Testing](#linux-testing)
3. [macOS Testing](#macos-testing)
4. [Feature Checklist](#feature-checklist)
5. [Troubleshooting Common Issues](#troubleshooting-common-issues)

---

## Windows Testing

### Prerequisites
- Windows 10 or later
- PowerShell 5.1 or PowerShell 7+
- Administrator access (for scheduler testing)

### Test 1: Basic Setup

```powershell
# Easy Setup Wizard (Recommended for beginners)
.\easy-setup.ps1

# OR Manual Setup
.\tfs-analyzer.ps1 setup
```

**Expected Result:**
- Interactive prompts for TFS URL, project name, auth method
- Configuration saved to `.config/.tfs-analyzer-config`
- No errors during save

### Test 2: Authentication Testing

```powershell
# Test TFS connection
.\tfs-analyzer.ps1 test-auth
```

**Expected Result:**
- `[OK] Authentication successful!` message
- No connection errors

### Test 3: Basic Analysis

```powershell
# Analyze last 1 day
.\tfs-analyzer.ps1 1 -Browser

# Analyze last 7 days
.\tfs-analyzer.ps1 7 -Html

# Console output
.\tfs-analyzer.ps1 3 -Console
```

**Expected Result:**
- Work items retrieved from TFS
- Proper priority classification (HIGH/MEDIUM/LOW)
- Output opens in browser/saves file/displays in console
- No script errors

### Test 3a: Hours-Based Analysis

```powershell
# Analyze last 12 hours
.\tfs-analyzer.ps1 12 -Hours -Browser

# Analyze last 6 hours with AI
.\tfs-analyzer.ps1 6 -Hours -Claude -Html

# Analyze last 24 hours to text
.\tfs-analyzer.ps1 24 -Hours -Text
```

**Expected Result:**
- Work items retrieved from correct time range (hours, not days)
- Proper time description in output ("last 12 hours" vs "last 12 days")
- All output methods work correctly with hours
- Date calculations accurate for hours

### Test 4: Claude AI Integration (Optional)

```powershell
# Setup Claude AI
.\tfs-analyzer.ps1 setup-claude

# Test Claude configuration
.\tfs-analyzer.ps1 test-claude

# Run with Claude AI
.\tfs-analyzer.ps1 1 -Claude -Browser
```

**Expected Result:**
- Claude Code CLI detected
- Authentication method verified (Azure CLI or PAT)
- AI-enhanced analysis completed
- Falls back to traditional if Claude fails

### Test 5: Scheduler Setup

```powershell
# Must run as Administrator
# Open PowerShell as Admin first

# Daily scheduler
.\tfs-scheduler-daily.ps1 -Time "08:00" -OutputMethod browser

# Smart scheduler (startup + daily)
.\tfs-scheduler-smart.ps1 -OutputMethod browser -Time "09:00"

# Verify task created
Get-ScheduledTask -TaskName "*TFS*"

# Test run immediately
Start-ScheduledTask -TaskName "TFS-Daily-Ticket-Analysis-NoSMTP"
```

**Expected Result:**
- Task created successfully in Task Scheduler
- Task runs without errors
- Output appears as configured (browser/HTML/text)

### Test 6: Remove Scheduler

```powershell
# Remove daily scheduler
.\tfs-scheduler-daily.ps1 -Remove

# Remove smart scheduler
.\tfs-scheduler-smart.ps1 -Remove

# Verify removal
Get-ScheduledTask -TaskName "*TFS*"
```

**Expected Result:**
- Tasks removed successfully
- No TFS tasks in Task Scheduler

---

## Linux Testing

### Prerequisites
- Linux distribution (Ubuntu, Debian, CentOS, etc.)
- Bash 4.0+
- curl command-line tool
- Python 3.6+ (for Python version testing)

### Test 1: Script Permissions

```bash
# Make scripts executable
chmod +x tfs-analyzer.sh tfs-scheduler.sh

# Verify permissions
ls -l tfs-analyzer.sh tfs-scheduler.sh
```

**Expected Result:**
- Scripts have execute permission (`-rwxr-xr-x`)

### Test 2: Basic Setup (Bash Version)

```bash
# Interactive setup
./tfs-analyzer.sh setup

# Test authentication
./tfs-analyzer.sh test-auth
```

**Expected Result:**
- Configuration saved to `.config/.tfs-analyzer-config`
- File permissions set to 600 (read/write owner only)
- Authentication test passes

### Test 3: Basic Analysis (Bash Version)

```bash
# Browser output
./tfs-analyzer.sh 1 -b

# HTML file
./tfs-analyzer.sh 3 -h

# Text file
./tfs-analyzer.sh 7 -t

# Console output
./tfs-analyzer.sh 1 --output console
```

**Expected Result:**
- Work items retrieved successfully
- Files saved to `~/Downloads/` or `~/Documents/`
- No bash syntax errors
- Proper ANSI color codes in terminal

### Test 3a: Hours-Based Analysis (Bash Version)

```bash
# Hours-based analysis
./tfs-analyzer.sh 12 --hours -b        # Last 12 hours in browser
./tfs-analyzer.sh 6 --hours -c -h      # Last 6 hours with AI to HTML
./tfs-analyzer.sh 24 --hours -t        # Last 24 hours to text file
```

**Expected Result:**
- Work items filtered by hours instead of days
- Time description shows "hours" in output
- Date calculations correct for all platforms (GNU date vs BSD date)
- No date parsing errors

### Test 4: Python Version Testing

```bash
# Install dependencies
pip install -r requirements.txt

# Setup
python tfs-analyzer.py --setup

# Test authentication
python tfs-analyzer.py --test-auth

# Run analysis
python tfs-analyzer.py 1 -b
python tfs-analyzer.py 3 -h
python tfs-analyzer.py 7 -t
```

**Expected Result:**
- All Python dependencies install correctly
- Configuration works identically to bash version
- Cross-platform paths work correctly

### Test 5: Scheduler Setup (Linux)

```bash
# Interactive setup
./tfs-scheduler.sh

# Manual setup
./tfs-scheduler.sh --time 08:00 --output browser

# Verify cron job
crontab -l | grep tfs-analyzer

# Remove scheduler
./tfs-scheduler.sh --remove
```

**Expected Result:**
- Cron job added successfully
- Job runs at specified time
- Output appears as configured

### Test 6: Claude AI (Linux)

```bash
# Bash version
./tfs-analyzer.sh setup-claude
./tfs-analyzer.sh test-claude
./tfs-analyzer.sh 1 -c -b

# Python version
python tfs-analyzer.py --setup-claude
python tfs-analyzer.py --test-claude
python tfs-analyzer.py 1 -c -b
```

**Expected Result:**
- Claude Code CLI detected on Linux
- Azure CLI authentication works
- AI analysis completes or falls back gracefully

---

## macOS Testing

### Prerequisites
- macOS 10.15 (Catalina) or later
- Bash or zsh shell
- curl (pre-installed)
- Python 3.6+ (pre-installed or via Homebrew)

### Test 1: Script Permissions

```bash
# Make executable
chmod +x tfs-analyzer.sh tfs-scheduler.sh

# Verify
ls -l *.sh
```

**Expected Result:**
- Execute permissions set correctly

### Test 2: Basic Setup and Analysis

```bash
# Setup (bash version)
./tfs-analyzer.sh setup
./tfs-analyzer.sh test-auth
./tfs-analyzer.sh 1 -b

# Setup (Python version - recommended for macOS)
pip3 install -r requirements.txt
python3 tfs-analyzer.py --setup
python3 tfs-analyzer.py --test-auth
python3 tfs-analyzer.py 1 -b
```

**Expected Result:**
- Configuration works correctly
- Files save to correct macOS directories
- Browser opens with HTML report

### Test 3: Scheduler Setup (macOS)

```bash
# macOS uses launchd instead of cron
# The scheduler should detect macOS and adjust

./tfs-scheduler.sh --time 08:00 --output browser

# Verify (cron on macOS)
crontab -l

# Or check launchd
launchctl list | grep tfs
```

**Expected Result:**
- Scheduler configured for macOS
- Jobs run at scheduled time

---

## Feature Checklist

Use this checklist to verify all features work correctly:

### Core Features
- [ ] Basic TFS connection with PAT
- [ ] Azure CLI authentication (optional)
- [ ] Windows authentication (Windows only)
- [ ] Retrieve assigned work items
- [ ] Detect @mentions in work items
- [ ] Days-based time range (1, 3, 7, etc.)
- [ ] Hours-based time range (6, 12, 24, etc.)
- [ ] Correct date calculations for both days and hours
- [ ] Priority scoring (HIGH/MEDIUM/LOW)
- [ ] Traditional content analysis

### Output Methods
- [ ] Browser output (HTML opens automatically)
- [ ] HTML file (saved to Documents/Downloads)
- [ ] Text file (plain text summary)
- [ ] Console output (colored terminal display)
- [ ] Email delivery (with SMTP config)

### Claude AI Features
- [ ] Claude AI setup wizard
- [ ] Claude authentication test
- [ ] AI-enhanced priority assessment
- [ ] Smart summarization
- [ ] Action recommendations
- [ ] Graceful fallback to traditional analysis
- [ ] Error messages in all output formats

### Automation Features
- [ ] Daily scheduler (Windows Task Scheduler)
- [ ] Smart scheduler (startup + daily)
- [ ] Cron job setup (Linux/Mac)
- [ ] Scheduler removal commands
- [ ] Task runs without errors

### Configuration
- [ ] Interactive setup wizard
- [ ] Easy setup wizard (beginner-friendly)
- [ ] Configuration file creation
- [ ] Secure file permissions (Unix)
- [ ] Multiple configuration profiles

### Cross-Platform
- [ ] Windows PowerShell version works
- [ ] Linux bash version works
- [ ] macOS bash version works
- [ ] Python version works on all platforms
- [ ] Consistent behavior across platforms

---

## Troubleshooting Common Issues

### Issue: "Execution policy prevents script from running" (Windows)

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: "Permission denied" (Linux/Mac)

**Solution:**
```bash
chmod +x tfs-analyzer.sh tfs-scheduler.sh
```

### Issue: "Configuration not found"

**Solution:**
```bash
# Run setup first
.\tfs-analyzer.ps1 setup          # Windows
./tfs-analyzer.sh setup            # Linux/Mac
python tfs-analyzer.py --setup     # Python
```

### Issue: "Authentication failed"

**Checks:**
1. Verify TFS URL is correct
2. Check PAT hasn't expired
3. Verify PAT has "Work Items (Read)" permission
4. Try Azure CLI: `az login --allow-no-subscriptions`
5. Test with: `.\tfs-analyzer.ps1 test-auth`

### Issue: "No work items found"

**Checks:**
1. Increase time range: `.\tfs-analyzer.ps1 7`
2. Verify you have assigned tickets in TFS
3. Check display name matches TFS exactly
4. Run with debug: `.\tfs-analyzer.ps1 1 -Details`

### Issue: "Claude AI not working"

**Solution:**
```bash
# Check Claude Code installation
claude-code --version

# Re-run setup
.\tfs-analyzer.ps1 setup-claude

# Test configuration
.\tfs-analyzer.ps1 test-claude

# Use traditional analysis
.\tfs-analyzer.ps1 1 --no-ai -Browser
```

### Issue: "Scheduler not running"

**Windows:**
```powershell
# Check task exists
Get-ScheduledTask -TaskName "*TFS*"

# Check task history
Get-ScheduledTask -TaskName "TFS-Daily-Ticket-Analysis-NoSMTP" | Get-ScheduledTaskInfo

# Run manually
Start-ScheduledTask -TaskName "TFS-Daily-Ticket-Analysis-NoSMTP"
```

**Linux/Mac:**
```bash
# Check cron job
crontab -l

# Check cron service (Linux)
systemctl status cron

# View cron logs (Linux)
grep CRON /var/log/syslog
```

### Issue: "Python dependencies missing"

**Solution:**
```bash
# Install all dependencies
pip install -r requirements.txt

# Or install individually
pip install requests configparser

# For Windows auth (optional)
pip install requests-ntlm
```

---

## Platform-Specific Notes

### Windows
- Requires Administrator privileges for scheduler setup
- Use PowerShell 7+ for best compatibility
- Task Scheduler GUI: `taskschd.msc`

### Linux
- Configuration files have 600 permissions
- Output goes to `~/Downloads/` or `~/Documents/`
- Requires cron service running

### macOS
- May use launchd instead of cron
- Python 3 command is `python3` not `python`
- Safari may require user approval for file:// URLs

---

## Testing Report Template

After testing, document your results:

```
Platform: [Windows/Linux/macOS/Distribution]
Version: [OS Version]
Shell: [PowerShell 5.1/7+ / Bash / Zsh / Python 3.x]

Tested Features:
✓ Basic Setup
✓ Authentication (Azure CLI / PAT / Windows)
✓ Work Item Retrieval
✓ Output Methods (Browser / HTML / Text / Console)
✓ Claude AI Integration
✓ Scheduler Setup
✗ [Any failing features]

Issues Found:
- [List any issues]

Notes:
- [Additional observations]
```

---

## Next Steps After Testing

1. **Document Issues**: Create GitHub issues for any bugs found
2. **Update README**: Add platform-specific notes if needed
3. **Performance Testing**: Test with large datasets (100+ work items)
4. **Security Testing**: Verify config files have proper permissions
5. **User Testing**: Have non-technical users try easy-setup.ps1

---

## Automated Testing Script

Create a test runner for automated checks:

**Windows:**
```powershell
# test-all.ps1
Write-Host "Running TFS Analyzer Tests..." -ForegroundColor Cyan

$tests = @(
    @{ Name="Setup"; Command=".\tfs-analyzer.ps1 setup" }
    @{ Name="Auth Test"; Command=".\tfs-analyzer.ps1 test-auth" }
    @{ Name="Analysis"; Command=".\tfs-analyzer.ps1 1 -Console" }
)

foreach ($test in $tests) {
    Write-Host "`nTesting: $($test.Name)" -ForegroundColor Yellow
    try {
        Invoke-Expression $test.Command
        Write-Host "[PASS] $($test.Name)" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] $($test.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}
```

**Linux/Mac:**
```bash
#!/bin/bash
# test-all.sh

echo "Running TFS Analyzer Tests..."

tests=(
    "Setup:./tfs-analyzer.sh setup"
    "Auth Test:./tfs-analyzer.sh test-auth"
    "Analysis:./tfs-analyzer.sh 1 --output console"
)

for test in "${tests[@]}"; do
    name="${test%%:*}"
    command="${test##*:}"
    echo -e "\nTesting: $name"

    if $command; then
        echo "[PASS] $name"
    else
        echo "[FAIL] $name"
    fi
done
```

---

**End of Testing Guide**
