# TFS Tickets - Troubleshooting Guide

This guide covers common issues and their solutions for the TFS Tickets custom command.

---

## Table of Contents

- [Setup Issues](#setup-issues)
- [Authentication Errors](#authentication-errors)
- [Project and Query Errors](#project-and-query-errors)
- [File and Browser Issues](#file-and-browser-issues)
- [Output and Performance](#output-and-performance)
- [Advanced Issues](#advanced-issues)

---

## Setup Issues

### "Configuration not found" error

**Symptom**: When you run `/tfs-tickets`, you get a message saying configuration is not found.

**Solution**: This is expected on first run. Follow these steps:

1. **Set up your PAT token first** (see [PAT token not set](#pat-token-not-set) below)
2. **Run setup command**:
   ```
   /tfs-tickets setup YourProjectName
   ```
3. **Test it works**:
   ```
   /tfs-tickets
   ```

**Example**:
```
/tfs-tickets setup TIP
```

---

### PAT token not set

**Symptom**: Error message: "Environment variable TFS_PERSONAL_TOKEN is not set"

**Solution**: Set the environment variable for your PAT token.

#### Windows (PowerShell):
```powershell
[System.Environment]::SetEnvironmentVariable('TFS_PERSONAL_TOKEN', 'your-52-character-token-here', 'User')
```

#### Mac/Linux (Bash):
```bash
echo 'export TFS_PERSONAL_TOKEN="your-52-character-token-here"' >> ~/.bashrc
source ~/.bashrc
```

#### Mac (Zsh - default on newer macOS):
```bash
echo 'export TFS_PERSONAL_TOKEN="your-52-character-token-here"' >> ~/.zshrc
source ~/.zshrc
```

**Important**: After setting the environment variable, **restart Claude Code** to pick up the new variable.

#### Get a PAT token:
1. Go to https://tfs.deltek.com/tfs/Deltek
2. Click your profile picture (top right)
3. Select **Security** → **Personal Access Tokens**
4. Click **New Token**
5. Name: `Claude TFS Integration`
6. Scopes: Check **"Work Items (Read)"**
7. Click **Create**
8. **Copy the token** (52-character string)

---

### Change default project

**Symptom**: You want to change your default project from TIP to Engineering (or vice versa).

**Solution**: Run the setup command again with the new project name:

```
/tfs-tickets setup Engineering
```

This will overwrite your existing configuration with the new default project.

---

### Config file location

**Question**: Where is my configuration stored?

**Answer**: Configuration is stored at:
- **Windows**: `C:\Users\YourName\.claude\commands\.tfs-tickets-config`
- **Mac/Linux**: `~/.claude/commands/.tfs-tickets-config`

**Manual edit**: You can edit this file directly if needed. Format:
```
DEFAULT_PROJECT=TIP
CONFIGURED_DATE=2025-10-17
VERSION=1.0.0
```

---

## Authentication Errors

### TFS API returns 401 (Unauthorized)

**Symptom**: Error: "TFS API returned 401 Unauthorized"

**Possible Causes**:
1. **PAT token expired** - Tokens expire after a set period
2. **PAT token invalid** - Token was regenerated or deleted
3. **PAT token not loaded** - Claude Code didn't pick up the environment variable
4. **Insufficient permissions** - Token doesn't have "Work Items (Read)" permission

**Solutions**:

#### 1. Regenerate PAT token:
1. Go to https://tfs.deltek.com/tfs/Deltek
2. Profile picture → **Security** → **Personal Access Tokens**
3. Find your existing token, click **Revoke**
4. Create a new token with **Work Items (Read)** permission
5. Copy the new token
6. Update environment variable (see [PAT token not set](#pat-token-not-set))
7. **Restart Claude Code**

#### 2. Verify token is loaded:
**Windows**:
```powershell
echo $env:TFS_PERSONAL_TOKEN
```

**Mac/Linux**:
```bash
echo $TFS_PERSONAL_TOKEN
```

If this shows nothing, the token isn't set properly.

---

### TFS API returns 403 (Forbidden)

**Symptom**: Error: "TFS API returned 403 Forbidden"

**Cause**: PAT token doesn't have required permissions.

**Solution**:
1. Go to https://tfs.deltek.com/tfs/Deltek
2. Profile picture → **Security** → **Personal Access Tokens**
3. Find your token, click **Edit**
4. Ensure **"Work Items (Read)"** scope is checked
5. Save changes
6. If editing isn't possible, create a new token with correct permissions

---

## Project and Query Errors

### TFS API returns 404 (Project not found)

**Symptom**: Error: "TFS API returned 404 Not Found" or "Project 'XYZ' does not exist"

**Cause**: Project name is incorrect or doesn't exist in your TFS instance.

**Solution**: Find the correct project name:

#### Method 1: Check TFS web UI
1. Go to https://tfs.deltek.com/tfs/Deltek
2. Browse to your work items
3. Look at the URL: `/tfs/Deltek/[ProjectName]/_workitems`
4. The `[ProjectName]` is what you need

#### Method 2: Common project names
- `TIP`
- `Engineering`
- `Marketing`
- `Operations`

#### Method 3: Ask your team
Project names are team-specific. Ask a teammate what project name they use.

**Once you have the correct name**:
```
/tfs-tickets setup CorrectProjectName
```

---

### No tickets found

**Symptom**: Report says "0 tickets found" but you know you have assigned tickets.

**Possible Causes**:
1. **Time range too short** - Default is 1 day
2. **Wrong project** - Using different project than where your tickets are
3. **Tickets not assigned** - Tickets are in project but not assigned to you
4. **Tickets too old** - Changed date is older than query period

**Solutions**:

#### 1. Try longer time range:
```
/tfs-tickets 7        # Last 7 days
/tfs-tickets 14       # Last 14 days
/tfs-tickets 30       # Last 30 days
```

#### 2. Try different project:
```
/tfs-tickets Engineering
/tfs-tickets TIP
```

#### 3. Verify in TFS web UI:
1. Go to https://tfs.deltek.com/tfs/Deltek
2. Navigate to **Work** → **Work Items**
3. Filter: **Assigned to me**
4. Check if tickets exist and note their "Changed Date"

#### 4. Check @mentions:
The command also searches for tickets where you're @mentioned. If you have no assigned tickets but are mentioned in discussions, those will still appear.

---

### Query timeout or slow response

**Symptom**: Command takes a very long time or times out.

**Possible Causes**:
1. **Large time range** - Querying 90+ days returns many tickets
2. **Network issues** - Slow connection to TFS server
3. **TFS server load** - Server is busy

**Solutions**:

#### 1. Reduce time range:
```
/tfs-tickets 1        # Just today
/tfs-tickets 3        # Last 3 days
```

#### 2. Check network:
Test connection to TFS:
```bash
ping tfs.deltek.com
```

#### 3. Try again later:
If server is overloaded, wait 15-30 minutes and retry.

---

## File and Browser Issues

### Cannot create output directory

**Symptom**: Error: "Failed to create directory ~/Documents/TFS-Reports"

**Possible Causes**:
1. **Documents folder doesn't exist** (rare)
2. **Permission issues**
3. **Disk full**

**Solutions**:

#### 1. Check Documents folder exists:
**Windows**:
```powershell
Test-Path "$env:USERPROFILE\Documents"
```

**Mac/Linux**:
```bash
ls -ld ~/Documents
```

#### 2. Create manually:
**Windows**:
```powershell
mkdir "$env:USERPROFILE\Documents\TFS-Reports"
```

**Mac/Linux**:
```bash
mkdir -p ~/Documents/TFS-Reports
```

#### 3. Check permissions:
**Windows**: Right-click Documents folder → Properties → Security → Ensure you have Write permission

**Mac/Linux**:
```bash
chmod 755 ~/Documents/TFS-Reports
```

#### 4. Check disk space:
**Windows**:
```powershell
Get-PSDrive C
```

**Mac/Linux**:
```bash
df -h ~
```

---

### Browser doesn't open automatically

**Symptom**: HTML report is created but browser doesn't open.

**Cause**: System `open` (Mac), `xdg-open` (Linux), or `start` (Windows) command not working.

**Solution**: Open manually.

#### Find the file:
Claude will show you the file path in the output, like:
```
✅ HTML report saved: /Users/yourname/Documents/TFS-Reports/TFS-Tickets-TIP-2025-10-17-14-30-45.html
```

#### Open manually:
**Windows Explorer**:
1. Press `Win + E`
2. Navigate to `C:\Users\YourName\Documents\TFS-Reports`
3. Double-click the HTML file

**Mac Finder**:
1. Press `Cmd + Space`, type "Documents"
2. Navigate to `TFS-Reports`
3. Double-click the HTML file

**Linux**:
```bash
xdg-open ~/Documents/TFS-Reports/TFS-Tickets-*.html
```

Or drag the file to your browser.

---

### HTML file is empty or corrupted

**Symptom**: HTML file opens but shows blank page or error.

**Possible Causes**:
1. **Write operation interrupted**
2. **File locked by another process**
3. **Disk full during write**

**Solutions**:

#### 1. Try again:
```
/tfs-tickets
```

#### 2. Check file size:
**Windows**:
```powershell
Get-ChildItem "$env:USERPROFILE\Documents\TFS-Reports\*.html" | Select Name, Length
```

**Mac/Linux**:
```bash
ls -lh ~/Documents/TFS-Reports/*.html
```

If file is 0 bytes or very small (<1KB), it's incomplete.

#### 3. Delete and regenerate:
**Windows**:
```powershell
Remove-Item "$env:USERPROFILE\Documents\TFS-Reports\TFS-Tickets-*.html"
```

**Mac/Linux**:
```bash
rm ~/Documents/TFS-Reports/TFS-Tickets-*.html
```

Then run `/tfs-tickets` again.

---

## Output and Performance

### AI analysis shows as "Traditional" instead of "AI Enhanced"

**Symptom**: Tickets show badge "⚠️ Traditional" instead of "🤖 AI Enhanced"

**Cause**: AI analysis failed or was skipped for those tickets.

**Why this happens**:
- Claude had temporary issues
- Ticket description was too long
- API rate limits

**Is this a problem?**: No, the command falls back to proven traditional priority scoring. Your results are still valid.

**Solution**: If you want AI analysis, try running again:
```
/tfs-tickets
```

Fresh run may succeed with AI analysis.

---

### Command takes a long time

**Symptom**: `/tfs-tickets` takes 2+ minutes to complete.

**Expected Duration**:
- **Few tickets (1-5)**: 15-30 seconds
- **Moderate tickets (10-20)**: 30-60 seconds
- **Many tickets (30+)**: 1-2 minutes

**Factors affecting speed**:
1. **Number of tickets** - More tickets = more API calls
2. **AI analysis** - Adds 2-5 seconds per ticket
3. **Network latency** - Slow connection to TFS
4. **TFS server load** - Busy server responds slower

**Solutions**:

#### 1. Reduce time range:
```
/tfs-tickets 1        # Fewer tickets to process
```

#### 2. Skip AI (faster):
This isn't a built-in option yet, but you can request enhancement to add `--no-ai` flag.

#### 3. Be patient:
For 20+ tickets with AI analysis, 1-2 minutes is normal.

---

### Performance stats show high failure rate

**Symptom**: At bottom of HTML report: "Success Rate: 45%"

**Meaning**: Only 45% of tickets got AI-enhanced analysis, rest used traditional scoring.

**Cause**: Temporary AI service issues.

**Impact**: Results are still valid (traditional scoring is proven), just less detailed.

**Solution**: Try again later when AI service is more responsive:
```
/tfs-tickets
```

---

## Advanced Issues

### curl command not found

**Symptom**: Error: "curl: command not found" or "curl is not recognized"

**Cause**: `curl` is not installed or not in PATH.

**Solutions**:

#### Windows:
Windows 10+ includes curl by default. If missing:

**Option 1 - Reinstall Windows curl**:
```powershell
# Run as Administrator
Add-WindowsCapability -Online -Name curl.Client~~~~0.0.1.0
```

**Option 2 - Install via Chocolatey**:
```powershell
choco install curl
```

#### Mac:
macOS includes curl by default. If missing:
```bash
brew install curl
```

#### Linux (Ubuntu/Debian):
```bash
sudo apt-get update
sudo apt-get install curl
```

#### Linux (RHEL/CentOS):
```bash
sudo yum install curl
```

---

### JSON parsing errors

**Symptom**: Error: "Failed to parse JSON response from TFS API"

**Possible Causes**:
1. **TFS returned HTML error page** instead of JSON
2. **Network proxy injected content**
3. **TFS API version mismatch**

**Solutions**:

#### 1. Test TFS API directly:
**Windows PowerShell**:
```powershell
curl -u ":$env:TFS_PERSONAL_TOKEN" "https://tfs.deltek.com/tfs/Deltek/TIP/_apis/projects/TIP?api-version=6.0"
```

**Mac/Linux**:
```bash
curl -u ":$TFS_PERSONAL_TOKEN" "https://tfs.deltek.com/tfs/Deltek/TIP/_apis/projects/TIP?api-version=6.0"
```

This should return valid JSON starting with `{"id":`. If you see HTML, there's an authentication or connectivity issue.

#### 2. Check proxy settings:
If your organization uses a proxy, you may need to configure curl:
```bash
export http_proxy=http://proxy.yourorg.com:8080
export https_proxy=http://proxy.yourorg.com:8080
```

Ask IT for proxy details.

#### 3. Verify TFS API version:
Try visiting: https://tfs.deltek.com/tfs/Deltek/_apis

This should show supported API versions. The command uses `api-version=6.0`.

---

### "Cannot write to ~/.claude/commands/" error

**Symptom**: Error during setup: "Permission denied" when saving config file

**Cause**: `.claude/commands/` directory doesn't exist or lacks write permission.

**Solutions**:

#### 1. Create directory:
**Windows**:
```powershell
mkdir "$env:USERPROFILE\.claude\commands" -Force
```

**Mac/Linux**:
```bash
mkdir -p ~/.claude/commands
chmod 755 ~/.claude/commands
```

#### 2. Check permissions:
**Mac/Linux**:
```bash
ls -ld ~/.claude/commands
```

Should show `drwxr-xr-x` (755 permissions).

**Windows**: Right-click folder → Properties → Security → Ensure you have Write permission

---

### Multiple PAT tokens / switching accounts

**Question**: Can I use different PAT tokens for different projects?

**Answer**: Not directly. The environment variable `TFS_PERSONAL_TOKEN` is global.

**Workaround**: If you need to use different accounts:

#### Option 1: Update environment variable
```powershell
# Windows - Switch token
[System.Environment]::SetEnvironmentVariable('TFS_PERSONAL_TOKEN', 'new-token-here', 'User')
# Restart Claude Code
```

#### Option 2: Use shell-specific tokens
**Mac/Linux**: Set token for single session:
```bash
export TFS_PERSONAL_TOKEN="temporary-token-here"
# Run Claude in this terminal session
```

#### Option 3: Contact IT
Request enhancement for multi-account support if this is a common need.

---

## Still Having Issues?

### Before contacting support:

1. **Check this guide** - Most issues are covered above
2. **Test authentication**:
   ```bash
   curl -u ":$TFS_PERSONAL_TOKEN" "https://tfs.deltek.com/tfs/Deltek/_apis/projects?api-version=6.0"
   ```
3. **Verify file locations**:
   - Command file: `~/.claude/commands/tfs-tickets.md`
   - Config file: `~/.claude/commands/.tfs-tickets-config`
   - Output: `~/Documents/TFS-Reports/`
4. **Check versions**:
   - Command file header shows version number
   - Claude Code: Help → About

### Contact Support:

**Email**: it-support@yourorg.com

**Subject**: "TFS Tickets Command Issue"

**Include**:
- What you tried to do
- Exact error message
- Your OS (Windows/Mac/Linux)
- Command file version number
- Steps you've already tried

---

## Quick Reference

### Most Common Issues

| Symptom | Quick Fix |
|---------|-----------|
| "Configuration not found" | Run: `/tfs-tickets setup TIP` |
| "PAT token not set" | Set env var, restart Claude Code |
| "Project not found" | Check project name in TFS URL |
| No tickets found | Try: `/tfs-tickets 7` |
| Browser doesn't open | Check output path, open manually |
| Slow performance | Reduce days: `/tfs-tickets 1` |

### Essential Commands

```bash
# Setup
/tfs-tickets setup TIP                    # First-time setup

# Basic usage
/tfs-tickets                              # Default project, 1 day
/tfs-tickets 7                            # Default project, 7 days
/tfs-tickets Engineering                  # Different project, 1 day
/tfs-tickets Engineering 7                # Different project, 7 days

# Change default
/tfs-tickets setup Engineering            # Switch default project
```

### Essential Paths

**Windows**:
- Command: `C:\Users\YourName\.claude\commands\tfs-tickets.md`
- Config: `C:\Users\YourName\.claude\commands\.tfs-tickets-config`
- Reports: `C:\Users\YourName\Documents\TFS-Reports\`

**Mac/Linux**:
- Command: `~/.claude/commands/tfs-tickets.md`
- Config: `~/.claude/commands/.tfs-tickets-config`
- Reports: `~/Documents/TFS-Reports/`

---

**Version**: 1.0.0
**Last Updated**: 2025-10-17
