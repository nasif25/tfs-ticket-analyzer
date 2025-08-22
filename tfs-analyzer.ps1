# TFS Ticket Analyzer with Multiple Output Options
# No SMTP server required - choose from multiple delivery methods

param(
    [Parameter(Position = 0)]
    [string]$Action = "analyze",
    [Parameter(Position = 1)]
    [int]$Days = 1,
    [switch]$SaveHtml = $false,
    [switch]$SendEmail = $false,
    [switch]$ShowInBrowser = $false,
    [switch]$SaveText = $false
)

$ConfigFile = "$env:USERPROFILE\.tfs-analyzer-config"

# Colors for output
$Colors = @{
    Info    = "Cyan"
    Success = "Green" 
    Warning = "Yellow"
    Error   = "Red"
}

function Write-ColorOutput {
    param([string]$Message, [string]$Color)
    Write-Host "[$($Color.ToUpper())] $Message" -ForegroundColor $Colors[$Color]
}

function Setup-OutputConfiguration {
    Write-ColorOutput "Setting up output preferences..." "Info"
    Write-Host "Choose your preferred daily summary delivery method:"
    Write-Host ""
    Write-Host "1. HTML file (saved to Documents, can open in browser)"
    Write-Host "2. Email via Office 365 (requires your Outlook credentials)"  
    Write-Host "3. Both HTML file AND email"
    Write-Host "4. Text file (simple text format)"
    Write-Host "5. Show in browser automatically"
    
    $Choice = Read-Host "Enter your choice (1-5)"
    
    $OutputConfig = ""
    
    switch ($Choice) {
        "1" {
            $OutputConfig = "OUTPUT_METHOD=HTML`nHTML_PATH=$env:USERPROFILE\Documents\TFS-Daily-Summary.html"
        }
        "2" {
            Write-Host ""
            Write-ColorOutput "Office 365 Email Setup:" "Info"
            $EmailAddress = Read-Host "Enter your Deltek email address"
            $EmailPassword = Read-Host "Enter your email password" -AsSecureString
            $EmailPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($EmailPassword))
            
            $OutputConfig = "OUTPUT_METHOD=EMAIL`nSMTP_SERVER=smtp.office365.com`nSMTP_PORT=587`nFROM_EMAIL=$EmailAddress`nTO_EMAIL=$EmailAddress`nSMTP_USER=$EmailAddress`nSMTP_PASS=$EmailPass"
        }
        "3" {
            Write-Host ""
            Write-ColorOutput "Office 365 Email Setup:" "Info"
            $EmailAddress = Read-Host "Enter your Deltek email address"
            $EmailPassword = Read-Host "Enter your email password" -AsSecureString
            $EmailPass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($EmailPassword))
            
            $OutputConfig = "OUTPUT_METHOD=BOTH`nHTML_PATH=$env:USERPROFILE\Documents\TFS-Daily-Summary.html`nSMTP_SERVER=smtp.office365.com`nSMTP_PORT=587`nFROM_EMAIL=$EmailAddress`nTO_EMAIL=$EmailAddress`nSMTP_USER=$EmailAddress`nSMTP_PASS=$EmailPass"
        }
        "4" {
            $OutputConfig = "OUTPUT_METHOD=TEXT`nTEXT_PATH=$env:USERPROFILE\Documents\TFS-Daily-Summary.txt"
        }
        "5" {
            $OutputConfig = "OUTPUT_METHOD=BROWSER`nHTML_PATH=$env:USERPROFILE\Documents\TFS-Daily-Summary.html`nOPEN_BROWSER=True"
        }
        default {
            Write-ColorOutput "Invalid choice. Defaulting to HTML file output." "Warning"
            $OutputConfig = "OUTPUT_METHOD=HTML`nHTML_PATH=$env:USERPROFILE\Documents\TFS-Daily-Summary.html"
        }
    }
    
    # Add to existing config or create new
    $ExistingConfig = ""
    if (Test-Path $ConfigFile) {
        $ExistingConfig = Get-Content $ConfigFile -Raw
    }
    
    $FinalConfig = if ($ExistingConfig) { "$ExistingConfig`n$OutputConfig" } else { $OutputConfig }
    $FinalConfig | Out-File -FilePath $ConfigFile -Encoding UTF8
    
    Write-ColorOutput "Output configuration saved!" "Success"
    Write-Host "Your daily summaries will be delivered as configured."
}

function Save-HtmlSummary {
    param([hashtable]$Config, [array]$AllTickets, [int]$Days, [string]$TfsUrl, [string]$ProjectName)
    
    $HtmlPath = if ($Config.HTML_PATH) { $Config.HTML_PATH } else { "$env:USERPROFILE\Documents\TFS-Daily-Summary.html" }
    
    Write-ColorOutput "Generating HTML summary..." "Info"
    
    # Group tickets by priority
    $HighPriority = @($AllTickets | Where-Object { $_.Priority.Level -eq 'HIGH' })
    $MediumPriority = @($AllTickets | Where-Object { $_.Priority.Level -eq 'MEDIUM' })
    $LowPriority = @($AllTickets | Where-Object { $_.Priority.Level -eq 'LOW' })
    
    # Build HTML content using array and join to avoid parsing issues
    $HtmlLines = @()
    $HtmlLines += '<!DOCTYPE html>'
    $HtmlLines += '<html>'
    $HtmlLines += '<head>'
    $HtmlLines += '<meta charset="UTF-8">'
    $HtmlLines += '<title>TFS Daily Ticket Summary</title>'
    $HtmlLines += '<style>'
    $HtmlLines += 'body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }'
    $HtmlLines += '.container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }'
    $HtmlLines += '.header { text-align: center; margin-bottom: 30px; padding-bottom: 20px; border-bottom: 3px solid #0066cc; }'
    $HtmlLines += '.summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 30px; }'
    $HtmlLines += '.summary-card { padding: 20px; border-radius: 8px; text-align: center; color: white; font-weight: bold; }'
    $HtmlLines += '.summary-high { background: linear-gradient(135deg, #ff6b6b 0%, #ee5a52 100%); }'
    $HtmlLines += '.summary-medium { background: linear-gradient(135deg, #feca57 0%, #ff9f43 100%); }'
    $HtmlLines += '.summary-low { background: linear-gradient(135deg, #48dbfb 0%, #0abde3 100%); }'
    $HtmlLines += '.ticket { margin: 15px 0; padding: 20px; border-radius: 8px; border-left: 5px solid #ccc; background: #fafafa; position: relative; }'
    $HtmlLines += '.ticket-high { border-left-color: #ff6b6b; background: #fff5f5; }'
    $HtmlLines += '.ticket-medium { border-left-color: #feca57; background: #fffbf0; }'
    $HtmlLines += '.ticket-low { border-left-color: #48dbfb; background: #f0fbff; }'
    $HtmlLines += '.ticket-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 15px; }'
    $HtmlLines += '.ticket-id { font-size: 20px; font-weight: bold; color: #0066cc; margin: 0; }'
    $HtmlLines += '.ticket-meta { display: flex; gap: 10px; align-items: center; }'
    $HtmlLines += '.ticket-source { padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }'
    $HtmlLines += '.source-assigned { background: #28a745; color: white; }'
    $HtmlLines += '.source-mentioned { background: #ffc107; color: #212529; }'
    $HtmlLines += '.source-both { background: #17a2b8; color: white; }'
    $HtmlLines += '.ticket-title { font-size: 16px; font-weight: bold; margin: 10px 0; color: #333; }'
    $HtmlLines += '.ticket-details { margin: 8px 0; color: #666; }'
    $HtmlLines += '.ticket-tags { margin: 10px 0; }'
    $HtmlLines += '.tag { background: #e1e8ed; color: #14171a; padding: 2px 8px; border-radius: 12px; font-size: 12px; margin-right: 5px; display: inline-block; }'
    $HtmlLines += '.action-box { background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; padding: 12px; margin: 15px 0; clear: both; }'
    $HtmlLines += '.action-title { font-weight: bold; color: #856404; margin-bottom: 5px; }'
    $HtmlLines += '.reasons { font-style: italic; color: #666; font-size: 14px; margin: 10px 0; }'
    $HtmlLines += '.content-analysis { background: #f8f9fa; border: 1px solid #dee2e6; border-radius: 5px; padding: 12px; margin: 15px 0; }'
    $HtmlLines += '.analysis-title { font-weight: bold; color: #495057; margin-bottom: 8px; font-size: 14px; }'
    $HtmlLines += '.analysis-summary { background: #e7f3ff; padding: 8px; border-radius: 3px; margin: 5px 0; font-size: 13px; }'
    $HtmlLines += '.analysis-section { margin: 8px 0; }'
    $HtmlLines += '.analysis-item { background: #f1f3f4; padding: 4px 8px; margin: 2px 0; border-radius: 3px; font-size: 12px; }'
    $HtmlLines += '.decision-item { background: #d1ecf1; border-left: 3px solid #bee5eb; }'
    $HtmlLines += '.next-step-item { background: #d4edda; border-left: 3px solid #c3e6cb; }'
    $HtmlLines += '.btn { background: #0066cc; color: white; padding: 8px 16px; text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 10px; }'
    $HtmlLines += '.btn:hover { background: #0056b3; text-decoration: none; }'
    $HtmlLines += '</style>'
    $HtmlLines += '</head>'
    $HtmlLines += '<body>'
    $HtmlLines += '<div class="container">'
    $HtmlLines += '<div class="header">'
    $HtmlLines += '<h1>TFS Daily Ticket Summary</h1>'
    $HtmlLines += "<p>Analysis for the last $Days day(s)</p>"
    $HtmlLines += '</div>'
    
    # Summary section
    $HtmlLines += '<div class="summary">'
    $HtmlLines += '<div class="summary-card summary-high">'
    $HtmlLines += "<div>High Priority: $($HighPriority.Count)</div>"
    $HtmlLines += '</div>'
    $HtmlLines += '<div class="summary-card summary-medium">'
    $HtmlLines += "<div>Medium Priority: $($MediumPriority.Count)</div>"
    $HtmlLines += '</div>'
    $HtmlLines += '<div class="summary-card summary-low">'
    $HtmlLines += "<div>Low Priority: $($LowPriority.Count)</div>"
    $HtmlLines += '</div>'
    $HtmlLines += '</div>'
    
    # Add tickets by priority
    $PriorityGroups = @(
        @{ Level = 'High'; Tickets = $HighPriority; Class = 'high' }
        @{ Level = 'Medium'; Tickets = $MediumPriority; Class = 'medium' }
        @{ Level = 'Low'; Tickets = $LowPriority; Class = 'low' }
    )
    
    foreach ($Group in $PriorityGroups) {
        if ($Group.Tickets.Count -gt 0) {
            $HtmlLines += "<h2>$($Group.Level) Priority Tickets ($($Group.Tickets.Count))</h2>"
            
            foreach ($Ticket in $Group.Tickets) {
                $Fields = $Ticket.Item.fields
                $ReasonsText = $Ticket.Priority.Reasons -join ", "
                $TicketId = $Ticket.Item.id
                
                # Fix URL to actual TFS ticket with proper ID
                $TicketUrl = "$TfsUrl/$ProjectName/_workitems/edit/$TicketId"
                
                # Determine source class for color coding
                $SourceClass = switch ($Ticket.Source) {
                    "Assigned" { "source-assigned" }
                    "@Mentioned" { "source-mentioned" }
                    "Assigned & @Mentioned" { "source-both" }
                    default { "source-assigned" }
                }
                
                $HtmlLines += "<div class=`"ticket ticket-$($Group.Class)`">"
                
                # Header with ticket ID and source
                $HtmlLines += '<div class="ticket-header">'
                $HtmlLines += "<div class=`"ticket-id`"><a href=`"$TicketUrl`" target=`"_blank`" style=`"color: #0066cc; text-decoration: underline;`">Ticket #$TicketId</a></div>"
                $HtmlLines += '<div class="ticket-meta">'
                $HtmlLines += "<div class=`"ticket-source $SourceClass`">$($Ticket.Source)</div>"
                $HtmlLines += '</div>'
                $HtmlLines += '</div>'
                
                # Title
                $HtmlLines += "<div class=`"ticket-title`">$($Fields.'System.Title')</div>"
                
                # Details
                $HtmlLines += "<div class=`"ticket-details`"><strong>Type:</strong> $($Fields.'System.WorkItemType')</div>"
                $HtmlLines += "<div class=`"ticket-details`"><strong>State:</strong> $($Fields.'System.State')</div>"
                if ($Fields.'System.AssignedTo') {
                    $HtmlLines += "<div class=`"ticket-details`"><strong>Assigned:</strong> $($Fields.'System.AssignedTo'.displayName)</div>"
                }
                $HtmlLines += "<div class=`"ticket-details`"><strong>Last Updated:</strong> $($Fields.'System.ChangedDate')</div>"
                
                # Tags
                if ($Fields.'System.Tags') {
                    $Tags = $Fields.'System.Tags' -split ';' | Where-Object { $_.Trim() -ne '' }
                    if ($Tags.Count -gt 0) {
                        $HtmlLines += '<div class="ticket-tags">'
                        $HtmlLines += '<strong>Tags:</strong> '
                        foreach ($Tag in $Tags) {
                            $HtmlLines += "<span class=`"tag`">$($Tag.Trim())</span>"
                        }
                        $HtmlLines += '</div>'
                    }
                }
                
                # Content Analysis
                if ($Ticket.ContentAnalysis) {
                    $Analysis = $Ticket.ContentAnalysis
                    $HtmlLines += '<div class="content-analysis">'
                    $HtmlLines += '<div class="analysis-title">Ticket Analysis</div>'
                    
                    # Summary
                    if ($Analysis.Summary -and $Analysis.Summary.Length -gt 0) {
                        $HtmlLines += '<div class="analysis-summary">'
                        $HtmlLines += "<strong>Summary:</strong> $($Analysis.Summary)"
                        $HtmlLines += '</div>'
                    }
                    
                    # Key Points
                    if ($Analysis.KeyPoints.Count -gt 0) {
                        $HtmlLines += '<div class="analysis-section">'
                        $HtmlLines += '<strong style="font-size: 13px;">Key Points:</strong>'
                        foreach ($KeyPoint in $Analysis.KeyPoints) {
                            $HtmlLines += "<div class=`"analysis-item`">$KeyPoint</div>"
                        }
                        $HtmlLines += '</div>'
                    }
                    
                    # Recent Decisions
                    if ($Analysis.Decisions.Count -gt 0) {
                        $HtmlLines += '<div class="analysis-section">'
                        $HtmlLines += '<strong style="font-size: 13px;">Recent Decisions:</strong>'
                        foreach ($Decision in $Analysis.Decisions) {
                            $HtmlLines += "<div class=`"analysis-item decision-item`">$Decision</div>"
                        }
                        $HtmlLines += '</div>'
                    }
                    
                    # Next Steps
                    if ($Analysis.NextSteps.Count -gt 0) {
                        $HtmlLines += '<div class="analysis-section">'
                        $HtmlLines += '<strong style="font-size: 13px;">Action Items:</strong>'
                        foreach ($NextStep in $Analysis.NextSteps) {
                            $HtmlLines += "<div class=`"analysis-item next-step-item`">$NextStep</div>"
                        }
                        $HtmlLines += '</div>'
                    }
                    
                    $HtmlLines += '</div>'
                }
                
                # Action box - Remove garbage characters
                $HtmlLines += '<div class="action-box">'
                $HtmlLines += '<div class="action-title">Recommended Action:</div>'
                $HtmlLines += "<div>$($Ticket.Action)</div>"
                $HtmlLines += '</div>'
                
                # Priority reasons
                $HtmlLines += "<div class=`"reasons`"><strong>Priority Reasons:</strong> $ReasonsText</div>"
                
                $HtmlLines += '</div>'
            }
        }
    }
    
    $HtmlLines += '<div style="text-align: center; margin-top: 30px; color: #888;">'
    $HtmlLines += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $HtmlLines += '</div>'
    $HtmlLines += '</div>'
    $HtmlLines += '</body>'
    $HtmlLines += '</html>'
    
    # Save the file
    $HtmlContent = $HtmlLines -join "`n"
    $HtmlContent | Out-File -FilePath $HtmlPath -Encoding UTF8
    
    Write-ColorOutput "HTML summary saved to: $HtmlPath" "Success"
    
    # Open in browser if configured
    if ($Config.OPEN_BROWSER -eq "True" -or $ShowInBrowser) {
        Start-Process $HtmlPath
        Write-ColorOutput "Opening summary in your default browser..." "Info"
    }
}

function Save-TextSummary {
    param([hashtable]$Config, [array]$AllTickets, [int]$Days)
    
    $TextPath = if ($Config.TEXT_PATH) { $Config.TEXT_PATH } else { "$env:USERPROFILE\Documents\TFS-Daily-Summary.txt" }
    
    Write-ColorOutput "Generating text summary..." "Info"
    
    # Group tickets by priority
    $HighPriority = @($AllTickets | Where-Object { $_.Priority.Level -eq 'HIGH' })
    $MediumPriority = @($AllTickets | Where-Object { $_.Priority.Level -eq 'MEDIUM' })
    $LowPriority = @($AllTickets | Where-Object { $_.Priority.Level -eq 'LOW' })
    
    $TextLines = @()
    $TextLines += "========================================"
    $TextLines += "TFS DAILY TICKET SUMMARY"
    $TextLines += "========================================"
    $TextLines += "Analysis Period: Last $Days day(s)"
    $TextLines += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $TextLines += ""
    $TextLines += "SUMMARY"
    $TextLines += "-------"
    $TextLines += "Total Tickets: $($AllTickets.Count)"
    $TextLines += "  High Priority: $($HighPriority.Count)"
    $TextLines += "  Medium Priority: $($MediumPriority.Count)"
    $TextLines += "  Low Priority: $($LowPriority.Count)"
    $TextLines += ""

    # Add tickets by priority
    $PriorityGroups = @(
        @{ Level = 'HIGH'; Tickets = $HighPriority }
        @{ Level = 'MEDIUM'; Tickets = $MediumPriority }
        @{ Level = 'LOW'; Tickets = $LowPriority }
    )
    
    foreach ($Group in $PriorityGroups) {
        if ($Group.Tickets.Count -gt 0) {
            $TextLines += "$($Group.Level) PRIORITY TICKETS ($($Group.Tickets.Count))"
            $TextLines += "=" * 40
            
            foreach ($Ticket in $Group.Tickets) {
                $Fields = $Ticket.Item.fields
                $ReasonsText = $Ticket.Priority.Reasons -join ", "
                
                # Create proper TFS URL
                $TicketUrl = "$($Config.TFS_URL)/$($Config.PROJECT_NAME)/_workitems/edit/$($Fields.'System.Id')"
                
                $TextLines += ""
                $TextLines += "TICKET #$($Fields.'System.Id') - $($Fields.'System.WorkItemType') ($($Ticket.Source))"
                $TextLines += "Title: $($Fields.'System.Title')"
                $TextLines += "State: $($Fields.'System.State')"
                if ($Fields.'System.AssignedTo') {
                    $TextLines += "Assigned: $($Fields.'System.AssignedTo'.displayName)"
                }
                $TextLines += "Last Updated: $($Fields.'System.ChangedDate')"
                
                # Add tags if they exist
                if ($Fields.'System.Tags') {
                    $Tags = $Fields.'System.Tags' -split ';' | Where-Object { $_.Trim() -ne '' } | ForEach-Object { $_.Trim() }
                    if ($Tags.Count -gt 0) {
                        $TextLines += "Tags: $($Tags -join ', ')"
                    }
                }
                
                # Add content analysis
                if ($Ticket.ContentAnalysis) {
                    $Analysis = $Ticket.ContentAnalysis
                    if ($Analysis.Summary -and $Analysis.Summary.Length -gt 0) {
                        $TextLines += "Summary: $($Analysis.Summary)"
                    }
                    
                    if ($Analysis.KeyPoints.Count -gt 0) {
                        $TextLines += "Key Points:"
                        foreach ($KeyPoint in $Analysis.KeyPoints) {
                            $TextLines += "  • $KeyPoint"
                        }
                    }
                    
                    if ($Analysis.Decisions.Count -gt 0) {
                        $TextLines += "Recent Decisions:"
                        foreach ($Decision in $Analysis.Decisions) {
                            $TextLines += "  → $Decision"
                        }
                    }
                    
                    if ($Analysis.NextSteps.Count -gt 0) {
                        $TextLines += "Action Items:"
                        foreach ($NextStep in $Analysis.NextSteps) {
                            $TextLines += "  ▶ $NextStep"
                        }
                    }
                }
                
                $TextLines += "Action: $($Ticket.Action)"
                $TextLines += "Reasons: $ReasonsText"
                $TextLines += "URL: $TicketUrl"
                $TextLines += "-" * 40
            }
        }
    }
    
    $TextLines += ""
    $TextLines += "NEXT STEPS"
    $TextLines += "----------"
    $TextLines += "1. Focus on HIGH priority items first"
    $TextLines += "2. Address CRITICAL issues immediately"
    $TextLines += "3. Update status on IN PROGRESS items"
    $TextLines += "4. Review @mentioned items"
    $TextLines += "5. Plan TO DO items"
    
    # Save the file
    $TextContent = $TextLines -join "`n"
    $TextContent | Out-File -FilePath $TextPath -Encoding UTF8
    
    Write-ColorOutput "Text summary saved to: $TextPath" "Success"
}

# Include all the existing functions from the original script
function Setup-Configuration {
    Write-ColorOutput "Setting up TFS configuration..." "Info"
    Write-Host "This script will help you configure access to your TFS server."
    Write-Host ""
    
    $TfsUrl = Read-Host "Enter your TFS Organization URL (e.g., https://tfs.deltek.com/tfs/Deltek)"
    $ProjectName = Read-Host "Enter your Project Name (e.g., TIP)"
    
    Write-Host ""
    Write-ColorOutput "Choose your authentication method:" "Info"
    Write-Host "1. Personal Access Token (PAT) - Recommended"
    Write-Host "2. Windows Authentication - For on-premise TFS"
    $AuthChoice = Read-Host "Enter your choice (1 or 2)"
    
    $UseWindowsAuth = $false
    $Pat = ""
    
    if ($AuthChoice -eq "2") {
        $UseWindowsAuth = $true
        Write-ColorOutput "Using Windows Authentication" "Info"
    } else {
        Write-Host ""
        Write-ColorOutput "PAT Setup Guide:" "Info"
        Write-Host "1. Go to: $TfsUrl"
        Write-Host "2. Click your profile picture -> Security -> Personal Access Tokens"
        Write-Host "3. Click New Token"
        Write-Host "4. Name: TFS Ticket Analyzer"
        Write-Host "5. Scopes: Select Work Items (Read)"
        Write-Host "6. Click Create and copy the token"
        Write-Host ""
        
        $Pat = Read-Host "Enter your Personal Access Token" -AsSecureString
        $PatPlainText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Pat))
        $Pat = $PatPlainText
    }
    
    $UserDisplayName = Read-Host "Enter your display name for @mentions (e.g., John Doe)"
    
    # Save configuration
    $ConfigText = "TFS_URL=$TfsUrl`nPROJECT_NAME=$ProjectName`nPAT=$Pat`nUSER_DISPLAY_NAME=$UserDisplayName`nUSE_WINDOWS_AUTH=$UseWindowsAuth"
    $ConfigText | Out-File -FilePath $ConfigFile -Encoding UTF8
    
    Write-ColorOutput "Configuration saved!" "Success"
    Write-Host "Next step: Configure output preferences with: .\tfs-ticket-analyzer-multi-output.ps1 setup-output"
}

function Load-Configuration {
    if (-not (Test-Path $ConfigFile)) {
        Write-ColorOutput "Configuration not found. Please run: .\tfs-ticket-analyzer-multi-output.ps1 setup" "Error"
        exit 1
    }
    
    $Config = @{}
    Get-Content $ConfigFile | ForEach-Object {
        if ($_ -match '^(.+?)=(.*)$') {
            $Config[$matches[1]] = $matches[2]
        }
    }
    
    return $Config
}

function Get-Headers {
    param([hashtable]$Config)
    
    if ($Config.USE_WINDOWS_AUTH -eq 'True') {
        return @{ 'Content-Type' = 'application/json' }
    } else {
        $AuthString = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($Config.PAT)"))
        return @{
            'Content-Type' = 'application/json'
            'Authorization' = "Basic $AuthString"
        }
    }
}

function Get-PriorityLevel {
    param($Fields, $Source)
    
    $Score = 0
    $Reasons = @()
    
    try {
        # State scoring
        $State = if ($Fields -and $Fields.'System.State') { $Fields.'System.State' } else { "" }
        switch ($State) {
            'In Progress' { $Score += 5; $Reasons += "Work in progress" }
            'Active' { $Score += 4; $Reasons += "Active item" }
            'New' { $Score += 3; $Reasons += "New item" }
            'To Do' { $Score += 2 }
            default { $Score += 1 }
        }
        
        # Type scoring
        $Type = if ($Fields -and $Fields.'System.WorkItemType') { $Fields.'System.WorkItemType' } else { "" }
        switch ($Type) {
            'Bug' { $Score += 3; $Reasons += "Bug item" }
            'Task' { $Score += 2 }
            default { $Score += 2 }
        }
        
        # Check keywords
        $Title = if ($Fields -and $Fields.'System.Title') { $Fields.'System.Title' } else { "" }
        $Description = if ($Fields -and $Fields.'System.Description') { $Fields.'System.Description' } else { "" }
        $TextFields = "$Title $Description"
        
        if ($TextFields -like "*CRITICAL*" -or $TextFields -like "*SHOWSTOPPER*") {
            $Score += 3
            $Reasons += "Critical keyword found"
        }
        if ($TextFields -like "*ERROR*" -or $TextFields -like "*BROKEN*") {
            $Score += 2
            $Reasons += "Priority keyword found"
        }
        
        # Source bonus
        if ($Source -eq "@Mentioned") {
            $Score += 1
            $Reasons += "You were mentioned"
        }
    } catch {
        Write-Host "Warning: Could not analyze priority for ticket fields" -ForegroundColor Yellow
        $Score = 2  # Default score if analysis fails
        $Reasons += "Analysis error - default priority"
    }
    
    $Level = if ($Score -ge 8) { 'HIGH' } elseif ($Score -ge 5) { 'MEDIUM' } else { 'LOW' }
    
    return @{
        Level = $Level
        Score = $Score
        Reasons = $Reasons
    }
}

function Get-ActionRecommendation {
    param($Fields, $Priority, $Source)
    
    try {
        $State = if ($Fields -and $Fields.'System.State') { $Fields.'System.State' } else { "" }
        $Type = if ($Fields -and $Fields.'System.WorkItemType') { $Fields.'System.WorkItemType' } else { "" }
        
        if ($Type -eq 'Bug' -and $State -eq 'New') {
            return "Investigate and reproduce the issue"
        } elseif ($State -eq 'In Progress') {
            return "Continue work and provide updates"
        } elseif ($State -eq 'Active') {
            return "Focus on completing tasks"
        } elseif ($State -eq 'To Do') {
            return "Schedule and start work"
        } elseif ($Source -eq '@Mentioned') {
            return "Review mention and respond"
        } elseif ($Priority -and $Priority.Level -eq 'HIGH') {
            return "High priority - address immediately"
        } else {
            return "Review and plan next steps"
        }
    } catch {
        return "Review and plan next steps"
    }
}

function Get-WorkItemComments {
    param([hashtable]$Config, [string]$WorkItemId, [string]$TfsUrl, [string]$ProjectName, [hashtable]$Headers)
    
    try {
        # Try the comments API first (newer TFS versions)
        $CommentsUrl = "$TfsUrl/$ProjectName/_apis/wit/workItems/$WorkItemId/comments?api-version=6.0"
        $CommentsResponse = Invoke-RestMethod -Uri $CommentsUrl -Headers $Headers -ErrorAction Stop
        
        $RecentComments = @()
        if ($CommentsResponse.comments -and $CommentsResponse.comments.Count -gt 0) {
            # Get recent comments (last 5) 
            $CommentsResponse.comments | Sort-Object createdDate -Descending | Select-Object -First 5 | ForEach-Object {
                $RecentComments += @{
                    Text = if ($_.text) { $_.text } else { "" }
                    Author = if ($_.createdBy -and $_.createdBy.displayName) { $_.createdBy.displayName } else { "Unknown" }
                    Date = if ($_.createdDate) { $_.createdDate } else { "" }
                }
            }
        }
        
        return $RecentComments
    } catch {
        # If comments API fails, try to get work item history (fallback for older TFS)
        try {
            $HistoryUrl = "$TfsUrl/$ProjectName/_apis/wit/workItems/$WorkItemId/updates?api-version=6.0"
            $HistoryResponse = Invoke-RestMethod -Uri $HistoryUrl -Headers $Headers -ErrorAction Stop
            
            $RecentComments = @()
            if ($HistoryResponse.value) {
                # Get recent history entries with comments
                $HistoryResponse.value | Sort-Object revisedDate -Descending | Select-Object -First 5 | ForEach-Object {
                    if ($_.fields -and $_.fields.'System.History') {
                        $RecentComments += @{
                            Text = $_.fields.'System.History'
                            Author = if ($_.revisedBy -and $_.revisedBy.displayName) { $_.revisedBy.displayName } else { "Unknown" }
                            Date = if ($_.revisedDate) { $_.revisedDate } else { "" }
                        }
                    }
                }
            }
            
            return $RecentComments
        } catch {
            # If both APIs fail, return empty array silently
            return @()
        }
    }
}

function Analyze-TicketContent {
    param($Fields, [array]$Comments)
    
    $Analysis = @{
        Summary = ""
        KeyPoints = @()
        Decisions = @()
        NextSteps = @()
    }
    
    try {
        # Priority order for descriptions - use the first one found with content
        $DescriptionFields = @(
            'Microsoft.VSTS.Common.DescriptionHtml',
            'System.Description',
            'Microsoft.VSTS.TCM.ReproSteps'
        )
        
        $MainDescription = ""
        foreach ($Field in $DescriptionFields) {
            if ($Fields -and $Fields.$Field -and $Fields.$Field.ToString().Trim().Length -gt 0) {
                $MainDescription = $Fields.$Field.ToString()
                break
            }
        }
        
        # Collect full description content
        $FullDescription = ""
        if ($MainDescription.Length -gt 0) {
            $FullDescription = $MainDescription -replace '<[^>]*>', '' -replace '\s+', ' ' -replace '&nbsp;', ' ' -replace '&gt;', '>' -replace '&lt;', '<'
            $FullDescription = $FullDescription.Trim()
        }
        
        # Collect full content from all specialized fields
        $AllKeyPointContent = @()
        $KeyPointFields = @{
            'Microsoft.VSTS.Common.AcceptanceCriteria' = 'Acceptance Criteria'
            'Microsoft.VSTS.TCM.ReproSteps' = 'Reproduction Steps'
            'Deltek.notes' = 'Notes'
            'Deltek.DevelopmentNotes' = 'Development'
            'Deltek.DevelopmentRCANotes' = 'Root Cause'
            'Deltek.IRBRemovalNotes' = 'IRB Notes'
            'Deltek.RelNotesDescription' = 'Release Notes'
        }
        
        foreach ($FieldName in $KeyPointFields.Keys) {
            if ($Fields -and $Fields.$FieldName -and $Fields.$FieldName.ToString().Trim().Length -gt 0) {
                $FieldContent = $Fields.$FieldName.ToString()
                $CleanContent = $FieldContent -replace '<[^>]*>', '' -replace '\s+', ' ' -replace '&nbsp;', ' ' -replace '&gt;', '>' -replace '&lt;', '<'
                $CleanContent = $CleanContent.Trim()
                
                if ($CleanContent.Length -gt 0) {
                    $AllKeyPointContent += @{
                        Field = $KeyPointFields[$FieldName]
                        Content = $CleanContent
                    }
                }
            }
        }
        
        # Collect full history content for analysis
        $FullHistory = ""
        if ($Fields -and $Fields.'System.History' -and $Fields.'System.History'.ToString().Trim().Length -gt 0) {
            $HistoryContent = $Fields.'System.History'.ToString()
            $FullHistory = $HistoryContent -replace '<[^>]*>', '' -replace '\s+', ' ' -replace '&nbsp;', ' '
            $FullHistory = $FullHistory.Trim()
        }
        
    } catch {
        Write-Verbose "Error in content analysis: $($_.Exception.Message)"
    }
    
    # Collect full comments content
    $AllComments = @()
    if ($Comments -and $Comments.Count -gt 0) {
        try {
            foreach ($Comment in $Comments) {
                $CommentText = if ($Comment.Text -and $Comment.Text.Length -gt 0) { 
                    $Comment.Text
                } elseif ($Comment.oldValue -or $Comment.newValue) {
                    "$($Comment.oldValue) -> $($Comment.newValue)"
                } else {
                    continue
                }
                
                if ($CommentText.Length -gt 0) {
                    $CleanComment = $CommentText -replace '<[^>]*>', '' -replace '\s+', ' ' -replace '@\{.*?\}', '' -replace 'oldValue=|newValue=', ''
                    $CleanComment = $CleanComment.Trim()
                    
                    if ($CleanComment.Length -gt 0) {
                        $AllComments += @{
                            Author = $Comment.Author
                            Text = $CleanComment
                        }
                    }
                }
            }
        } catch {
            Write-Verbose "Error processing comments: $($_.Exception.Message)"
        }
    }
    
    # Now perform intelligent contextual analysis on all collected content
    
    # 1. Create contextual Summary from description
    if ($FullDescription.Length -gt 0) {
        # Analyze content depth and complexity
        $WordCount = ($FullDescription -split '\s+').Count
        $SentenceCount = ($FullDescription -split '[.!?]' | Where-Object { $_.Trim().Length -gt 5 }).Count
        
        # Identify key concepts and context
        $KeyConcepts = @()
        $TechnicalContext = ""
        
        # Technical categorization
        if ($FullDescription -match "(?i)(bug|error|exception|crash|fail|broken|not working)") { 
            $KeyConcepts += "Bug Fix"
            $TechnicalContext = "defect resolution"
        }
        if ($FullDescription -match "(?i)(new feature|enhancement|improve|add|implement|develop)") { 
            $KeyConcepts += "Feature Development"
            $TechnicalContext = "functionality expansion"
        }
        if ($FullDescription -match "(?i)(test|testing|verify|validate|qa|quality)") { 
            $KeyConcepts += "Quality Assurance"
            $TechnicalContext = "verification process"
        }
        if ($FullDescription -match "(?i)(performance|slow|optimization|speed|memory)") {
            $KeyConcepts += "Performance"
            $TechnicalContext = "system optimization"
        }
        if ($FullDescription -match "(?i)(security|vulnerability|authentication|authorization)") {
            $KeyConcepts += "Security"
            $TechnicalContext = "security enhancement"
        }
        
        # Create adaptive summary based on content length and complexity
        if ($WordCount -lt 20) {
            # Short description - use as-is
            $Analysis.Summary = $FullDescription
        } elseif ($WordCount -lt 100) {
            # Medium description - extract key sentences
            $KeySentences = $FullDescription -split '[.!?]' | Where-Object { 
                $_ -ne $null -and $_.GetType().Name -eq 'String' -and $_.ToString().Trim().Length -gt 10
            } | Select-Object -First 2
            
            $SummaryText = ($KeySentences | ForEach-Object { $_.ToString().Trim() }) -join '. '
            if ($KeyConcepts.Count -gt 0) {
                $Analysis.Summary = "[$($KeyConcepts -join ', ')] $SummaryText."
            } else {
                $Analysis.Summary = "$SummaryText."
            }
        } else {
            # Long description - create intelligent summary
            $ImportantSentences = @()
            $Sentences = $FullDescription -split '[.!?]' | Where-Object { 
                $_ -ne $null -and $_.GetType().Name -eq 'String' -and $_.ToString().Trim().Length -gt 15
            }
            
            # Extract most informative sentences
            foreach ($Sentence in $Sentences) {
                $SentenceText = $Sentence.ToString().Trim()
                # Look for sentences with key information indicators
                if ($SentenceText -match "(?i)(issue|problem|need|should|will|must|require|when|because|result|cause)") {
                    $ImportantSentences += $SentenceText
                }
            }
            
            if ($ImportantSentences.Count -eq 0) {
                $ImportantSentences = $Sentences | Select-Object -First 3
            } else {
                $ImportantSentences = $ImportantSentences | Select-Object -First 3
            }
            
            $SummaryText = ($ImportantSentences | ForEach-Object { $_.ToString().Trim() }) -join '. '
            if ($KeyConcepts.Count -gt 0) {
                $Analysis.Summary = "[$($KeyConcepts -join ', ')] $SummaryText."
            } else {
                $Analysis.Summary = "$SummaryText."
            }
        }
    }
    
    # 2. Contextually extract and format key points with subsections
    foreach ($KeyPoint in $AllKeyPointContent) {
        if ($KeyPoint.Content.Length -gt 10) {
            $FieldName = $KeyPoint.Field
            $Content = $KeyPoint.Content
            $WordCount = ($Content -split '\s+').Count
            
            # Analyze content structure and format accordingly
            if ($Content -match '[-•*]\s+' -or $Content -match '\d+\.\s+' -or $Content -match '\n\s*[-•*\d]') {
                # Handle structured lists/bullet points
                $Points = @()
                
                # Split by various list indicators
                $ListItems = $Content -split '[-•*]\s+|\d+\.\s+|\n\s*[-•*\d]\s*' | Where-Object { 
                    $_ -ne $null -and $_.GetType().Name -eq 'String' -and $_.ToString().Trim().Length -gt 8
                }
                
                foreach ($Item in $ListItems) {
                    $CleanItem = $Item.ToString().Trim()
                    if ($CleanItem.Length -gt 8) {
                        $Points += $CleanItem
                    }
                }
                
                if ($Points.Count -gt 0) {
                    # Format with field name and multiple subsections
                    $FormattedContent = "$FieldName" + ":" + "`n"
                    foreach ($Point in ($Points | Select-Object -First 5)) {
                        $FormattedContent += "  - $Point" + "`n"
                    }
                    $Analysis.KeyPoints += $FormattedContent.Trim()
                }
                
            } elseif ($Content -match '\n' -or $WordCount -gt 50) {
                # Handle multi-paragraph or long content
                $Paragraphs = $Content -split '\n+' | Where-Object { 
                    $_ -ne $null -and $_.GetType().Name -eq 'String' -and $_.ToString().Trim().Length -gt 15
                }
                
                if ($Paragraphs.Count -gt 1) {
                    # Multiple paragraphs - format with clear separation
                    $FormattedContent = "$FieldName" + ":" + "`n"
                    foreach ($Para in ($Paragraphs | Select-Object -First 4)) {
                        $CleanPara = $Para.ToString().Trim()
                        if ($CleanPara.Length -gt 15) {
                            # Summarize very long paragraphs
                            if ($CleanPara.Length -gt 200) {
                                $Sentences = $CleanPara -split '[.!?]' | Where-Object { $_.Trim().Length -gt 10 }
                                $CleanPara = ($Sentences | Select-Object -First 2 | ForEach-Object { $_.ToString().Trim() }) -join '. ' + '.'
                            }
                            $FormattedContent += "`n$CleanPara`n"
                        }
                    }
                    $Analysis.KeyPoints += $FormattedContent.Trim()
                } else {
                    # Single long paragraph - intelligently summarize
                    $CleanContent = $Paragraphs[0].ToString().Trim()
                    if ($CleanContent.Length -gt 300) {
                        # Extract key sentences for very long content
                        $Sentences = $CleanContent -split '[.!?]' | Where-Object { 
                            $_ -ne $null -and $_.ToString().Trim().Length -gt 15
                        }
                        
                        $KeySentences = @()
                        foreach ($Sentence in $Sentences) {
                            $SentText = $Sentence.ToString().Trim()
                            # Prioritize sentences with important keywords
                            if ($SentText -match "(?i)(must|should|will|need|require|important|critical|ensure|verify|when|if|because)") {
                                $KeySentences += $SentText
                            }
                        }
                        
                        if ($KeySentences.Count -eq 0) {
                            $KeySentences = $Sentences | Select-Object -First 3
                        } else {
                            $KeySentences = $KeySentences | Select-Object -First 3
                        }
                        
                        $SummarizedContent = ($KeySentences | ForEach-Object { $_.ToString().Trim() }) -join '. ' + '.'
                        $Analysis.KeyPoints += "$FieldName" + ": " + $SummarizedContent
                    } else {
                        $Analysis.KeyPoints += "$FieldName" + ": " + $CleanContent
                    }
                }
                
            } else {
                # Short, simple content - use as-is
                $Analysis.KeyPoints += "$FieldName" + ": " + $Content
            }
        }
    }
    
    # 3. Intelligently extract decisions from history and comments
    $AllDecisionSources = @()
    if ($FullHistory) { $AllDecisionSources += @{Source = "History"; Text = $FullHistory} }
    foreach ($Comment in $AllComments) {
        $AllDecisionSources += @{Source = $Comment.Author; Text = $Comment.Text}
    }
    
    foreach ($Source in $AllDecisionSources) {
        if ($Source.Text -and $Source.Text.Length -gt 10) {
            $SourceText = $Source.Text
            
            # Look for status changes with context
            $StateMatches = [regex]::Matches($SourceText, "(?i)(State changed from [^.;]+ to [^.;]+|Priority changed from [^.;]+ to [^.;]+|assigned to [^.;,]+|Status.*changed|marked.*complete|resolved.*issue)")
            foreach ($Match in $StateMatches) {
                $StateChange = $Match.Value.ToString().Trim()
                $Analysis.Decisions += "Status Update: " + $StateChange
            }
            
            # Look for explicit decision statements with more context
            $DecisionPatterns = @(
                "(?i)([^.;]{5,80}(decided to|decision was made to|agreed to|approved|rejected|concluded that)[^.;]{5,80})",
                "(?i)([^.;]{5,80}(will proceed with|will not|chosen approach|selected option)[^.;]{5,80})",
                "(?i)([^.;]{5,80}(resolution is to|solution is to|approach will be)[^.;]{5,80})"
            )
            
            foreach ($Pattern in $DecisionPatterns) {
                $DecisionMatches = [regex]::Matches($SourceText, $Pattern)
                foreach ($Match in $DecisionMatches) {
                    $DecisionText = $Match.Value.ToString().Trim()
                    if ($DecisionText.Length -gt 20) {
                        $Prefix = if ($Source.Source -eq "History") { "System" } else { $Source.Source }
                        $Analysis.Decisions += $Prefix + " decided: " + $DecisionText
                    }
                }
            }
        }
    }
    
    # 4. Contextually extract action items and next steps
    $AllActionSources = $AllDecisionSources
    
    foreach ($Source in $AllActionSources) {
        if ($Source.Text -and $Source.Text.Length -gt 10) {
            $SourceText = $Source.Text
            
            # Look for action-oriented statements with various patterns
            $ActionPatterns = @(
                "(?i)([^.;]{10,120}(will need to|must|should|plan to|going to|intend to)[^.;]{10,120})",
                "(?i)([^.;]{10,120}(next step is|next action|action item|todo)[^.;]{10,120})",
                "(?i)([^.;]{10,120}(needs to be|has to be|requires|pending)[^.;]{10,120})",
                "(?i)([^.;]{10,120}(follow up|investigate|research|implement|develop|test)[^.;]{10,120})"
            )
            
            foreach ($Pattern in $ActionPatterns) {
                $ActionMatches = [regex]::Matches($SourceText, $Pattern)
                foreach ($Match in $ActionMatches) {
                    $ActionText = $Match.Value.ToString().Trim()
                    if ($ActionText.Length -gt 25) {
                        # Clean up and categorize the action
                        $ActionType = "General"
                        if ($ActionText -match "(?i)(test|verify|validate|check)") { $ActionType = "Testing" }
                        elseif ($ActionText -match "(?i)(implement|develop|code|build)") { $ActionType = "Development" }
                        elseif ($ActionText -match "(?i)(investigate|research|analyze|review)") { $ActionType = "Analysis" }
                        elseif ($ActionText -match "(?i)(deploy|release|configure)") { $ActionType = "Deployment" }
                        
                        $Prefix = if ($Source.Source -eq "History") { "System" } else { $Source.Source }
                        $Analysis.NextSteps += "[" + $ActionType + "] " + $Prefix + ": " + $ActionText
                    }
                }
            }
        }
    }
    
    # Remove duplicates and intelligently limit results
    $Analysis.KeyPoints = $Analysis.KeyPoints | Select-Object -Unique | Select-Object -First 6
    $Analysis.Decisions = $Analysis.Decisions | Select-Object -Unique | 
        Where-Object { $_.Length -gt 30 } | Select-Object -First 4
    $Analysis.NextSteps = $Analysis.NextSteps | Select-Object -Unique | 
        Where-Object { $_.Length -gt 35 } | Select-Object -First 4
    
    return $Analysis
}

function Send-Office365Email {
    param([hashtable]$Config, [string]$HtmlContent, [string]$Subject)
    
    try {
        $SmtpClient = New-Object System.Net.Mail.SmtpClient
        $SmtpClient.Host = $Config.SMTP_SERVER
        $SmtpClient.Port = [int]$Config.SMTP_PORT
        $SmtpClient.EnableSsl = $true
        $SmtpClient.Credentials = New-Object System.Net.NetworkCredential($Config.SMTP_USER, $Config.SMTP_PASS)
        
        $MailMessage = New-Object System.Net.Mail.MailMessage
        $MailMessage.From = $Config.FROM_EMAIL
        $MailMessage.To.Add($Config.TO_EMAIL)
        $MailMessage.Subject = $Subject
        $MailMessage.Body = $HtmlContent
        $MailMessage.IsBodyHtml = $true
        
        $SmtpClient.Send($MailMessage)
        
        Write-ColorOutput "Email sent successfully to $($Config.TO_EMAIL)" "Success"
        
        # Cleanup
        $MailMessage.Dispose()
        $SmtpClient.Dispose()
        
        return $true
        
    } catch {
        Write-ColorOutput "Failed to send email: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Analyze-Tickets {
    param([hashtable]$Config, [int]$Days)
    
    $Headers = Get-Headers -Config $Config
    $ProjectName = $Config.PROJECT_NAME
    $TfsUrl = $Config.TFS_URL
    $UserDisplayName = $Config.USER_DISPLAY_NAME
    
    Write-ColorOutput "Analyzing TFS tickets for the last $Days day(s)..." "Info"
    Write-Host "Project: $ProjectName"
    Write-Host "User: $UserDisplayName"
    
    # Determine output method from parameters or config
    if ($SaveHtml -or $ShowInBrowser -or $SaveText -or $SendEmail) {
        # Use parameter switches
    } elseif ($Config.OUTPUT_METHOD) {
        # Use configured method
        switch ($Config.OUTPUT_METHOD) {
            "HTML" { $SaveHtml = $true }
            "EMAIL" { $SendEmail = $true }
            "BOTH" { $SaveHtml = $true; $SendEmail = $true }
            "TEXT" { $SaveText = $true }
            "BROWSER" { $SaveHtml = $true; $ShowInBrowser = $true }
        }
    }
    
    Write-Host ""
    
    # Query 1: Assigned tickets - Use basic fields to avoid compatibility issues
    $AssignedQuery = @{
        query = "SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType], [System.AssignedTo], [System.ChangedDate], [System.Description], [System.Tags] FROM WorkItems WHERE [System.TeamProject] = '$ProjectName' AND [System.AssignedTo] = @Me AND [System.ChangedDate] >= @Today - $Days ORDER BY [System.ChangedDate] DESC"
    } | ConvertTo-Json
    
    # Query 2: @Mentioned tickets - Use basic fields to avoid compatibility issues
    $MentionQuery = @{
        query = "SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType], [System.AssignedTo], [System.ChangedDate], [System.Description], [System.Tags] FROM WorkItems WHERE [System.TeamProject] = '$ProjectName' AND [System.History] CONTAINS WORDS '@$UserDisplayName' AND [System.ChangedDate] >= @Today - $Days ORDER BY [System.ChangedDate] DESC"
    } | ConvertTo-Json
    
    $AllTickets = @()
    
    try {
        # Get assigned tickets
        Write-ColorOutput "Fetching assigned tickets..." "Info"
        $AssignedResponse = Invoke-RestMethod -Uri "$TfsUrl/$ProjectName/_apis/wit/wiql?api-version=6.0" -Method Post -Body $AssignedQuery -Headers $Headers
        
        if ($AssignedResponse.workItems -and $AssignedResponse.workItems.Count -gt 0) {
            $AssignedIds = ($AssignedResponse.workItems | ForEach-Object { $_.id }) -join ','
            $AssignedDetails = Invoke-RestMethod -Uri "$TfsUrl/$ProjectName/_apis/wit/workItems?ids=$AssignedIds&api-version=6.0" -Headers $Headers
            
            foreach ($Item in $AssignedDetails.value) {
                $AllTickets += @{
                    Item = $Item
                    Source = "Assigned"
                }
            }
        }
        
        # Get @mentioned tickets
        Write-ColorOutput "Fetching @mentioned tickets..." "Info"
        $MentionResponse = Invoke-RestMethod -Uri "$TfsUrl/$ProjectName/_apis/wit/wiql?api-version=6.0" -Method Post -Body $MentionQuery -Headers $Headers
        
        if ($MentionResponse.workItems -and $MentionResponse.workItems.Count -gt 0) {
            $MentionIds = ($MentionResponse.workItems | ForEach-Object { $_.id }) -join ','
            $MentionDetails = Invoke-RestMethod -Uri "$TfsUrl/$ProjectName/_apis/wit/workItems?ids=$MentionIds&api-version=6.0" -Headers $Headers
            
            foreach ($Item in $MentionDetails.value) {
                $ExistingItem = $AllTickets | Where-Object { $_.Item.id -eq $Item.id }
                if ($ExistingItem) {
                    $ExistingItem.Source = "Assigned & @Mentioned"
                } else {
                    $AllTickets += @{
                        Item = $Item
                        Source = "@Mentioned"
                    }
                }
            }
        }
        
        if ($AllTickets.Count -eq 0) {
            Write-ColorOutput "No tickets found in the last $Days day(s)." "Warning"
            return
        }
        
        # Analyze priorities, actions, and content
        Write-ColorOutput "Analyzing ticket content and comments..." "Info"
        
        # Create debug file for raw data analysis
        $DebugPath = "$env:USERPROFILE\Documents\TFS-Debug-Data.txt"
        $DebugLines = @()
        $DebugLines += "=".PadRight(80, '=')
        $DebugLines += "TFS TICKET ANALYZER - DEBUG DATA"
        $DebugLines += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $DebugLines += "Total Tickets Found: $($AllTickets.Count)"
        $DebugLines += "=".PadRight(80, '=')
        $DebugLines += ""
        
        foreach ($TicketData in $AllTickets) {
            $TicketId = $TicketData.Item.id
            $DebugLines += "TICKET #$TicketId ($($TicketData.Source))"
            $DebugLines += "-".PadRight(50, '-')
            
            # Dump all available fields
            $DebugLines += "AVAILABLE FIELDS:"
            $TicketData.Item.fields.PSObject.Properties | ForEach-Object {
                $FieldName = $_.Name
                $FieldValue = if ($_.Value -and $_.Value.ToString().Length -gt 0) { 
                    $_.Value.ToString().Substring(0, [Math]::Min(200, $_.Value.ToString().Length))
                } else { 
                    "[EMPTY]" 
                }
                $DebugLines += "  $FieldName = $FieldValue"
            }
            
            $DebugLines += ""
            $DebugLines += "WORK ITEM PROPERTIES:"
            $TicketData.Item.PSObject.Properties | ForEach-Object {
                if ($_.Name -ne "fields") {
                    $DebugLines += "  $($_.Name) = $($_.Value)"
                }
            }
            
            # Get comments and show raw comment data
            $DebugLines += ""
            $DebugLines += "FETCHING COMMENTS..."
            $Comments = Get-WorkItemComments -Config $Config -WorkItemId $TicketData.Item.id -TfsUrl $TfsUrl -ProjectName $ProjectName -Headers $Headers
            
            if ($Comments -and $Comments.Count -gt 0) {
                $DebugLines += "COMMENTS FOUND: $($Comments.Count)"
                for ($i = 0; $i -lt $Comments.Count; $i++) {
                    $Comment = $Comments[$i]
                    $DebugLines += "  Comment $($i+1):"
                    $DebugLines += "    Author: $($Comment.Author)"
                    $DebugLines += "    Date: $($Comment.Date)"
                    $CommentText = if ($Comment.Text -and $Comment.Text.Length -gt 0) { 
                        $Comment.Text.Substring(0, [Math]::Min(300, $Comment.Text.Length))
                    } else { 
                        "[NO TEXT]" 
                    }
                    $DebugLines += "    Text: $CommentText"
                }
            } else {
                $DebugLines += "NO COMMENTS FOUND"
            }
            
            # Run analysis but show what it produces
            $Priority = Get-PriorityLevel -Fields $TicketData.Item.fields -Source $TicketData.Source
            $Action = Get-ActionRecommendation -Fields $TicketData.Item.fields -Priority $Priority -Source $TicketData.Source
            $ContentAnalysis = Analyze-TicketContent -Fields $TicketData.Item.fields -Comments $Comments
            
            $DebugLines += ""
            $DebugLines += "ANALYSIS RESULTS:"
            $DebugLines += "  Priority: $($Priority.Level) (Score: $($Priority.Score))"
            $DebugLines += "  Reasons: $($Priority.Reasons -join ', ')"
            $DebugLines += "  Action: $Action"
            $DebugLines += "  Summary: $($ContentAnalysis.Summary)"
            $DebugLines += "  Key Points: $($ContentAnalysis.KeyPoints -join '; ')"
            $DebugLines += "  Decisions: $($ContentAnalysis.Decisions -join '; ')"
            $DebugLines += "  Next Steps: $($ContentAnalysis.NextSteps -join '; ')"
            
            $DebugLines += ""
            $DebugLines += "=".PadRight(80, '=')
            $DebugLines += ""
            
            $TicketData.Priority = $Priority
            $TicketData.Action = $Action
            $TicketData.ContentAnalysis = $ContentAnalysis
            $TicketData.Comments = $Comments
        }
        
        # Save debug file
        $DebugContent = $DebugLines -join "`n"
        $DebugContent | Out-File -FilePath $DebugPath -Encoding UTF8
        Write-ColorOutput "Debug data saved to: $DebugPath" "Success"
        
        # Group by priority
        $HighPriority = @($AllTickets | Where-Object { $_.Priority.Level -eq 'HIGH' })
        $MediumPriority = @($AllTickets | Where-Object { $_.Priority.Level -eq 'MEDIUM' })
        $LowPriority = @($AllTickets | Where-Object { $_.Priority.Level -eq 'LOW' })
        
        # Console output (always show)
        Write-Host ""
        Write-ColorOutput "SUMMARY" "Success"
        Write-Host "Total Tickets: $($AllTickets.Count)"
        Write-Host "  High Priority: $($HighPriority.Count)"
        Write-Host "  Medium Priority: $($MediumPriority.Count)"
        Write-Host "  Low Priority: $($LowPriority.Count)"
        Write-Host ""
        
        # Generate outputs based on configuration
        if ($SaveHtml -or $ShowInBrowser) {
            Save-HtmlSummary -Config $Config -AllTickets $AllTickets -Days $Days -TfsUrl $TfsUrl -ProjectName $ProjectName
        }
        
        if ($SaveText) {
            Save-TextSummary -Config $Config -AllTickets $AllTickets -Days $Days
        }
        
        if ($SendEmail -and $Config.SMTP_SERVER) {
            # Generate HTML content for email
            Save-HtmlSummary -Config $Config -AllTickets $AllTickets -Days $Days -TfsUrl $TfsUrl -ProjectName $ProjectName
            $HtmlPath = if ($Config.HTML_PATH) { $Config.HTML_PATH } else { "$env:USERPROFILE\Documents\TFS-Daily-Summary.html" }
            $HtmlContent = Get-Content $HtmlPath -Raw
            $Subject = "Daily TFS Ticket Summary - $($AllTickets.Count) tickets ($($HighPriority.Count) high priority)"
            Send-Office365Email -Config $Config -HtmlContent $HtmlContent -Subject $Subject
        }
        
        Write-Host ""
        Write-ColorOutput "Analysis complete!" "Success"
        
    } catch {
        Write-ColorOutput "Error analyzing tickets: $($_.Exception.Message)" "Error"
        Write-Host "Full error: $($_.Exception)"
    }
}

function Show-Help {
    Write-Host "TFS Ticket Analyzer with Multiple Output Options - Deltek Edition" -ForegroundColor Cyan
    Write-Host "No SMTP server setup required - choose your preferred output method!"
    Write-Host ""
    Write-Host "SETUP:" -ForegroundColor Yellow
    Write-Host "  .\tfs-ticket-analyzer-multi-output.ps1 setup         - Setup TFS connection" 
    Write-Host "  .\tfs-ticket-analyzer-multi-output.ps1 setup-output  - Choose output method"
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\tfs-ticket-analyzer-multi-output.ps1 [days]         - Use configured output method"
    Write-Host "  .\tfs-ticket-analyzer-multi-output.ps1 [days] -SaveHtml      - Save as HTML file"
    Write-Host "  .\tfs-ticket-analyzer-multi-output.ps1 [days] -ShowInBrowser - Open in browser"
    Write-Host "  .\tfs-ticket-analyzer-multi-output.ps1 [days] -SaveText      - Save as text file"
    Write-Host "  .\tfs-ticket-analyzer-multi-output.ps1 [days] -SendEmail     - Send via email"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\tfs-ticket-analyzer-multi-output.ps1               - Use configured method"
    Write-Host "  .\tfs-ticket-analyzer-multi-output.ps1 3 -SaveHtml   - Save last 3 days as HTML"
    Write-Host "  .\tfs-ticket-analyzer-multi-output.ps1 1 -ShowInBrowser - Open todays summary"
    Write-Host ""
    Write-Host "OUTPUT OPTIONS:" -ForegroundColor Yellow
    Write-Host "  HTML File - Professional web page saved to Documents"
    Write-Host "  Email - Via Office 365 (requires your email password)"
    Write-Host "  Text File - Simple text format saved to Documents"
    Write-Host "  Browser - Automatically opens HTML in your browser"
    Write-Host "  Console - Always shows summary in terminal"
}

# Main logic
switch ($Action.ToLower()) {
    'setup' {
        Setup-Configuration
    }
    'setup-output' {
        Setup-OutputConfiguration
    }
    'help' {
        Show-Help
    }
    { $_ -match '^\d+$' } {
        $Config = Load-Configuration
        Analyze-Tickets -Config $Config -Days ([int]$Action)
    }
    'analyze' {
        $Config = Load-Configuration
        Analyze-Tickets -Config $Config -Days $Days
    }
    default {
        if ($Action -match '^\d+$') {
            $Config = Load-Configuration
            Analyze-Tickets -Config $Config -Days ([int]$Action)
        } else {
            Write-ColorOutput "Invalid option: $Action" "Error"
            Write-Host "Use help for usage information."
        }
    }
}