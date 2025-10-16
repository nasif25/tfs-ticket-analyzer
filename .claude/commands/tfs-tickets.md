# TFS Tickets - AI-Enhanced Ticket Analysis
# Version: 1.0.0
# Last Updated: 2025-10-17

Analyze your TFS tickets with AI-powered priority assessment and beautiful HTML reports.

---

**IMPORTANT EXECUTION INSTRUCTIONS FOR CLAUDE:**

This command fetches and analyzes TFS/Azure DevOps work items using direct REST API calls, performs AI-based priority analysis, generates a beautiful HTML report, and opens it in the user's browser.

## STEP 1: Parse Command Parameters

Parse the user's input after `/tfs-tickets`:

**Parameter Logic**:
- No parameters → Use default project from config, days=1
- `setup ProjectName` → Run setup mode (save default project)
- One parameter (number) → Default project, days={param}
- One parameter (text, not "setup") → project={param}, days=1
- Two parameters → project={param1}, days={param2}

Store parsed values in variables:
- `PROJECT` = project name
- `DAYS` = number of days to look back
- `SETUP_MODE` = true if "setup" command

## STEP 2: Check for First-Run or Setup Mode

**Check if config file exists**: `~/.claude/commands/.tfs-tickets-config`

### If SETUP_MODE is true:

Run the setup wizard:

1. **Validate PAT Token**:
   - Check if environment variable `TFS_PERSONAL_TOKEN` is set
   - If NOT set, show this error and EXIT:

```
❌ PAT Token Not Configured

Before setting your default project, you need to configure your TFS Personal Access Token.

STEP 1: Get Your PAT Token
  1. Go to https://tfs.deltek.com/tfs/Deltek
  2. Click your profile picture (top right)
  3. Select "Security" → "Personal Access Tokens"
  4. Click "New Token"
  5. Name: "Claude TFS Integration"
  6. Scopes: Check "Work Items (Read)"
  7. Click "Create"
  8. Copy the token (52-character string)

STEP 2: Set Environment Variable

  Windows PowerShell:
  [System.Environment]::SetEnvironmentVariable('TFS_PERSONAL_TOKEN', 'paste-your-token-here', 'User')

  Mac/Linux:
  echo 'export TFS_PERSONAL_TOKEN="paste-your-token-here"' >> ~/.bashrc
  source ~/.bashrc

STEP 3: Restart Claude Code (important!)

STEP 4: Try setup again
  /tfs-tickets setup YourProjectName

Need help? The token is a long string starting with numbers, looks like: 52rnl4q...
```

2. **Test TFS Connection**:
   - Use the Bash tool to test connection with provided project name:

```bash
curl -s -u ":$TFS_PERSONAL_TOKEN" \
  "https://tfs.deltek.com/tfs/Deltek/$PROJECT/_apis/projects/$PROJECT?api-version=6.0"
```

   - If successful (HTTP 200), proceed to save config
   - If 404 Not Found:

```
❌ Project "$PROJECT" Not Found

The project "$PROJECT" doesn't exist or you don't have access to it.

Common project names at Deltek:
  - TIP
  - Engineering
  - Marketing
  - Finance

To find your project name:
  1. Go to https://tfs.deltek.com/tfs/Deltek
  2. Look at the URL when viewing your tickets
  3. Format: https://tfs.deltek.com/tfs/Deltek/[ProjectName]/_workitems

Try again with correct project name:
  /tfs-tickets setup CorrectProjectName
```

   - If 401 Unauthorized:

```
❌ Authentication Failed

Your PAT token is invalid or expired.

To fix:
  1. Go to https://tfs.deltek.com/tfs/Deltek
  2. Profile → Security → Personal Access Tokens
  3. Delete the old "Claude TFS Integration" token
  4. Create a new token with "Work Items (Read)" scope
  5. Set the new token:
     Windows: [System.Environment]::SetEnvironmentVariable('TFS_PERSONAL_TOKEN', 'new-token-here', 'User')
     Mac/Linux: export TFS_PERSONAL_TOKEN="new-token-here"
  6. Restart Claude Code
  7. Try again: /tfs-tickets setup $PROJECT
```

3. **Save Configuration**:
   - Use the Write tool to create `~/.claude/commands/.tfs-tickets-config` with content:

```
DEFAULT_PROJECT=$PROJECT
CONFIGURED_DATE=$(date +%Y-%m-%d)
VERSION=1.0.0
```

   - Show success message:

```
✅ Configuration Saved!

  Default Project: $PROJECT
  PAT Token: ✓ Configured

Ready to use! Try:
  /tfs-tickets              → Analyze your $PROJECT tickets
  /tfs-tickets 7            → Last 7 days
  /tfs-tickets OtherProject → Use different project

To change your default project later:
  /tfs-tickets setup NewProjectName
```

   - EXIT (don't proceed to analysis)

### If config file does NOT exist and NOT setup mode:

Show welcome message and setup instructions:

```
🎫 Welcome to TFS Tickets!

This is your first time using this command. Let's get you set up! (2 minutes)

═══════════════════════════════════════════════════════════

STEP 1: Configure Your PAT Token

You need a TFS Personal Access Token for authentication.

Get your PAT token:
  1. Go to https://tfs.deltek.com/tfs/Deltek
  2. Click your profile picture (top right)
  3. Security → Personal Access Tokens
  4. Click "New Token"
  5. Name: "Claude TFS Integration"
  6. Scopes: Check "Work Items (Read)"
  7. Click "Create" and copy the token

Set your PAT token:

  Windows PowerShell:
  [System.Environment]::SetEnvironmentVariable('TFS_PERSONAL_TOKEN', 'your-token-here', 'User')

  Mac/Linux:
  echo 'export TFS_PERSONAL_TOKEN="your-token-here"' >> ~/.bashrc
  source ~/.bashrc

═══════════════════════════════════════════════════════════

STEP 2: Restart Claude Code

Important! Claude needs to restart to pick up the new environment variable.
  • Close and reopen Claude Code

═══════════════════════════════════════════════════════════

STEP 3: Set Your Default Project

After restarting, run:
  /tfs-tickets setup YourProjectName

Common project names: TIP, Engineering, Marketing, Finance

═══════════════════════════════════════════════════════════

Need help? Contact: it-support@yourorg.com
```

EXIT (don't proceed to analysis)

### If config file EXISTS:

- Use the Read tool to read `~/.claude/commands/.tfs-tickets-config`
- Parse `DEFAULT_PROJECT` from the file
- If PROJECT was not specified by user, use DEFAULT_PROJECT
- Continue to STEP 3

## STEP 3: Validate PAT Token

Check if environment variable `TFS_PERSONAL_TOKEN` is set:

```bash
echo $TFS_PERSONAL_TOKEN
```

If empty or undefined, show error:

```
❌ PAT Token Not Set

Your TFS Personal Access Token is not configured.

To fix:
  Windows: [System.Environment]::SetEnvironmentVariable('TFS_PERSONAL_TOKEN', 'your-token', 'User')
  Mac/Linux: export TFS_PERSONAL_TOKEN="your-token"

Don't have a token? Get one:
  1. Go to https://tfs.deltek.com/tfs/Deltek
  2. Profile → Security → Personal Access Tokens
  3. Create new token with "Work Items (Read)" scope

After setting the token:
  • Restart Claude Code
  • Try again: /tfs-tickets
```

EXIT if PAT token not set.

## STEP 4: Fetch Tickets from TFS via REST API

Show progress message:
```
🎫 Fetching TFS tickets from project "$PROJECT"...
   Period: Last $DAYS day(s)
```

### Query 1: Get Assigned Work Items

Use Bash tool to call TFS REST API WIQL (Work Item Query Language):

```bash
curl -s -u ":$TFS_PERSONAL_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  "https://tfs.deltek.com/tfs/Deltek/$PROJECT/_apis/wit/wiql?api-version=6.0" \
  -d '{
    "query": "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = '\''$PROJECT'\'' AND [System.AssignedTo] = @Me AND [System.ChangedDate] >= @Today - $DAYS ORDER BY [System.ChangedDate] DESC"
  }'
```

Parse the JSON response to extract work item IDs from `workItems[].id`.

Store these IDs in a list: `ASSIGNED_IDS`

### Query 2: Get @Mentioned Work Items

```bash
curl -s -u ":$TFS_PERSONAL_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  "https://tfs.deltek.com/tfs/Deltek/$PROJECT/_apis/wit/wiql?api-version=6.0" \
  -d '{
    "query": "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = '\''$PROJECT'\'' AND [System.History] Contains '\''@'\'' AND [System.ChangedDate] >= @Today - $DAYS"
  }'
```

Parse the JSON response to extract work item IDs.

Store these IDs in a list: `MENTIONED_IDs`

### Merge and Deduplicate IDs

Combine `ASSIGNED_IDS` and `MENTIONED_IDS`, remove duplicates.

Store final list: `ALL_TICKET_IDS`

If `ALL_TICKET_IDS` is empty:

```
📭 No Tickets Found

No work items found in project "$PROJECT" for the last $DAYS day(s).

Suggestions:
  • Try more days: /tfs-tickets $PROJECT 7
  • Check different project: /tfs-tickets OtherProject
  • Verify you have tickets assigned in TFS

To see your projects, visit: https://tfs.deltek.com/tfs/Deltek
```

EXIT if no tickets.

### Query 3: Get Full Work Item Details

For each ID in `ALL_TICKET_IDS`, fetch full details:

```bash
curl -s -u ":$TFS_PERSONAL_TOKEN" \
  "https://tfs.deltek.com/tfs/Deltek/$PROJECT/_apis/wit/workitems/$ID?`$expand=all&api-version=6.0"
```

Store each work item's data including:
- `id`
- `fields["System.Title"]`
- `fields["System.State"]`
- `fields["System.WorkItemType"]`
- `fields["System.AssignedTo"].displayName`
- `fields["System.ChangedDate"]`
- `fields["System.Description"]`
- `fields["System.Tags"]`
- `fields["Microsoft.VSTS.Common.Priority"]`
- `fields["Microsoft.VSTS.Common.Severity"]`

Determine if ticket was assigned, @mentioned, or both:
- If ID was in `ASSIGNED_IDS` only → `source = "Assigned"`
- If ID was in `MENTIONED_IDS` only → `source = "@Mentioned"`
- If ID was in both → `source = "Assigned & @Mentioned"`

Show progress:
```
   Found $COUNT tickets. Analyzing with AI...
```

## STEP 5: AI Priority Analysis for Each Ticket

For each work item, perform priority scoring:

### Priority Scoring Algorithm

Calculate numeric score based on these factors:

**State Analysis**:
- "In Progress" or "Active" → +30 points, reason: "Currently in progress"
- "New" or "Committed" → +20 points, reason: "New or committed work"
- "Done", "Closed", "Resolved" → -20 points, reason: "Already completed"

**Work Item Type Analysis**:
- "Bug" → +25 points, reason: "Bug type (higher priority)"
- "Task", "Product Backlog Item", "User Story" → +15 points, reason: "Active work item"
- "Epic", "Feature" → +5 points, reason: "Large planning item"

**Title/Description Keyword Analysis** (case-insensitive):
- Contains: "showstopper", "critical", "urgent", "blocker", "blocking" → +40 points, reason: "Contains critical keywords"
- Contains: "error", "broken", "crash", "failure", "failed", "not working" → +25 points, reason: "Indicates system issues"
- Contains: "performance", "slow", "timeout", "hang" → +15 points, reason: "Performance issue"

**Priority Field Analysis**:
- Priority = 1 → +30 points, reason: "Priority 1 (highest)"
- Priority = 2 → +20 points, reason: "Priority 2 (high)"
- Priority = 3 → +10 points, reason: "Priority 3 (medium)"

**Severity Analysis**:
- Severity = "1 - Critical" or "1" → +35 points, reason: "Critical severity"
- Severity = "2 - High" or "2" → +25 points, reason: "High severity"
- Severity = "3 - Medium" or "3" → +15 points, reason: "Medium severity"

**Determine Priority Level**:
- Total score >= 60 → Priority = "HIGH"
- Total score 30-59 → Priority = "MEDIUM"
- Total score < 30 → Priority = "LOW"

### AI Content Analysis

For each ticket, use your AI capabilities to analyze and generate:

1. **One-Sentence Summary** (max 100 chars):
   - Concise description of what the ticket is about
   - Example: "Payment processing fails for credit card transactions over $1000"

2. **Key Points** (2-3 bullets):
   - Important details from title/description
   - Technical requirements or constraints
   - Business impact if mentioned
   - Example: "Affects 15% of transactions", "Customer-reported issue", "Blocking Q4 release"

3. **Recommended Actions** (1-2 actions):
   - What should be done next
   - Based on state and type
   - Example: "Investigate payment gateway logs", "Coordinate with DevOps team"

Store analysis for each ticket:
- `priorityLevel`: "HIGH" | "MEDIUM" | "LOW"
- `priorityScore`: numeric score
- `priorityReasons`: array of reason strings
- `summary`: one-sentence summary
- `keyPoints`: array of 2-3 key points
- `actions`: array of 1-2 recommended actions

## STEP 6: Generate HTML Report

Use the Write tool to create HTML file at:
`~/Documents/TFS-Reports/TFS-Tickets-$PROJECT-$(date +%Y-%m-%d-%H-%M-%S).html`

First, create the directory if it doesn't exist:
```bash
mkdir -p ~/Documents/TFS-Reports
```

### HTML Structure

Generate complete HTML document with this structure:

```html
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>TFS Ticket Summary - $PROJECT</title>
<style>
body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
.container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
.header { text-align: center; margin-bottom: 30px; padding-bottom: 20px; border-bottom: 3px solid #0066cc; }
.header h1 { color: #0066cc; margin: 0 0 10px 0; }
.header .subtitle { color: #666; font-size: 14px; }
.summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 30px; }
.summary-card { padding: 20px; border-radius: 8px; text-align: center; color: white; font-weight: bold; font-size: 18px; }
.summary-high { background: linear-gradient(135deg, #ff6b6b 0%, #ee5a52 100%); }
.summary-medium { background: linear-gradient(135deg, #feca57 0%, #ff9f43 100%); }
.summary-low { background: linear-gradient(135deg, #48dbfb 0%, #0abde3 100%); }
.ticket { margin: 15px 0; padding: 20px; border-radius: 8px; border-left: 5px solid #ccc; background: #fafafa; }
.ticket-high { border-left-color: #ff6b6b; background: #fff5f5; }
.ticket-medium { border-left-color: #feca57; background: #fffbf0; }
.ticket-low { border-left-color: #48dbfb; background: #f0fbff; }
.ticket-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 15px; }
.ticket-id { font-size: 20px; font-weight: bold; color: #0066cc; margin: 0; }
.ticket-id a { color: #0066cc; text-decoration: none; }
.ticket-id a:hover { text-decoration: underline; }
.ticket-meta { display: flex; gap: 10px; align-items: center; }
.ticket-source { padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
.source-assigned { background: #28a745; color: white; }
.source-mentioned { background: #ffc107; color: #212529; }
.source-both { background: #17a2b8; color: white; }
.ticket-title { font-size: 16px; font-weight: bold; margin: 10px 0; color: #333; }
.ticket-details { margin: 8px 0; color: #666; font-size: 14px; }
.ticket-tags { margin: 10px 0; }
.tag { background: #e1e8ed; color: #14171a; padding: 2px 8px; border-radius: 12px; font-size: 12px; margin-right: 5px; display: inline-block; }
.content-analysis { background: #f8f9fa; border: 1px solid #dee2e6; border-radius: 5px; padding: 12px; margin: 15px 0; }
.analysis-title { font-weight: bold; color: #495057; margin-bottom: 8px; font-size: 14px; }
.analysis-summary { background: #e7f3ff; padding: 8px; border-radius: 3px; margin: 5px 0; font-size: 13px; }
.analysis-section { margin: 8px 0; }
.analysis-item { background: #f1f3f4; padding: 4px 8px; margin: 2px 0; border-radius: 3px; font-size: 12px; }
.next-step-item { background: #d4edda; border-left: 3px solid #c3e6cb; }
.action-box { background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; padding: 12px; margin: 15px 0; }
.action-title { font-weight: bold; color: #856404; margin-bottom: 5px; }
.reasons { font-style: italic; color: #666; font-size: 14px; margin: 10px 0; }
.footer { text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #dee2e6; color: #888; font-size: 12px; }
</style>
</head>
<body>
<div class="container">

<!-- Header -->
<div class="header">
  <h1>TFS Daily Ticket Summary</h1>
  <div class="subtitle">Project: $PROJECT | Period: Last $DAYS day(s) | Generated: $(date '+%Y-%m-%d %H:%M:%S')</div>
</div>

<!-- Summary Cards -->
<div class="summary">
  <div class="summary-card summary-high">
    <div>High Priority</div>
    <div style="font-size: 32px; margin-top: 10px;">$HIGH_COUNT</div>
  </div>
  <div class="summary-card summary-medium">
    <div>Medium Priority</div>
    <div style="font-size: 32px; margin-top: 10px;">$MEDIUM_COUNT</div>
  </div>
  <div class="summary-card summary-low">
    <div>Low Priority</div>
    <div style="font-size: 32px; margin-top: 10px;">$LOW_COUNT</div>
  </div>
</div>

<!-- High Priority Tickets -->
<h2 style="color: #ff6b6b;">High Priority Tickets ($HIGH_COUNT)</h2>
[For each HIGH priority ticket, generate:]

<div class="ticket ticket-high">
  <div class="ticket-header">
    <div class="ticket-id">
      <a href="https://tfs.deltek.com/tfs/Deltek/$PROJECT/_workitems/edit/$TICKET_ID" target="_blank">Ticket #$TICKET_ID</a>
    </div>
    <div class="ticket-meta">
      <div class="ticket-source source-$SOURCE_CLASS">$SOURCE</div>
    </div>
  </div>

  <div class="ticket-title">$TITLE</div>

  <div class="ticket-details"><strong>Type:</strong> $TYPE</div>
  <div class="ticket-details"><strong>State:</strong> $STATE</div>
  <div class="ticket-details"><strong>Assigned:</strong> $ASSIGNED_TO</div>
  <div class="ticket-details"><strong>Last Updated:</strong> $CHANGED_DATE</div>

  [If tags exist:]
  <div class="ticket-tags">
    <strong>Tags:</strong> <span class="tag">$TAG1</span> <span class="tag">$TAG2</span>
  </div>

  <!-- AI Analysis -->
  <div class="content-analysis">
    <div class="analysis-title">AI Analysis</div>
    <div class="analysis-summary"><strong>Summary:</strong> $AI_SUMMARY</div>

    <div class="analysis-section">
      <strong style="font-size: 13px;">Key Points:</strong>
      [For each key point:]
      <div class="analysis-item">$KEY_POINT</div>
    </div>

    <div class="analysis-section">
      <strong style="font-size: 13px;">Action Items:</strong>
      [For each action:]
      <div class="analysis-item next-step-item">$ACTION</div>
    </div>
  </div>

  <!-- Priority Reasons -->
  <div class="reasons"><strong>Priority Reasons:</strong> $REASONS_JOINED</div>
</div>

[Repeat for all HIGH priority tickets]

<!-- Medium Priority Tickets -->
<h2 style="color: #feca57;">Medium Priority Tickets ($MEDIUM_COUNT)</h2>
[Same structure as HIGH, but with class="ticket ticket-medium"]

<!-- Low Priority Tickets -->
<h2 style="color: #48dbfb;">Low Priority Tickets ($LOW_COUNT)</h2>
[Same structure as HIGH, but with class="ticket ticket-low"]

<!-- Footer -->
<div class="footer">
  Generated by TFS Tickets Command v1.0.0 |
  <a href="https://tfs.deltek.com/tfs/Deltek/$PROJECT" target="_blank">View Project in TFS</a>
</div>

</div>
</body>
</html>
```

### HTML Generation Notes:

- Group tickets by priority level (HIGH, MEDIUM, LOW)
- Sort within each group by priority score (descending)
- For `$SOURCE_CLASS`: convert source to lowercase CSS class
  - "Assigned" → "assigned"
  - "@Mentioned" → "mentioned"
  - "Assigned & @Mentioned" → "both"
- Escape HTML special characters in ticket content
- Format dates nicely (YYYY-MM-DD HH:MM)
- Join priority reasons with commas

## STEP 7: Open HTML in Browser

After writing the HTML file, open it in the user's default browser:

```bash
# Get the full file path that was just created
HTML_FILE="$HOME/Documents/TFS-Reports/TFS-Tickets-$PROJECT-$(date +%Y-%m-%d-%H-%M-%S).html"

# Open in default browser (cross-platform)
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
  # Windows
  start "" "$HTML_FILE"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  open "$HTML_FILE"
else
  # Linux
  xdg-open "$HTML_FILE" 2>/dev/null || echo "Please open manually: $HTML_FILE"
fi
```

## STEP 8: Show Terminal Summary

Print summary to terminal:

```
✅ TFS Ticket Analysis Complete!

Project: $PROJECT
Period: Last $DAYS day(s)
Total Tickets: $TOTAL_COUNT

Priority Breakdown:
  🔴 High Priority: $HIGH_COUNT ticket(s)
  🟡 Medium Priority: $MEDIUM_COUNT ticket(s)
  🔵 Low Priority: $LOW_COUNT ticket(s)

[If HIGH_COUNT > 0:]
Top Priority Items:
  • #$ID1: $TITLE1
  • #$ID2: $TITLE2
  • #$ID3: $TITLE3

✅ Opening detailed HTML report in your browser...

Report Location:
  ~/Documents/TFS-Reports/TFS-Tickets-$PROJECT-$TIMESTAMP.html

═══════════════════════════════════════════════════════════

Tips:
  • Run again: /tfs-tickets
  • Different project: /tfs-tickets ProjectName
  • More days: /tfs-tickets 7
  • Change default: /tfs-tickets setup NewProject
```

## ERROR HANDLING

### Error: curl command not found
```
❌ System Error: curl not available

This command requires curl for TFS API calls.

Windows: curl is built-in on Windows 10+
Mac/Linux: Install with: sudo apt install curl (Ubuntu) or brew install curl (Mac)

Contact IT if you need help: it-support@yourorg.com
```

### Error: TFS API returns 401
```
❌ Authentication Failed

Your PAT token is invalid or expired.

To fix:
  1. Generate new token: https://tfs.deltek.com/tfs/Deltek
  2. Profile → Security → Personal Access Tokens
  3. Create token with "Work Items (Read)" scope
  4. Update environment variable with new token
  5. Restart Claude Code

Current token check: Run `echo $TFS_PERSONAL_TOKEN` to see if it's set.
```

### Error: TFS API returns 404
```
❌ Project "$PROJECT" Not Found

The project doesn't exist or you don't have access.

To find your project name:
  1. Go to https://tfs.deltek.com/tfs/Deltek
  2. Browse your work items
  3. Check the URL: /tfs/Deltek/[ProjectName]/_workitems

Common projects: TIP, Engineering, Marketing

Try again: /tfs-tickets CorrectProjectName
```

### Error: Cannot create output directory
```
❌ Cannot Create Output Directory

Failed to create ~/Documents/TFS-Reports/

To fix:
  • Check permissions on ~/Documents folder
  • Try alternate location:
    mkdir -p ~/Downloads/TFS-Reports

Then report the HTML file location to save manually.
```

---

**END OF EXECUTION INSTRUCTIONS**

This command should execute all steps sequentially, handling errors gracefully and providing clear feedback to the user at each stage.
