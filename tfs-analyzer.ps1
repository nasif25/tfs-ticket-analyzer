# TFS Ticket Analyzer with Claude AI Integration
# Enhanced with AI-powered analysis using Claude via Azure DevOps MCP Server
# Supports both AI-enhanced and traditional analysis modes

param(
    [Parameter(Position = 0)]
    [string]$Action = "analyze",
    [Parameter(Position = 1)]
    [int]$TimeValue = 1,
    [switch]$Hours = $false,
    [switch]$Html = $false,
    [switch]$Email = $false,
    [switch]$Browser = $false,
    [switch]$Text = $false,
    [switch]$Claude = $false,
    [switch]$NoAI = $false,
    [switch]$Details = $false
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ConfigFile = "$ScriptDir\.config\.tfs-analyzer-config"
$ClaudeConfigFile = "$ScriptDir\.config\.tfs-analyzer-claude-config"

# Ensure .config directory exists
if (-not (Test-Path "$ScriptDir\.config")) {
    New-Item -ItemType Directory -Path "$ScriptDir\.config" -Force | Out-Null
}

# Colors for output
$Colors = @{
    Info    = "Cyan"
    Success = "Green" 
    Warning = "Yellow"
    Error   = "Red"
}

function Write-ColorOutput {
    param([string]$Message, [string]$Color)
    if (-not $Global:QuietMode) {
        Write-Host "[$($Color.ToUpper())] $Message" -ForegroundColor $Colors[$Color]
    }
}

function Write-DebugOutput {
    param([string]$Message, [switch]$ShowDetails = $false)
    # Global script-level variable $script:Details should be used
    if ($ShowDetails -or $script:Details -or $VerbosePreference -eq 'Continue') {
        Write-Host "[DEBUG] $Message" -ForegroundColor Magenta
    }
}

function Test-AzureCliAuthentication {
    try {
        Write-DebugOutput "Testing Azure CLI authentication..."
        $accountInfo = az account show --query '{name:name, tenantId:tenantId}' -o json 2>$null
        if ($accountInfo -and $accountInfo -ne "null" -and $accountInfo.Trim() -ne "") {
            $account = $accountInfo | ConvertFrom-Json
            Write-DebugOutput "Azure CLI authenticated as: $($account.name)"
            return $true
        }
        return $false
    } catch {
        Write-DebugOutput "Azure CLI authentication test failed: $($_.Exception.Message)"
        return $false
    }
}

function Test-ClaudeCodeAvailability {
    try {
        Write-DebugOutput "Testing Claude Code availability..."
        $claudeHelp = claude --help 2>$null
        if ($claudeHelp) {
            Write-DebugOutput "Claude Code CLI found"
            return $true
        }
        return $false
    } catch {
        Write-DebugOutput "Claude Code CLI not found: $($_.Exception.Message)"
        return $false
    }
}


function Setup-ClaudeConfiguration {
    Write-ColorOutput "Setting up Claude AI integration..." "Info"
    Write-Host "This will configure AI-powered ticket analysis with enhanced insights."
    Write-Host ""
    
    # Step 1: Test Claude Code availability
    Write-DebugOutput "Testing Claude Code availability..."
    $claudeAvailable = Test-ClaudeCodeAvailability
    if (-not $claudeAvailable) {
        Write-ColorOutput "[ERROR] Claude Code CLI not found. Please install Claude Code first:" "Error"
        Write-Host ""
        Write-Host "Installation Installation Steps:"
        Write-Host "1. Visit: https://claude.ai/code"
        Write-Host "2. Download and install Claude Code"
        Write-Host "3. Follow the setup instructions"
        Write-Host "4. Restart your terminal/PowerShell"
        Write-Host "5. Run this setup again: .\tfs-analyzer.ps1 setup-claude"
        Write-Host ""
        return $false
    }
    Write-ColorOutput "[OK] Claude Code CLI found" "Success"
    
    # Step 2: Load existing configuration
    try {
        $config = Load-Configuration
    } catch {
        Write-ColorOutput "[ERROR] Main configuration not found. Please run: .\tfs-analyzer.ps1 setup" "Error"
        return $false
    }
    
    Write-Host ""
    Write-ColorOutput "Claude AI Features Claude AI Features:" "Info"
    Write-Host "- Intelligent priority assessment with AI reasoning"
    Write-Host "- Smart content summarization and key point extraction"
    Write-Host "- Actionable recommendations for next steps"
    Write-Host "- Impact analysis and risk assessment"
    Write-Host "- Enhanced decision tracking from ticket history"
    Write-Host ""
    
    $enableClaude = Read-Host "Enable Claude AI analysis by default? (y/n)"
    $useClaudeByDefault = $enableClaude -eq "y" -or $enableClaude -eq "Y" -or $enableClaude -eq "yes"
    
    # Step 3: Configure authentication
    Write-Host ""
    Write-ColorOutput "Authentication Configuration Authentication Configuration:" "Info"
    Write-Host "Claude Code supports multiple authentication methods:"
    Write-Host "1. Azure CLI (Recommended) - Uses your current Azure login"
    Write-Host "2. Personal Access Token - Uses stored PAT from main config"
    Write-Host ""
    
    # Test available authentication methods
    $azureCliAuth = Test-AzureCliAuthentication
    $patAvailable = -not [string]::IsNullOrWhiteSpace($config.PAT)
    
    Write-Host "Authentication Status Authentication Status:"
    if ($azureCliAuth) {
        Write-ColorOutput "[OK] Azure CLI: Authenticated and ready" "Success"
    } else {
        Write-ColorOutput "[ERROR] Azure CLI: Not authenticated (run 'az login --allow-no-subscriptions')" "Warning"
    }
    
    if ($patAvailable) {
        Write-ColorOutput "[OK] PAT: Available from main configuration" "Success"
    } else {
        Write-ColorOutput "[ERROR] PAT: Not configured" "Warning"
    }
    
    Write-Host ""
    $authChoice = Read-Host "Choose primary authentication method (1 for Azure CLI, 2 for PAT)"
    $useAzureCli = $authChoice -eq "1"
    
    if ($useAzureCli -and -not $azureCliAuth) {
        Write-ColorOutput "[WARNING]  Azure CLI selected but not authenticated." "Warning"
        Write-Host "Please run: az login --allow-no-subscriptions"
        Write-Host ""
        $continueAnyway = Read-Host "Continue with PAT as fallback? (y/n)"
        if ($continueAnyway -ne "y" -and $continueAnyway -ne "Y") {
            Write-ColorOutput "Setup cancelled. Please run 'az login --allow-no-subscriptions' and try again." "Warning"
            return $false
        }
        $useAzureCli = $false
    }
    
    if (-not $useAzureCli -and -not $patAvailable) {
        Write-ColorOutput "[ERROR] No valid authentication method available." "Error"
        Write-Host "Please either:"
        Write-Host "1. Run 'az login --allow-no-subscriptions' to authenticate Azure CLI, or"
        Write-Host "2. Run '.\tfs-analyzer.ps1 setup' to configure PAT"
        return $false
    }
    
    # Step 4: Configure Azure DevOps Organization URL
    Write-Host ""
    Write-ColorOutput "Azure DevOps Configuration Azure DevOps Configuration:" "Info"
    $azureDevOpsOrgUrl = Read-Host "Enter your Azure DevOps Organization URL"
    
    if ([string]::IsNullOrWhiteSpace($azureDevOpsOrgUrl)) {
        Write-ColorOutput "[ERROR] Azure DevOps Organization URL is required for Claude AI integration." "Error"
        return $false
    }
    
    # Validate URL format
    try {
        $uri = [System.Uri]$azureDevOpsOrgUrl
        if ($uri.Scheme -ne "https") {
            Write-ColorOutput "[WARNING]  Warning: HTTPS is recommended for security" "Warning"
        }
    } catch {
        Write-ColorOutput "[ERROR] Invalid URL format. Please enter a valid Azure DevOps URL." "Error"
        return $false
    }
    
    # Step 5: Create Claude configuration
    Write-DebugOutput "Creating Claude configuration..."
    $claudeConfig = @{
        USE_CLAUDE_BY_DEFAULT = $useClaudeByDefault.ToString().ToLower()
        USE_AZURE_CLI = $useAzureCli.ToString().ToLower()
        CLAUDE_AVAILABLE = "true"
        AZURE_DEVOPS_ORG_URL = $azureDevOpsOrgUrl
    }
    
    # Save configuration
    $configLines = @()
    foreach ($key in $claudeConfig.Keys) {
        $configLines += "$key=$($claudeConfig[$key])"
    }
    $configLines -join "`n" | Out-File -FilePath $ClaudeConfigFile -Encoding UTF8
    Write-ColorOutput "[OK] Claude AI configuration saved" "Success"
    
    # Step 6: Create Claude Code MCP server configuration
    Write-DebugOutput "Setting up Claude Code MCP server configuration..."
    $mcpSuccess = Setup-ClaudeCodeMcpConfig -AzureDevOpsUrl $azureDevOpsOrgUrl -UseAzureCli $useAzureCli
    if (-not $mcpSuccess) {
        Write-ColorOutput "[WARNING]  Claude Code MCP configuration failed, but Claude AI is still configured" "Warning"
    }
    
    # Step 7: Run comprehensive verification
    Write-Host ""
    Write-ColorOutput "Running Configuration Verification Running Configuration Verification..." "Info"
    $verificationPassed = Test-ClaudeConfiguration
    
    if ($verificationPassed) {
        Write-Host ""
        Write-ColorOutput "[SUCCESS] Claude AI integration setup completed successfully!" "Success"
        Write-Host ""
        Write-Host "Next Steps Next Steps:"
        Write-Host "- Test with: .\tfs-analyzer.ps1 1 -Claude -Browser"
        Write-Host "- Use -Details flag for troubleshooting if needed"
        Write-Host "- Run 'test-auth' to verify authentication setup"
        Write-Host ""
        Write-Host "Ready! Claude AI is now ready to enhance your ticket analysis!"
    } else {
        Write-ColorOutput "[WARNING]  Setup completed with warnings. Some features may not work properly." "Warning"
        Write-Host ""
        Write-Host "Troubleshooting Tips  Troubleshooting Tips:"
        Write-Host "- Run: .\tfs-analyzer.ps1 test-claude"
        Write-Host "- Check authentication with: az login --allow-no-subscriptions"
        Write-Host "- Verify Claude Code installation"
        Write-Host "- Use -Details flag for debug information"
    }
    
    return $true
}

function Setup-ClaudeCodeMcpConfig {
    param(
        [string]$AzureDevOpsUrl,
        [bool]$UseAzureCli
    )
    
    Write-ColorOutput "Setting up Claude Code MCP server configuration..." "Info"
    
    $claudeCodeConfigPath = "$ScriptDir\.config\claude-code-config.json"
    
    $configContent = @"
{
    "mcpServers": {
        "azure-devops": {
            "command": "npx",
            "args": ["@anthropic/mcp-server-azure-devops"],
            "env": {
                "AZURE_DEVOPS_ORG_URL": "$AzureDevOpsUrl"
            }
        }
    }
}
"@
    
    $configContent | Out-File -FilePath $claudeCodeConfigPath -Encoding UTF8
    Write-ColorOutput "[OK] Claude Code MCP configuration created" "Success"
    Write-Host "- Configuration saved to: $claudeCodeConfigPath"
    Write-Host "- Azure DevOps Organization: $AzureDevOpsUrl"
    
    return $true
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
    param([hashtable]$Config, [array]$AllTickets, [int]$Days, [string]$TfsUrl, [string]$ProjectName, [bool]$ShowInBrowser = $false)
    
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
    Write-Host "DEBUG: Browser check: OPEN_BROWSER=$($Config.OPEN_BROWSER), ShowInBrowser=$ShowInBrowser" -ForegroundColor Yellow
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
                            $TextLines += "  - $KeyPoint"
                        }
                    }
                    
                    if ($Analysis.Decisions.Count -gt 0) {
                        $TextLines += "Recent Decisions:"
                        foreach ($Decision in $Analysis.Decisions) {
                            $TextLines += "  > $Decision"
                        }
                    }
                    
                    if ($Analysis.NextSteps.Count -gt 0) {
                        $TextLines += "Action Items:"
                        foreach ($NextStep in $Analysis.NextSteps) {
                            $TextLines += "  > $NextStep"
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
    Write-Host "This script will help you configure access to your TFS/Azure DevOps server."
    Write-Host ""
    
    $TfsUrl = Read-Host "Enter your TFS/Azure DevOps Organization URL (e.g., https://tfs.deltek.com/tfs/Deltek)"
    $ProjectName = Read-Host "Enter your Project Name (e.g., TIP)"
    
    Write-Host ""
    Write-ColorOutput "Choose your authentication method:" "Info"
    Write-Host "1. Azure CLI Authentication (Recommended) - Uses your current Azure login"
    Write-Host "2. Personal Access Token (PAT) - Uses stored token"
    Write-Host "3. Windows Authentication - For on-premise TFS only"
    $AuthChoice = Read-Host "Enter your choice (1, 2, or 3)"
    
    $UseWindowsAuth = $false
    $UseAzureCli = $false
    $Pat = ""
    
    switch ($AuthChoice) {
        "1" {
            Write-ColorOutput "Using Azure CLI Authentication" "Info"
            $UseAzureCli = $true
            
            # Test Azure CLI authentication
            $azureCliAuth = Test-AzureCliAuthentication
            if (-not $azureCliAuth) {
                Write-ColorOutput "Azure CLI not authenticated. Please run 'az login --allow-no-subscriptions' first." "Warning"
                $fallbackChoice = Read-Host "Do you want to: (1) Exit and run 'az login --allow-no-subscriptions', (2) Use PAT instead"
                if ($fallbackChoice -eq "2") {
                    $UseAzureCli = $false
                    Write-ColorOutput "Switching to PAT authentication..." "Info"
                } else {
                    Write-ColorOutput "Please run 'az login --allow-no-subscriptions' and run setup again." "Info"
                    return
                }
            } else {
                Write-ColorOutput "Azure CLI authentication verified!" "Success"
            }
        }
        "3" {
            $UseWindowsAuth = $true
            Write-ColorOutput "Using Windows Authentication" "Info"
        }
        default {
            Write-ColorOutput "Using PAT Authentication" "Info"
        }
    }
    
    if (-not $UseWindowsAuth -and -not $UseAzureCli) {
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
    
    # Save main configuration
    $ConfigText = "TFS_URL=$TfsUrl`nPROJECT_NAME=$ProjectName`nPAT=$Pat`nUSER_DISPLAY_NAME=$UserDisplayName`nUSE_WINDOWS_AUTH=$UseWindowsAuth`nUSE_AZURE_CLI=$UseAzureCli"
    $ConfigText | Out-File -FilePath $ConfigFile -Encoding UTF8
    
    Write-ColorOutput "Configuration saved!" "Success"
    
    # Ask about Claude integration
    Write-Host ""
    Write-ColorOutput "AI Enhancement Setup:" "Info"
    Write-Host "This analyzer can use Claude AI for enhanced ticket analysis."
    $setupClaude = Read-Host "Set up Claude AI integration? (y/n)"
    
    if ($setupClaude -eq "y" -or $setupClaude -eq "Y" -or $setupClaude -eq "yes") {
        Setup-ClaudeConfiguration
    } else {
        # Create minimal Claude config indicating it's disabled
        "USE_CLAUDE_BY_DEFAULT=false`nCLAUDE_AVAILABLE=false" | Out-File -FilePath $ClaudeConfigFile -Encoding UTF8
    }
    
    Write-Host ""
    Write-Host "Next step: Configure output preferences with: .\tfs-analyzer.ps1 setup-output"
}

function Load-Configuration {
    if (-not (Test-Path $ConfigFile)) {
        Write-ColorOutput "Configuration not found. Please run: .\tfs-analyzer.ps1 setup" "Error"
        exit 1
    }
    
    $Config = @{}
    Get-Content $ConfigFile | ForEach-Object {
        if ($_ -match '^(.+?)=(.*)$') {
            $Config[$matches[1]] = $matches[2]
        }
    }
    
    # Load Claude configuration if available
    if (Test-Path $ClaudeConfigFile) {
        Get-Content $ClaudeConfigFile | ForEach-Object {
            if ($_ -match '^(.+?)=(.*)$') {
                $Config[$matches[1]] = $matches[2]
            }
        }
    } else {
        # Default Claude settings if no config exists
        $Config['USE_CLAUDE_BY_DEFAULT'] = 'false'
        $Config['CLAUDE_AVAILABLE'] = 'false'
        $Config['USE_AZURE_CLI'] = 'false'
    }
    
    return $Config
}

function Load-ClaudeConfiguration {
    $claudeConfig = @{
        USE_CLAUDE_BY_DEFAULT = 'false'
        CLAUDE_AVAILABLE = 'false'
        USE_AZURE_CLI = 'false'
    }
    
    if (Test-Path $ClaudeConfigFile) {
        Get-Content $ClaudeConfigFile | ForEach-Object {
            if ($_ -match '^(.+?)=(.*)$') {
                $claudeConfig[$matches[1]] = $matches[2]
            }
        }
    }
    
    return $claudeConfig
}

function Invoke-ClaudeAnalysis {
    param(
        [hashtable]$Config,
        [string]$WorkItemId,
        [string]$ProjectName,
        [object]$WorkItemData
    )
    
    try {
        Write-DebugOutput "Starting Claude AI analysis for work item $WorkItemId"
        
        # Step 1: Verify Claude Code is available
        $claudeAvailable = Test-ClaudeCodeAvailability
        if (-not $claudeAvailable) {
            Write-ColorOutput "Claude Code CLI not available. Run setup-claude first." "Warning"
            return @{ Error = "Claude Code CLI not found. Run setup-claude first." }
        }
        
        # Step 2: Verify authentication
        $azureCliAuth = Test-AzureCliAuthentication
        $patAvailable = -not [string]::IsNullOrWhiteSpace($Config.PAT)
        
        if (-not $azureCliAuth -and -not $patAvailable) {
            Write-ColorOutput "No valid authentication method available for Claude analysis" "Warning"
            return @{ Error = "No valid authentication method available. Configure Azure CLI or PAT." }
        }
        
        # Set up environment for Azure DevOps MCP server
        if (-not $azureCliAuth -and $patAvailable) {
            Write-DebugOutput "Using PAT for Azure DevOps MCP server authentication"
            $env:AZURE_DEVOPS_PAT = $Config.PAT
        }
        
        Write-DebugOutput "Authentication verified for Claude analysis"
        
        # Create a temporary file with work item data for Claude to analyze
        $tempFile = [System.IO.Path]::GetTempFileName()
        $workItemJson = $WorkItemData | ConvertTo-Json -Depth 10
        $workItemJson | Out-File -FilePath $tempFile -Encoding UTF8
        
        Write-DebugOutput "Work item data saved to temp file: $tempFile"
        
        # Prepare Claude prompt for work item analysis
        $claudePrompt = @"
Analyze this TFS/Azure DevOps work item and provide:

1. **Priority Assessment** (HIGH/MEDIUM/LOW) with reasoning
2. **Content Summary** - Brief overview of the issue/task
3. **Key Points** - Important requirements, acceptance criteria, or technical details
4. **Recent Decisions** - Any decisions made based on comments/history
5. **Action Items** - Recommended next steps
6. **Impact Assessment** - Business and technical impact

Work Item Data:
{0}

Provide the analysis in a structured JSON format with the following keys:
- priorityLevel (HIGH/MEDIUM/LOW)
- priorityReasons (array of reasons)
- summary (string)
- keyPoints (array of strings)
- decisions (array of strings)
- actionItems (array of strings)
- impactAssessment (string)
"@
        
        $fullPrompt = $claudePrompt -f $workItemJson
        
        # Save prompt to temp file
        $promptFile = [System.IO.Path]::GetTempFileName()
        $fullPrompt | Out-File -FilePath $promptFile -Encoding UTF8
        
        Write-DebugOutput "Claude prompt saved to: $promptFile"
        
        # Execute Claude Code with the work item analysis prompt using stdin
        $claudeCommand = "claude"
        $claudeArgs = @(
            "--print"
            "--output-format", "json"
        )
        
        Write-DebugOutput "Executing Claude command: $claudeCommand $($claudeArgs -join ' ') < $promptFile"
        
        # Set timeout for Claude command (30 seconds)
        $timeoutSeconds = 30
        $job = Start-Job -ScriptBlock {
            param($cmd, $args, $inputFile)
            Get-Content $inputFile | & $cmd @args 2>&1
        } -ArgumentList $claudeCommand, $claudeArgs, $promptFile
        
        $claudeResult = $null
        if (Wait-Job $job -Timeout $timeoutSeconds) {
            $claudeResult = Receive-Job $job
            $exitCode = $job.State
        } else {
            Write-DebugOutput "Claude command timed out after $timeoutSeconds seconds"
            Stop-Job $job
            Remove-Job $job
            return @{ Error = "Claude command timed out after $timeoutSeconds seconds" }
        }
        
        Remove-Job $job
        
        if ($exitCode -eq 'Completed' -and $claudeResult) {
            Write-DebugOutput "Claude analysis completed successfully"
            
            # Parse Claude response with error handling
            try {
                # Handle potential multi-line JSON response
                $jsonResponse = $claudeResult -join "`n"
                
                # Try to extract JSON if embedded in other text
                if ($jsonResponse -match '\{[\s\S]*\}') {
                    $jsonResponse = $matches[0]
                }
                
                $claudeAnalysis = $jsonResponse | ConvertFrom-Json
                Write-DebugOutput "Claude analysis parsed successfully"
                
                # Validate required fields and provide defaults if missing
                if (-not $claudeAnalysis.priorityLevel) {
                    $claudeAnalysis | Add-Member -NotePropertyName 'priorityLevel' -NotePropertyValue 'MEDIUM'
                }
                if (-not $claudeAnalysis.priorityReasons) {
                    $claudeAnalysis | Add-Member -NotePropertyName 'priorityReasons' -NotePropertyValue @('AI analysis')
                }
                if (-not $claudeAnalysis.summary) {
                    $claudeAnalysis | Add-Member -NotePropertyName 'summary' -NotePropertyValue 'AI-generated summary not available'
                }
                
                # Clean up temp files
                Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
                Remove-Item -Path $promptFile -ErrorAction SilentlyContinue
                
                return $claudeAnalysis
                
            } catch {
                Write-DebugOutput "Error parsing Claude response: $($_.Exception.Message)"
                Write-DebugOutput "Claude raw response: $claudeResult"
                
                # Attempt to extract key information using regex if JSON parsing fails
                try {
                    $fallbackAnalysis = @{}
                    
                    # Extract priority level
                    if ($claudeResult -match '(?i)(HIGH|MEDIUM|LOW)') {
                        $fallbackAnalysis.priorityLevel = $matches[1].ToUpper()
                    } else {
                        $fallbackAnalysis.priorityLevel = 'MEDIUM'
                    }
                    
                    # Extract summary (look for summary-like content)
                    if ($claudeResult -match '(?i)summary[:\s]*([^\n\r]{20,200})') {
                        $fallbackAnalysis.summary = $matches[1].Trim()
                    }
                    
                    $fallbackAnalysis.priorityReasons = @('AI analysis (fallback parsing)')
                    
                    Write-DebugOutput "Used fallback parsing for Claude response"
                    return $fallbackAnalysis
                } catch {
                    Write-DebugOutput "Fallback parsing also failed: $($_.Exception.Message)"
                    return @{ Error = "Claude response parsing failed. Claude output: $($claudeResult -join ' ')" }
                }
            }
        } else {
            Write-DebugOutput "Claude command failed or returned no result"
            Write-DebugOutput "Claude output: $claudeResult"
            $errorMsg = if ($claudeResult) { "Claude command failed. Output: $($claudeResult -join ' ')" } else { "Claude command returned no result" }
            return @{ Error = $errorMsg }
        }
        
        # Clean up temp files
        Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
        Remove-Item -Path $promptFile -ErrorAction SilentlyContinue
        
        return @{ Error = "Claude analysis completed but no valid result was produced" }
        
    } catch {
        Write-DebugOutput "Error in Claude analysis: $($_.Exception.Message)"
        return @{ Error = "Claude analysis exception: $($_.Exception.Message)" }
    }
}

function Get-EnhancedWorkItemAnalysis {
    param(
        [hashtable]$Config,
        [object]$WorkItemData,
        [array]$Comments,
        [string]$Source,
        [bool]$UseClaude = $false
    )
    
    $analysis = @{
        Priority = $null
        Action = ""
        ContentAnalysis = $null
        Enhanced = $false
    }
    
    # Ensure Comments is an array (handle null case)
    if (-not $Comments) {
        $Comments = @()
    }
    
    # Always get traditional analysis as fallback
    try {
        $traditionalPriority = Get-PriorityLevel -Fields $WorkItemData.fields -Source $Source
        $traditionalAction = Get-ActionRecommendation -Fields $WorkItemData.fields -Priority $traditionalPriority -Source $Source
        $traditionalContent = Analyze-TicketContent -Fields $WorkItemData.fields -Comments $Comments
    } catch {
        Write-DebugOutput "Error in traditional analysis: $($_.Exception.Message)"
        # Provide minimal fallback analysis
        $traditionalPriority = @{ Level = 'MEDIUM'; Score = 5; Reasons = @('Analysis error') }
        $traditionalAction = "Review this work item"
        $traditionalContent = @{ Summary = 'Analysis unavailable'; KeyPoints = @(); Decisions = @(); NextSteps = @() }
    }
    
    $analysis.Priority = $traditionalPriority
    $analysis.Action = $traditionalAction
    $analysis.ContentAnalysis = $traditionalContent
    
    # Try Claude analysis if requested and available
    if ($UseClaude -and $Config.CLAUDE_AVAILABLE -eq 'true') {
        Write-DebugOutput "Attempting Claude analysis..."
        
        # Retry mechanism for Claude analysis
        $maxRetries = 2
        $claudeAnalysis = $null
        $claudeError = $null
        
        for ($retry = 0; $retry -lt $maxRetries -and -not $claudeAnalysis; $retry++) {
            if ($retry -gt 0) {
                Write-DebugOutput "Retrying Claude analysis (attempt $($retry + 1)/$maxRetries)..."
                Start-Sleep -Seconds 2
            }
            
            try {
                $claudeResult = Invoke-ClaudeAnalysis -Config $Config -WorkItemId $WorkItemData.id -ProjectName $Config.PROJECT_NAME -WorkItemData $WorkItemData
                if ($claudeResult -and $claudeResult.Error) {
                    $claudeError = $claudeResult.Error
                    Write-DebugOutput "Claude analysis attempt $($retry + 1) returned error: $claudeError"
                } else {
                    $claudeAnalysis = $claudeResult
                }
            } catch {
                $claudeError = "Exception: $($_.Exception.Message)"
                Write-DebugOutput "Claude analysis attempt $($retry + 1) failed: $claudeError"
                if ($retry -eq $maxRetries - 1) {
                    Write-DebugOutput "All Claude analysis attempts failed"
                }
            }
        }
        
        if ($claudeAnalysis -and -not $claudeAnalysis.Error) {
            Write-DebugOutput "Claude analysis successful, enhancing traditional analysis..."
            
            try {
                # Enhance priority analysis with Claude insights
                if ($claudeAnalysis.priorityLevel) {
                    $analysis.Priority.Level = $claudeAnalysis.priorityLevel
                    if ($claudeAnalysis.priorityReasons -and $claudeAnalysis.priorityReasons.Count -gt 0) {
                        $analysis.Priority.Reasons = $claudeAnalysis.priorityReasons
                    }
                }
                
                # Enhance content analysis with Claude insights
                if ($claudeAnalysis.summary) {
                    $analysis.ContentAnalysis.Summary = $claudeAnalysis.summary
                }
                if ($claudeAnalysis.keyPoints -and $claudeAnalysis.keyPoints.Count -gt 0) {
                    $analysis.ContentAnalysis.KeyPoints = $claudeAnalysis.keyPoints
                }
                if ($claudeAnalysis.decisions -and $claudeAnalysis.decisions.Count -gt 0) {
                    $analysis.ContentAnalysis.Decisions = $claudeAnalysis.decisions
                }
                if ($claudeAnalysis.actionItems -and $claudeAnalysis.actionItems.Count -gt 0) {
                    $analysis.ContentAnalysis.NextSteps = $claudeAnalysis.actionItems
                }
                
                # Enhanced action recommendation
                if ($claudeAnalysis.actionItems -and $claudeAnalysis.actionItems.Count -gt 0) {
                    $analysis.Action = $claudeAnalysis.actionItems[0]  # Use first action item as primary recommendation
                }
                
                # Add impact assessment if available
                if ($claudeAnalysis.impactAssessment) {
                    $analysis.ContentAnalysis.ImpactAssessment = $claudeAnalysis.impactAssessment
                }
                
                $analysis.Enhanced = $true
                Write-DebugOutput "Analysis enhanced with Claude AI insights"
                
            } catch {
                Write-DebugOutput "Error applying Claude analysis enhancements: $($_.Exception.Message)"
                Write-DebugOutput "Falling back to traditional analysis"
            }
        } else {
            Write-DebugOutput "Claude analysis failed after all attempts, using traditional analysis"
            Write-ColorOutput "Claude analysis failed - using traditional analysis as backup" "Warning"
            # Store the Claude error for later reporting
            if ($claudeError) {
                $analysis.ClaudeError = $claudeError
            }
        }
    }
    
    return $analysis
}

function Invoke-TfsRestMethod {
    param(
        [string]$Uri,
        [hashtable]$Config,
        [string]$Method = "GET",
        [string]$Body = $null
    )
    
    $Headers = @{ 'Content-Type' = 'application/json' }
    
    # Check authentication method and call accordingly
    if ($Config.USE_WINDOWS_AUTH -eq 'True') {
        Write-DebugOutput "Making request with Windows authentication"
        if ($Body) {
            return Invoke-RestMethod -Uri $Uri -Method $Method -Body $Body -Headers $Headers -UseDefaultCredentials
        } else {
            return Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers -UseDefaultCredentials
        }
    }
    
    # Check if Azure CLI is authenticated (for Azure AD integrated TFS)
    try {
        $accountInfo = az account show 2>$null | ConvertFrom-Json
        if ($accountInfo -and $accountInfo.user -and $accountInfo.user.name) {
            Write-DebugOutput "Making request with Azure CLI authenticated credentials"
            if ($Body) {
                return Invoke-RestMethod -Uri $Uri -Method $Method -Body $Body -Headers $Headers -UseDefaultCredentials
            } else {
                return Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers -UseDefaultCredentials
            }
        }
    } catch {
        Write-DebugOutput "Azure CLI check exception: $($_.Exception.Message)"
    }
    
    # Fallback to PAT authentication
    if ($Config.PAT -and $Config.PAT.Trim() -ne "") {
        Write-DebugOutput "Making request with PAT authentication"
        $AuthString = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($Config.PAT)"))
        $Headers['Authorization'] = "Basic $AuthString"
        if ($Body) {
            return Invoke-RestMethod -Uri $Uri -Method $Method -Body $Body -Headers $Headers
        } else {
            return Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers
        }
    }
    
    throw "No valid authentication method available"
}

function Get-Headers {
    param([hashtable]$Config)
    
    if ($Config.USE_WINDOWS_AUTH -eq 'True') {
        Write-DebugOutput "Using Windows authentication"
        return @{ 'Content-Type' = 'application/json' }
    } 
    
    # Check if Azure CLI is authenticated (for Azure AD integrated TFS)
    Write-DebugOutput "Checking Azure CLI authentication status..."
    try {
        $accountInfo = az account show 2>$null | ConvertFrom-Json
        if ($accountInfo -and $accountInfo.user -and $accountInfo.user.name) {
            Write-DebugOutput "Azure CLI is authenticated as: $($accountInfo.user.name)"
            Write-DebugOutput "Using Azure CLI authenticated Windows credentials"
            return @{ 'Content-Type' = 'application/json' }
        } else {
            Write-DebugOutput "Azure CLI not authenticated"
        }
    } catch {
        Write-DebugOutput "Azure CLI check exception: $($_.Exception.Message)"
    }
    
    # Fallback to PAT authentication
    Write-DebugOutput "Attempting PAT authentication..."
    if ($Config.PAT -and $Config.PAT.Trim() -ne "") {
        Write-DebugOutput "Using PAT authentication"
        $AuthString = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($Config.PAT)"))
        return @{
            'Content-Type' = 'application/json'
            'Authorization' = "Basic $AuthString"
        }
    } else {
        Write-DebugOutput "No PAT configured in config"
    }
    
    # No authentication method available
    Write-ColorOutput "[ERROR] No valid authentication method available." "Error"
    Write-ColorOutput "Azure CLI test result was: '$tokenResult'" "Error"
    Write-ColorOutput "Please run 'az login --allow-no-subscriptions' or configure a PAT during setup." "Error"
    throw "No valid authentication method available"
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
    param([hashtable]$Config, [string]$WorkItemId, [string]$TfsUrl, [string]$ProjectName)
    
    try {
        # Try the comments API first (newer TFS versions)
        $CommentsUrl = "$TfsUrl/$ProjectName/_apis/wit/workItems/$WorkItemId/comments?api-version=6.0"
        $CommentsResponse = Invoke-TfsRestMethod -Uri $CommentsUrl -Config $Config
        
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
            $HistoryResponse = Invoke-TfsRestMethod -Uri $HistoryUrl -Config $Config
            
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
            if ($Content -match '[--*]\s+' -or $Content -match '\d+\.\s+' -or $Content -match '\n\s*[--*\d]') {
                # Handle structured lists/bullet points
                $Points = @()
                
                # Split by various list indicators
                $ListItems = $Content -split '[--*]\s+|\d+\.\s+|\n\s*[--*\d]\s*' | Where-Object { 
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
    param(
        [hashtable]$Config,
        [int]$TimeValue,
        [bool]$UseHours = $false,
        [switch]$Html,
        [switch]$Browser,
        [switch]$Text,
        [switch]$Email,
        [switch]$Claude,
        [switch]$Details,
        [switch]$NoAI
    )

    # Set script-level variable for debug output
    $script:Details = $Details

    # Determine Claude usage
    $shouldUseClaude = $false
    if ($Claude) {
        $shouldUseClaude = $true
        Write-DebugOutput "Claude usage requested via parameter"
    } elseif ($NoAI) {
        $shouldUseClaude = $false
        Write-DebugOutput "Claude usage disabled via parameter"
    } elseif ($Config.USE_CLAUDE_BY_DEFAULT -eq 'true') {
        $shouldUseClaude = $true
        Write-DebugOutput "Claude usage enabled by default configuration"
    }
    
    if ($shouldUseClaude -and $Config.CLAUDE_AVAILABLE -ne 'true') {
        Write-ColorOutput "Claude requested but not available. Run setup to configure Claude integration." "Warning"
        $shouldUseClaude = $false
    }
    
    try {
        $Headers = Get-Headers -Config $Config
    } catch {
        Write-ColorOutput "Authentication setup failed: $($_.Exception.Message)" "Error"
        return
    }
    
    $ProjectName = $Config.PROJECT_NAME
    $TfsUrl = $Config.TFS_URL
    $UserDisplayName = $Config.USER_DISPLAY_NAME

    # Calculate the time period
    $timeUnit = if ($UseHours) { "hour(s)" } else { "day(s)" }
    $timeDescription = "$TimeValue $timeUnit"

    Write-ColorOutput "Analyzing TFS tickets for the last $timeDescription..." "Info"
    Write-Host "Project: $ProjectName"
    Write-Host "User: $UserDisplayName"
    
    if ($shouldUseClaude) {
        Write-ColorOutput "AI Enhancement: Claude AI analysis enabled" "Info"
    } else {
        Write-ColorOutput "Analysis Mode: Traditional analysis" "Info"
    }
    
    $authMethod = if ($Config.USE_AZURE_CLI -eq 'true') { "Azure CLI" } elseif ($Config.USE_WINDOWS_AUTH -eq 'true') { "Windows Auth" } else { "PAT" }
    Write-Host "Authentication: $authMethod"
    
    # Determine output method from parameters or config
    if ($Html -or $Browser -or $Text -or $Email) {
        # Use parameter switches
    } elseif ($Config.OUTPUT_METHOD) {
        # Use configured method
        switch ($Config.OUTPUT_METHOD) {
            "HTML" { $Html = $true }
            "EMAIL" { $Email = $true }
            "BOTH" { $Html = $true; $Email = $true }
            "TEXT" { $Text = $true }
            "BROWSER" { $Html = $true; $Browser = $true }
        }
    }
    
    Write-Host ""

    # Calculate the start date for the query
    if ($UseHours) {
        $startDate = (Get-Date).AddHours(-$TimeValue).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $queryTimeFilter = "[System.ChangedDate] >= '$startDate'"
    } else {
        # Use TFS-native @Today - Days syntax for better performance
        $queryTimeFilter = "[System.ChangedDate] >= @Today - $TimeValue"
    }

    # Query 1: Assigned tickets - Use basic fields to avoid compatibility issues
    $AssignedQuery = @{
        query = "SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType], [System.AssignedTo], [System.ChangedDate], [System.Description], [System.Tags] FROM WorkItems WHERE [System.TeamProject] = '$ProjectName' AND [System.AssignedTo] = @Me AND $queryTimeFilter ORDER BY [System.ChangedDate] DESC"
    } | ConvertTo-Json

    # Query 2: @Mentioned tickets - Use basic fields to avoid compatibility issues
    $mentionQueryString = @"
SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType], [System.AssignedTo], [System.ChangedDate], [System.Description], [System.Tags] FROM WorkItems WHERE [System.TeamProject] = '$ProjectName' AND [System.History] CONTAINS WORDS '@$UserDisplayName' AND $queryTimeFilter ORDER BY [System.ChangedDate] DESC
"@
    $MentionQuery = @{
        query = $mentionQueryString
    } | ConvertTo-Json
    
    $AllTickets = @()
    
    try {
        # Get assigned tickets
        Write-ColorOutput "Fetching assigned tickets..." "Info"
        $AssignedResponse = Invoke-TfsRestMethod -Uri "$TfsUrl/$ProjectName/_apis/wit/wiql?api-version=6.0" -Method Post -Body $AssignedQuery -Config $Config
        
        if ($AssignedResponse.workItems -and $AssignedResponse.workItems.Count -gt 0) {
            $AssignedIds = ($AssignedResponse.workItems | ForEach-Object { $_.id }) -join ','
            $AssignedDetails = Invoke-TfsRestMethod -Uri "$TfsUrl/$ProjectName/_apis/wit/workItems?ids=$AssignedIds`&api-version=6.0" -Config $Config
            
            foreach ($Item in $AssignedDetails.value) {
                $AllTickets += @{
                    Item = $Item
                    Source = "Assigned"
                }
            }
        }
        
        # Get @mentioned tickets
        Write-ColorOutput "Fetching @mentioned tickets..." "Info"
        $MentionResponse = Invoke-TfsRestMethod -Uri "$TfsUrl/$ProjectName/_apis/wit/wiql?api-version=6.0" -Method Post -Body $MentionQuery -Config $Config
        
        if ($MentionResponse.workItems -and $MentionResponse.workItems.Count -gt 0) {
            $MentionIds = ($MentionResponse.workItems | ForEach-Object { $_.id }) -join ','
            $MentionDetails = Invoke-TfsRestMethod -Uri "$TfsUrl/$ProjectName/_apis/wit/workItems?ids=$MentionIds`&api-version=6.0" -Config $Config
            
            foreach ($Item in $MentionDetails.value) {
                $ExistingItem = $AllTickets | Where-Object { $_.Item.id -eq $Item.id }
                if ($ExistingItem) {
                    $ExistingItem.Source = "Assigned `& @Mentioned"
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
        $analysisType = if ($shouldUseClaude) { "AI-enhanced" } else { "traditional" }
        Write-ColorOutput "Performing $analysisType ticket analysis..." "Info"
        if ($shouldUseClaude) {
            Write-ColorOutput "Claude AI will analyze each ticket for enhanced insights..." "Info"
            Write-Host "  [INFO] This may take a few minutes depending on ticket count and complexity" -ForegroundColor Gray
        }
        
        # Create debug file for raw data analysis
        $DebugPath = "$env:USERPROFILE\Documents\TFS-Debug-Data.txt"
        $DebugLines = @()
        $DebugLines += "=".PadRight(80, '=')
        $DebugLines += "TFS TICKET ANALYZER - DEBUG DATA"
        $DebugLines += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $DebugLines += "Total Tickets Found: $($AllTickets.Count)"
        $DebugLines += "=".PadRight(80, '=')
        $DebugLines += ""
        
        $ticketCounter = 0
        foreach ($TicketData in $AllTickets) {
            $TicketId = $TicketData.Item.id
            $ticketCounter++
            
            # Show progress for AI analysis
            if ($shouldUseClaude) {
                Write-Host "  [AI] Analyzing ticket #$TicketId ($ticketCounter/$($AllTickets.Count))..." -ForegroundColor Cyan -NoNewline
            }
            
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
            $Comments = Get-WorkItemComments -Config $Config -WorkItemId $TicketData.Item.id -TfsUrl $TfsUrl -ProjectName $ProjectName
            
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
            
            # Run enhanced analysis (Claude or traditional)
            $enhancedAnalysis = Get-EnhancedWorkItemAnalysis -Config $Config -WorkItemData $TicketData.Item -Comments $Comments -Source $TicketData.Source -UseClaude $shouldUseClaude
            
            # Show completion for AI analysis
            if ($shouldUseClaude) {
                Write-Host " Done" -ForegroundColor Green
            }
            
            $Priority = $enhancedAnalysis.Priority
            $Action = $enhancedAnalysis.Action
            $ContentAnalysis = $enhancedAnalysis.ContentAnalysis
            
            $DebugLines += ""
            $DebugLines += "ANALYSIS RESULTS:"
            $DebugLines += "  Analysis Type: $(if ($enhancedAnalysis.Enhanced) { 'AI-Enhanced (Claude)' } else { 'Traditional' })"
            $DebugLines += "  Priority: $($Priority.Level) (Score: $($Priority.Score))"
            $DebugLines += "  Reasons: $($Priority.Reasons -join ', ')"
            $DebugLines += "  Action: $Action"
            $DebugLines += "  Summary: $($ContentAnalysis.Summary)"
            $DebugLines += "  Key Points: $($ContentAnalysis.KeyPoints -join '; ')"
            $DebugLines += "  Decisions: $($ContentAnalysis.Decisions -join '; ')"
            $DebugLines += "  Next Steps: $($ContentAnalysis.NextSteps -join '; ')"
            if ($ContentAnalysis.ImpactAssessment) {
                $DebugLines += "  Impact: $($ContentAnalysis.ImpactAssessment)"
            }
            
            $DebugLines += ""
            $DebugLines += "=".PadRight(80, '=')
            $DebugLines += ""
            
            $TicketData.Priority = $Priority
            $TicketData.Action = $Action
            $TicketData.ContentAnalysis = $ContentAnalysis
            $TicketData.Comments = $Comments
            $TicketData.Enhanced = $enhancedAnalysis.Enhanced
        }
        
        # Show completion message for AI analysis
        if ($shouldUseClaude) {
            Write-Host ""
            Write-ColorOutput "Claude AI analysis completed for all $($AllTickets.Count) tickets!" "Success"
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
        Write-Host "DEBUG: Output parameters: Html=$Html, Browser=$Browser" -ForegroundColor Yellow
        if ($Html -or $Browser) {
            Save-HtmlSummary -Config $Config -AllTickets $AllTickets -Days $Days -TfsUrl $TfsUrl -ProjectName $ProjectName -ShowInBrowser $Browser
        }

        if ($Text) {
            Save-TextSummary -Config $Config -AllTickets $AllTickets -Days $Days
        }

        if ($Email -and $Config.SMTP_SERVER) {
            # Generate HTML content for email
            Save-HtmlSummary -Config $Config -AllTickets $AllTickets -Days $Days -TfsUrl $TfsUrl -ProjectName $ProjectName
            $HtmlPath = if ($Config.HTML_PATH) { $Config.HTML_PATH } else { "$env:USERPROFILE\Documents\TFS-Daily-Summary.html" }
            $HtmlContent = Get-Content $HtmlPath -Raw
            $Subject = "Daily TFS Ticket Summary - $($AllTickets.Count) tickets ($($HighPriority.Count) high priority)"
            Send-Office365Email -Config $Config -HtmlContent $HtmlContent -Subject $Subject
        }
        
        Write-Host ""
        Write-ColorOutput "Analysis complete!" "Success"
        
        # Show analysis summary
        $enhancedCount = ($AllTickets | Where-Object { $_.Enhanced -eq $true }).Count
        if ($shouldUseClaude -and $enhancedCount -gt 0) {
            Write-ColorOutput "AI Enhancement: $enhancedCount/$($AllTickets.Count) tickets analyzed with Claude AI" "Success"
        } elseif ($shouldUseClaude) {
            Write-ColorOutput "AI Enhancement: Claude analysis was attempted but fell back to traditional analysis" "Warning"
            
            # Show specific Claude error reasons
            $claudeErrors = @()
            $AllTickets | Where-Object { $_.ClaudeError } | ForEach-Object {
                if ($claudeErrors -notcontains $_.ClaudeError) {
                    $claudeErrors += $_.ClaudeError
                }
            }
            
            if ($claudeErrors.Count -gt 0) {
                Write-Host ""
                Write-ColorOutput "Claude Analysis Failure Reasons:" "Warning"
                $claudeErrors | ForEach-Object {
                    Write-Host "  - $_" -ForegroundColor Yellow
                }
            }
        }
        
    } catch {
        Write-ColorOutput "Error analyzing tickets: $($_.Exception.Message)" "Error"
        Write-Host "Full error: $($_.Exception)"
    }
}

function Show-Help {
    Write-Host "TFS Ticket Analyzer with Claude AI Integration - Enhanced Edition" -ForegroundColor Cyan
    Write-Host "AI-powered ticket analysis with multiple output options and authentication methods!"
    Write-Host ""
    Write-Host "SETUP:" -ForegroundColor Yellow
    Write-Host "  .\tfs-analyzer.ps1 setup         - Setup TFS connection and authentication" 
    Write-Host "  .\tfs-analyzer.ps1 setup-output  - Choose output method"
    Write-Host "  .\tfs-analyzer.ps1 setup-claude  - Setup Claude AI integration"
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\tfs-analyzer.ps1 [days]                    - Use configured settings"
    Write-Host "  .\tfs-analyzer.ps1 [days] -Claude             - Force Claude AI analysis"
    Write-Host "  .\tfs-analyzer.ps1 [days] -NoAI               - Use traditional analysis only"
    Write-Host "  .\tfs-analyzer.ps1 [days] -Html               - Save as HTML file"
    Write-Host "  .\tfs-analyzer.ps1 [days] -Browser            - Open in browser"
    Write-Host "  .\tfs-analyzer.ps1 [days] -Text               - Save as text file"
    Write-Host "  .\tfs-analyzer.ps1 [days] -Email              - Send via email"
    Write-Host "  .\tfs-analyzer.ps1 [days] -Details            - Enable detailed debug output"
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\tfs-analyzer.ps1                           - Use configured method"
    Write-Host "  .\tfs-analyzer.ps1 3 -Claude -Html            - AI analysis for 3 days, save HTML"
    Write-Host "  .\tfs-analyzer.ps1 1 -Browser                - Open today's summary"
    Write-Host "  .\tfs-analyzer.ps1 7 -NoAI -Details          - Traditional analysis with detailed output"
    Write-Host ""
    Write-Host "AUTHENTICATION METHODS:" -ForegroundColor Yellow
    Write-Host "  Azure CLI (Recommended) - Uses current Azure login (az login --allow-no-subscriptions)"
    Write-Host "  Personal Access Token   - Uses stored PAT for authentication"
    Write-Host "  Windows Authentication  - Uses current Windows credentials (on-premise only)"
    Write-Host ""
    Write-Host "AI ENHANCEMENT:" -ForegroundColor Yellow
    Write-Host "  Claude AI provides enhanced analysis including:"
    Write-Host "  - Intelligent priority assessment with detailed reasoning"
    Write-Host "  - Smart content summarization and key point extraction"
    Write-Host "  - Action recommendations and impact analysis"
    Write-Host "  - Decision tracking from comments and history"
    Write-Host ""
    Write-Host "OUTPUT OPTIONS:" -ForegroundColor Yellow
    Write-Host "  HTML File - Professional web page with AI insights"
    Write-Host "  Email - Via Office 365 with enhanced analysis"
    Write-Host "  Text File - Structured text format with AI summaries"
    Write-Host "  Browser - Automatically opens HTML with full analysis"
    Write-Host "  Console - Always shows summary in terminal"
}

function Test-ClaudeConfiguration {
    Write-ColorOutput "Testing Claude AI Configuration..." "Info"
    Write-Host ""
    
    # Step 1: Check if basic configuration exists
    if (-not (Test-Path $ConfigFile)) {
        Write-ColorOutput "[WARNING] No basic configuration found." "Warning"
        Write-Host "You need to run the initial setup first."
        Write-Host ""
        $setupBasic = Read-Host "Would you like to run the basic setup now? (y/n)"
        if ($setupBasic -eq 'y' -or $setupBasic -eq 'Y') {
            Setup-Configuration
            return
        } else {
            Write-ColorOutput "[ERROR] Cannot test Claude without basic configuration." "Error"
            return
        }
    }
    
    $Config = Load-Configuration
    Write-ColorOutput "[OK] Basic configuration found" "Success"
    
    # Step 2: Test authentication availability
    Write-Host ""
    Write-ColorOutput "Checking Authentication..." "Info"
    
    $azAuthWorking = $false
    $patAvailable = $false
    
    # Test Azure CLI authentication status
    try {
        $accountInfo = az account show 2>$null | ConvertFrom-Json
        if ($accountInfo -and $accountInfo.user -and $accountInfo.user.name) {
            Write-ColorOutput "[OK] Azure CLI is authenticated as $($accountInfo.user.name)" "Success"
            $azAuthWorking = $true
        }
    } catch {
        Write-DebugOutput "Azure CLI test failed: $($_.Exception.Message)"
    }
    
    # Test Windows Authentication
    $windowsAuthAvailable = $false
    if ($Config.USE_WINDOWS_AUTH -eq 'True') {
        Write-ColorOutput "[OK] Windows Authentication is enabled" "Success"
        $windowsAuthAvailable = $true
    }
    
    # Test PAT availability
    if ($Config.PAT -and $Config.PAT.Trim() -ne "") {
        Write-ColorOutput "[OK] Personal Access Token is configured" "Success"
        $patAvailable = $true
    }
    
    # If no authentication method is available, guide user to set it up
    if (-not $azAuthWorking -and -not $patAvailable -and -not $windowsAuthAvailable) {
        Write-ColorOutput "[WARNING] No authentication method is available!" "Warning"
        Write-Host ""
        Write-Host "AUTHENTICATION SETUP REQUIRED:"
        Write-Host "You need at least one authentication method to use Claude AI."
        Write-Host ""
        
        if ($isAzureDevOps) {
            Write-Host "OPTION 1 (RECOMMENDED): Azure CLI"
            Write-Host "  1. Run: az login --allow-no-subscriptions"
            Write-Host "  2. Follow the browser authentication prompts"
            Write-Host "  3. Come back and run: .\tfs-analyzer.ps1 test-claude"
            Write-Host ""
            Write-Host "OPTION 2: Personal Access Token (PAT)"
            Write-Host "  1. Run: .\tfs-analyzer.ps1 setup"
            Write-Host "  2. Choose to configure PAT when prompted"
            Write-Host "  3. Come back and run: .\tfs-analyzer.ps1 test-claude"
            Write-Host ""
            
            $authChoice = Read-Host "Would you like to set up Azure CLI authentication now? (y/n)"
            if ($authChoice -eq 'y' -or $authChoice -eq 'Y') {
                Write-Host ""
                Write-ColorOutput "Starting Azure CLI authentication..." "Info"
                Write-Host "This will open your browser for authentication..."
                
                try {
                    $azResult = Start-Process "az" -ArgumentList "login", "--allow-no-subscriptions" -NoNewWindow -Wait -PassThru
                    if ($azResult.ExitCode -eq 0) {
                        Write-ColorOutput "[OK] Azure CLI authentication completed!" "Success"
                        Write-Host "Run 'test-claude' again to verify the setup."
                    } else {
                        Write-ColorOutput "[ERROR] Azure CLI authentication failed." "Error"
                        Write-Host "You can try the PAT setup instead: .\tfs-analyzer.ps1 setup"
                    }
                } catch {
                    Write-ColorOutput "[ERROR] Could not start Azure CLI authentication: $($_.Exception.Message)" "Error"
                    Write-Host "Please install Azure CLI or run: .\tfs-analyzer.ps1 setup"
                }
            }
        } else {
            Write-Host "FOR ON-PREMISES TFS:"
            Write-Host "Personal Access Token (PAT) is required for on-premises TFS."
            Write-Host ""
            Write-Host "OPTION 1: Personal Access Token (PAT)"
            Write-Host "  1. Run: .\tfs-analyzer.ps1 setup"
            Write-Host "  2. Choose to configure PAT when prompted"
            Write-Host "  3. Come back and run: .\tfs-analyzer.ps1 test-claude"
            Write-Host ""
            Write-Host "OPTION 2: Windows Authentication"
            Write-Host "  1. Run: .\tfs-analyzer.ps1 setup"
            Write-Host "  2. Choose to enable Windows Authentication when prompted"
            Write-Host "  3. Come back and run: .\tfs-analyzer.ps1 test-claude"
            Write-Host ""
            
            $authChoice = Read-Host "Would you like to run the setup now? (y/n)"
            if ($authChoice -eq 'y' -or $authChoice -eq 'Y') {
                Setup-Configuration
                return
            }
        }
        return
    }
    
    # Step 3: Test Claude Code CLI
    Write-Host ""
    Write-ColorOutput "Testing Claude Code CLI..." "Info"
    
    $claudeAvailable = Test-ClaudeCodeAvailability
    if (-not $claudeAvailable) {
        Write-ColorOutput "[ERROR] Claude Code CLI not found" "Error"
        Write-Host ""
        Write-Host "CLAUDE CODE INSTALLATION REQUIRED:"
        Write-Host "1. Visit: https://claude.ai/code"
        Write-Host "2. Download and install Claude Code"
        Write-Host "3. Restart your terminal"
        Write-Host "4. Run: .\tfs-analyzer.ps1 test-claude"
        return
    }
    
    Write-ColorOutput "[OK] Claude Code CLI is available" "Success"
    
    # Step 4: Test full Claude integration
    Write-Host ""
    Write-ColorOutput "Testing Claude AI Integration..." "Info"
    
    # Test if all components are working together
    $fullTest = $true
    try {
        # Quick test of basic functionality  
        $headers = Get-Headers -Config $Config
        if (-not $headers) {
            $fullTest = $false
        }
    } catch {
        $fullTest = $false
        Write-DebugOutput "Full configuration test failed: $($_.Exception.Message)"
    }
    if ($fullTest) {
        Write-Host ""
        Write-ColorOutput "[SUCCESS] Claude AI is fully configured and ready!" "Success"
        Write-Host ""
        Write-Host "Next Steps:"
        Write-Host "- Test with: .\tfs-analyzer.ps1 1 -Claude -Browser"
        Write-Host "- Use -Details for troubleshooting if needed"
        Write-Host ""
        Write-Host "Ready! Claude AI will enhance your ticket analysis!"
    } else {
        Write-Host ""
        Write-ColorOutput "[WARNING] Claude AI configuration has issues" "Warning"
        Write-Host ""
        Write-Host "Try these troubleshooting steps:"
        Write-Host "1. Run: .\tfs-analyzer.ps1 setup-claude"
        Write-Host "2. Verify Azure DevOps connectivity"
        Write-Host "3. Check Claude Code installation"
        Write-Host "4. Use -Details flag for debug information"
    }
}

# Handle backward compatibility for -Days parameter
if ($Days -gt 0) {
    $TimeValue = $Days
}

# Main logic
switch ($Action.ToLower()) {
    'setup' {
        Setup-Configuration
    }
    'setup-output' {
        Setup-OutputConfiguration
    }
    'setup-claude' {
        Setup-ClaudeConfiguration
    }
    'test-claude' {
        Test-ClaudeConfiguration
    }
    'help' {
        Show-Help
    }
    'test-auth' {
        $Config = Load-Configuration
        try {
            $Headers = Get-Headers -Config $Config
            Write-ColorOutput "Authentication test successful!" "Success"

            # Test Azure CLI if configured
            if ($Config.USE_AZURE_CLI -eq 'true') {
                $azAuth = Test-AzureCliAuthentication
                if ($azAuth) {
                    Write-ColorOutput "Azure CLI authentication verified" "Success"
                } else {
                    Write-ColorOutput "Azure CLI authentication failed" "Warning"
                }
            }

            # Test Claude if available
            if ($Config.CLAUDE_AVAILABLE -eq 'true') {
                $claudeAvailable = Test-ClaudeCodeAvailability
                if ($claudeAvailable) {
                    Write-ColorOutput "Claude Code CLI is available" "Success"
                } else {
                    Write-ColorOutput "Claude Code CLI not found" "Warning"
                }
            }

        } catch {
            Write-ColorOutput "Authentication test failed: $($_.Exception.Message)" "Error"
        }
    }
    { $_ -match '^\d+$' } {
        $Config = Load-Configuration
        Analyze-Tickets -Config $Config -TimeValue ([int]$Action) -UseHours:$Hours -Html:$Html -Browser:$Browser -Text:$Text -Email:$Email -Claude:$Claude -NoAI:$NoAI -Details:$Details
    }
    'analyze' {
        $Config = Load-Configuration
        Analyze-Tickets -Config $Config -TimeValue $TimeValue -UseHours:$Hours -Html:$Html -Browser:$Browser -Text:$Text -Email:$Email -Claude:$Claude -NoAI:$NoAI -Details:$Details
    }
    default {
        if ($Action -match '^\d+$') {
            $Config = Load-Configuration
            Analyze-Tickets -Config $Config -TimeValue ([int]$Action) -UseHours:$Hours -Html:$Html -Browser:$Browser -Text:$Text -Email:$Email -Claude:$Claude -NoAI:$NoAI -Details:$Details
        } else {
            Write-ColorOutput "Invalid option: $Action" "Error"
            Write-Host "Use 'help' for usage information."
            Write-Host "Available commands: setup, setup-output, setup-claude, test-auth, help, analyze, [number]"
        }
    }
}