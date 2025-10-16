# TFS Tickets - Custom Claude Command

**One-file solution for AI-enhanced TFS ticket analysis**

Version: 1.0.0 | For Deltek on-premise TFS

---

## What Is This?

A custom Claude command that fetches your TFS tickets, analyzes them with AI for priority and insights, generates a beautiful HTML report, and opens it in your browser automatically.

**No scripts, no dependencies, just one markdown file.**

## Features

✅ **Multi-Project Support** - Works with any TFS project (TIP, Engineering, etc.)
✅ **AI Priority Analysis** - Smart prioritization based on state, type, keywords, severity
✅ **Beautiful HTML Reports** - Gradient cards, color-coded priorities, clickable links
✅ **First-Run Setup Wizard** - Interactive configuration on first use
✅ **Self-Diagnosing** - Clear error messages with step-by-step fixes
✅ **Personalized Defaults** - Each user sets their own default project

---

## Installation (30 seconds)

### Step 1: Copy Command File

**From file share**:
```bash
# Windows
copy \\shared-drive\claude-commands\tfs-tickets.md %USERPROFILE%\.claude\commands\

# Mac/Linux
cp /mnt/shared-drive/claude-commands/tfs-tickets.md ~/.claude/commands/
```

**Or copy manually**:
- Copy `tfs-tickets.md` to your `.claude/commands/` folder
- Location:
  - Windows: `C:\Users\YourName\.claude\commands\`
  - Mac/Linux: `~/.claude/commands/`

That's it! You're ready to use it.

---

## First-Time Setup (2 minutes)

The first time you run `/tfs-tickets`, it will guide you through setup:

### Step 1: Get PAT Token

1. Go to https://tfs.deltek.com/tfs/Deltek
2. Click your profile picture (top right)
3. Select **Security** → **Personal Access Tokens**
4. Click **New Token**
5. Name: `Claude TFS Integration`
6. Scopes: Check **"Work Items (Read)"**
7. Click **Create**
8. **Copy the token** (52-character string)

### Step 2: Set Environment Variable

**Windows PowerShell**:
```powershell
[System.Environment]::SetEnvironmentVariable('TFS_PERSONAL_TOKEN', 'paste-your-token-here', 'User')
```

**Mac/Linux**:
```bash
echo 'export TFS_PERSONAL_TOKEN="paste-your-token-here"' >> ~/.bashrc
source ~/.bashrc
```

### Step 3: Restart Claude Code

**Important!** Close and reopen Claude Code to pick up the new environment variable.

### Step 4: Set Your Default Project

In Claude, run:
```
/tfs-tickets setup YourProjectName
```

Examples:
- `/tfs-tickets setup TIP`
- `/tfs-tickets setup Engineering`
- `/tfs-tickets setup Marketing`

**Don't know your project name?**
- Go to https://tfs.deltek.com/tfs/Deltek
- Browse your work items
- Check the URL: `/tfs/Deltek/[ProjectName]/_workitems`

---

## Usage

### Basic Commands

```bash
/tfs-tickets                    # Your default project, last 1 day
/tfs-tickets 7                  # Your default project, last 7 days
/tfs-tickets Engineering        # Different project, last 1 day
/tfs-tickets Engineering 7      # Different project, last 7 days
```

### Setup Commands

```bash
/tfs-tickets setup TIP          # Set TIP as your default project
/tfs-tickets setup Engineering  # Change default to Engineering
```

### Examples

**Scenario 1: Daily standup prep**
```
You: /tfs-tickets

Claude: [Fetches your tickets, analyzes, generates HTML, opens browser]
```

**Scenario 2: Check another project**
```
You: /tfs-tickets Marketing

Claude: [Fetches Marketing project tickets]
```

**Scenario 3: Weekly review**
```
You: /tfs-tickets 7

Claude: [Fetches last 7 days of your default project]
```

**Scenario 4: Change your default**
```
You: /tfs-tickets setup Engineering

Claude: ✅ Configuration saved! Default project is now Engineering.
```

---

## What You Get

### HTML Report

Reports are saved to: `~/Documents/TFS-Reports/TFS-Tickets-{PROJECT}-{TIMESTAMP}.html`

**Features**:
- **Summary Cards**: Visual breakdown of High/Medium/Low priority counts
- **Priority Grouping**: Tickets organized by priority level with color coding
- **AI Analysis**: Each ticket includes:
  - One-sentence summary
  - Key points extracted from description
  - Recommended actions
  - Priority reasoning
- **Clickable Links**: Direct links to TFS work items
- **Tags**: Visual tag badges for easy scanning
- **Source Indicators**: Shows if assigned, @mentioned, or both
- **Timestamps**: When the report was generated

### Terminal Output

You'll also see a summary in Claude:
```
✅ TFS Ticket Analysis Complete!

Project: TIP
Period: Last 1 day(s)
Total Tickets: 12

Priority Breakdown:
  🔴 High Priority: 3 ticket(s)
  🟡 Medium Priority: 5 ticket(s)
  🔵 Low Priority: 4 ticket(s)

Top Priority Items:
  • #456789: Critical bug in payment processing
  • #456790: Production deployment blocked
  • #456791: Customer-reported data loss

✅ Opening detailed HTML report in your browser...
```

---

## How It Works

### Behind the Scenes

1. **Configuration Check**: Reads your default project from `~/.claude/commands/.tfs-tickets-config`
2. **PAT Authentication**: Uses your `TFS_PERSONAL_TOKEN` environment variable
3. **TFS API Calls**:
   - Query 1: Fetch assigned work items
   - Query 2: Fetch @mentioned work items
   - Query 3: Get full details for each ticket
4. **AI Analysis**: Analyzes each ticket for priority and insights
5. **HTML Generation**: Creates beautiful report with embedded CSS
6. **Browser Opening**: Opens report automatically in your default browser

### Priority Scoring

Tickets are scored based on:
- **State**: In Progress (high), New (medium), Done (low)
- **Type**: Bug (high), Task/PBI (medium), Epic (low)
- **Keywords**: CRITICAL, ERROR, BROKEN, SLOW, etc.
- **Priority Field**: 1 (high), 2-3 (medium), 4+ (low)
- **Severity**: 1-Critical (high), 2-High (medium), 3-Medium (medium)

**Final Priority**:
- Score ≥ 60 → **HIGH** (red)
- Score 30-59 → **MEDIUM** (yellow)
- Score < 30 → **LOW** (blue)

---

## Multi-Project Workflows

### Multiple Projects, One User

If you work across multiple projects:

**Set your primary project as default**:
```
/tfs-tickets setup TIP          # TIP is your primary
```

**Use specific project when needed**:
```
/tfs-tickets                    # Uses TIP (default)
/tfs-tickets Engineering        # Temporarily uses Engineering
/tfs-tickets Marketing          # Temporarily uses Marketing
/tfs-tickets                    # Back to TIP (default)
```

**Change your default anytime**:
```
/tfs-tickets setup Engineering  # Now Engineering is default
/tfs-tickets                    # Uses Engineering
```

---

## Tips & Tricks

### 1. Morning Standup

Quick command to see what you're working on:
```
/tfs-tickets
```

### 2. Weekly Planning

See the whole week:
```
/tfs-tickets 7
```

### 3. Cross-Team Collaboration

Check another team's project:
```
/tfs-tickets TheirProject 7
```

### 4. After Vacation

Catch up on everything:
```
/tfs-tickets 14
```

### 5. Reports for Sharing

The HTML files are standalone - you can email them or share via Slack/Teams without losing formatting.

---

## System Requirements

- **Claude Code**: Installed and configured
- **TFS Access**: Valid PAT token with "Work Items (Read)" permission
- **OS**: Windows 10+, macOS 10.14+, or Linux with curl
- **Browser**: Any modern browser (Chrome, Edge, Firefox, Safari)

---

## Security

### PAT Token Storage

Your PAT token is stored as an environment variable (`TFS_PERSONAL_TOKEN`):
- **Windows**: Stored in Windows Registry (encrypted at rest)
- **Mac/Linux**: Stored in shell profile (~/.bashrc)

**Best practices**:
- Never share your PAT token
- Regenerate tokens every 90 days
- Use minimum permissions (Work Items: Read only)
- Never commit tokens to git

### HTML Reports

Reports are saved locally to `~/Documents/TFS-Reports/`:
- Not uploaded to any server
- Not shared automatically
- You control who sees them
- Can be deleted anytime

---

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

Quick fixes:

**"PAT token not set"**
- Set environment variable (see First-Time Setup)
- Restart Claude Code

**"Project not found"**
- Check project name at https://tfs.deltek.com/tfs/Deltek
- Update: `/tfs-tickets setup CorrectProjectName`

**"No tickets found"**
- Try more days: `/tfs-tickets 7`
- Verify you have assigned tickets in TFS

**Browser doesn't open**
- Check report location in terminal output
- Open manually: `~/Documents/TFS-Reports/`

---

## Updating the Command

When a new version is released:

1. **Copy new version** from file share:
   ```bash
   copy \\shared-drive\claude-commands\tfs-tickets.md %USERPROFILE%\.claude\commands\
   ```

2. **Overwrite when prompted**: Yes

3. **Your configuration is preserved**: The config file (`.tfs-tickets-config`) is separate and won't be overwritten

4. **Check version**: The first lines of `tfs-tickets.md` show the version number

---

## Support

### Help Resources

- **Troubleshooting Guide**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **IT Support**: it-support@yourorg.com
- **Internal Wiki**: [TFS Tickets Command Documentation]

### Common Questions

**Q: Can I use this for multiple TFS organizations?**
A: Currently designed for Deltek TFS only. Contact IT if you need multi-org support.

**Q: How often can I run this?**
A: As often as you want! No rate limits on our end. TFS API has rate limits but they're very generous.

**Q: Can I customize the HTML?**
A: The HTML template is embedded in the command. Advanced users can edit `tfs-tickets.md` directly.

**Q: Does this work offline?**
A: No, requires network access to TFS server (tfs.deltek.com).

**Q: Can I share reports with teammates?**
A: Yes! The HTML files are self-contained and can be emailed or shared via Slack/Teams.

---

## What's Next?

### Planned Features (v1.1)

- Team-level reports (all tickets for a team)
- Export to PDF
- Ticket status updates via command
- Sprint/iteration filtering
- Custom HTML themes

### Feedback

Have suggestions? Email: it-support@yourorg.com with subject "TFS Tickets Command Feedback"

---

## Credits

- **Original TFS Analyzer**: tfs-analyzer.ps1 (PowerShell version)
- **HTML/CSS**: Ported from existing analyzer
- **Priority Algorithm**: Based on proven scoring logic
- **Built for**: Deltek teams by Deltek teams

---

**Version**: 1.0.0
**Last Updated**: 2025-10-17
**Maintained by**: IT Support Team
