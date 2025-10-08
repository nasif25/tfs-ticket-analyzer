# TFS Ticket Analyzer - Easy Setup Wizard
# Simple guided setup for non-technical users

param(
    [switch]$SkipWelcome
)

function Show-Welcome {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║   TFS Ticket Analyzer - Easy Setup Wizard                 ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Welcome! This wizard will help you set up your TFS Ticket Analyzer." -ForegroundColor White
    Write-Host ""
    Write-Host "What this tool does:" -ForegroundColor Yellow
    Write-Host "  ✓ Analyzes your TFS/Azure DevOps tickets" -ForegroundColor Green
    Write-Host "  ✓ Shows you what needs attention" -ForegroundColor Green
    Write-Host "  ✓ Helps prioritize your work" -ForegroundColor Green
    Write-Host "  ✓ Can run automatically every day" -ForegroundColor Green
    Write-Host ""
    Write-Host "Setup takes about 2-3 minutes." -ForegroundColor White
    Write-Host ""

    $continue = Read-Host "Ready to start? (Y/N)"
    if ($continue -notmatch '^[Yy]') {
        Write-Host "Setup cancelled. Run this script again when you're ready!" -ForegroundColor Yellow
        exit
    }
}

function Get-TFSConfiguration {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Step 1: TFS/Azure DevOps Connection" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "We need to know where your TFS server is located." -ForegroundColor White
    Write-Host ""
    Write-Host "Common examples:" -ForegroundColor Yellow
    Write-Host "  • https://dev.azure.com/yourcompany" -ForegroundColor Gray
    Write-Host "  • https://tfs.yourcompany.com/tfs/YourCollection" -ForegroundColor Gray
    Write-Host ""

    $tfsUrl = Read-Host "Enter your TFS/Azure DevOps URL"

    Write-Host ""
    Write-Host "What project do you want to analyze?" -ForegroundColor White
    Write-Host "(This is the name of your team project)" -ForegroundColor Gray
    Write-Host ""

    $projectName = Read-Host "Enter your project name"

    return @{
        TfsUrl = $tfsUrl
        ProjectName = $projectName
    }
}

function Get-AuthenticationMethod {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Step 2: Authentication Setup" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "How would you like to connect to TFS?" -ForegroundColor White
    Write-Host ""
    Write-Host "1. Azure CLI (Recommended - most secure)" -ForegroundColor Green
    Write-Host "   Uses your Microsoft account to log in" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Personal Access Token" -ForegroundColor Yellow
    Write-Host "   Uses a password-like token you create in TFS" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Choose option (1 or 2)"

    if ($choice -eq "1") {
        # Check if Azure CLI is installed
        try {
            $null = & az --version 2>$null
            Write-Host ""
            Write-Host "✓ Azure CLI is installed" -ForegroundColor Green
        } catch {
            Write-Host ""
            Write-Host "Azure CLI is not installed." -ForegroundColor Red
            Write-Host ""
            Write-Host "Would you like to:" -ForegroundColor Yellow
            Write-Host "  A. Install Azure CLI now (opens browser)" -ForegroundColor White
            Write-Host "  B. Use Personal Access Token instead" -ForegroundColor White
            Write-Host ""

            $installChoice = Read-Host "Choose (A or B)"

            if ($installChoice -match '^[Aa]') {
                Write-Host ""
                Write-Host "Opening Azure CLI download page..." -ForegroundColor Cyan
                Start-Process "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
                Write-Host ""
                Write-Host "After installing:" -ForegroundColor Yellow
                Write-Host "  1. Close and reopen PowerShell" -ForegroundColor White
                Write-Host "  2. Run this setup again" -ForegroundColor White
                Write-Host ""
                Read-Host "Press Enter to exit"
                exit
            } else {
                return Get-PersonalAccessToken
            }
        }

        # Try to authenticate with Azure CLI
        Write-Host ""
        Write-Host "Authenticating with Azure CLI..." -ForegroundColor Cyan
        Write-Host "This will open your browser to log in." -ForegroundColor Yellow
        Write-Host ""

        try {
            & az login --allow-no-subscriptions
            Write-Host ""
            Write-Host "✓ Successfully authenticated!" -ForegroundColor Green
            return @{
                Method = "AzureCLI"
                Pat = ""
            }
        } catch {
            Write-Host ""
            Write-Host "Azure CLI login failed." -ForegroundColor Red
            Write-Host "Let's try Personal Access Token instead." -ForegroundColor Yellow
            return Get-PersonalAccessToken
        }
    } else {
        return Get-PersonalAccessToken
    }
}

function Get-PersonalAccessToken {
    Write-Host ""
    Write-Host "═══ Setting up Personal Access Token ═══" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To create a Personal Access Token (PAT):" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Open your browser and go to your TFS/Azure DevOps" -ForegroundColor White
    Write-Host "2. Click your profile picture (top right)" -ForegroundColor White
    Write-Host "3. Go to: Security > Personal Access Tokens" -ForegroundColor White
    Write-Host "4. Click 'New Token'" -ForegroundColor White
    Write-Host "5. Give it a name like 'TFS Analyzer'" -ForegroundColor White
    Write-Host "6. Check the 'Work Items (Read)' permission" -ForegroundColor White
    Write-Host "7. Click 'Create' and copy the token" -ForegroundColor White
    Write-Host ""

    $openBrowser = Read-Host "Would you like me to open your TFS page? (Y/N)"
    if ($openBrowser -match '^[Yy]') {
        $global:TfsConfig = @{TfsUrl = ""; ProjectName = ""}
        if ($global:TfsConfig.TfsUrl) {
            Start-Process $global:TfsConfig.TfsUrl
        }
    }

    Write-Host ""
    $pat = Read-Host "Enter your Personal Access Token" -AsSecureString
    $patPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pat))

    return @{
        Method = "PAT"
        Pat = $patPlain
    }
}

function Get-UserDisplayName {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Step 3: Your Display Name" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "What is your display name in TFS/Azure DevOps?" -ForegroundColor White
    Write-Host "This helps find tickets where you're mentioned." -ForegroundColor Gray
    Write-Host ""
    Write-Host "Examples: 'John Smith', 'Jane Doe'" -ForegroundColor Yellow
    Write-Host ""

    $displayName = Read-Host "Enter your display name"
    return $displayName
}

function Get-OutputPreference {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Step 4: How to Show Results" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "How would you like to see your ticket analysis?" -ForegroundColor White
    Write-Host ""
    Write-Host "1. Open in Browser (Recommended)" -ForegroundColor Green
    Write-Host "   Opens a nice HTML report automatically" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Save HTML File" -ForegroundColor Yellow
    Write-Host "   Saves report to your Documents folder" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Show in Terminal" -ForegroundColor Yellow
    Write-Host "   Displays results right here" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Choose option (1, 2, or 3)"

    switch ($choice) {
        "1" { return "browser" }
        "2" { return "html" }
        "3" { return "console" }
        default { return "browser" }
    }
}

function Get-AutomationPreference {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Step 5: Automatic Daily Analysis (Optional)" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Would you like to run the analysis automatically every day?" -ForegroundColor White
    Write-Host ""
    Write-Host "If yes, it will:" -ForegroundColor Yellow
    Write-Host "  • Run once per day at your chosen time" -ForegroundColor White
    Write-Host "  • Show you your tickets automatically" -ForegroundColor White
    Write-Host "  • Save you time remembering to check" -ForegroundColor White
    Write-Host ""

    $automate = Read-Host "Set up automatic daily analysis? (Y/N)"

    if ($automate -notmatch '^[Yy]') {
        return $null
    }

    Write-Host ""
    Write-Host "What time should it run?" -ForegroundColor White
    Write-Host "Enter time in 24-hour format (e.g., 08:00 for 8 AM, 14:30 for 2:30 PM)" -ForegroundColor Gray
    Write-Host ""

    $time = Read-Host "Enter time (default: 08:00)"
    if ([string]::IsNullOrWhiteSpace($time)) {
        $time = "08:00"
    }

    return $time
}

function Save-Configuration {
    param(
        [hashtable]$Config
    )

    Write-Host ""
    Write-Host "Saving configuration..." -ForegroundColor Cyan

    # Create config directory
    $configDir = Join-Path $PSScriptRoot ".config"
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    # Save configuration file
    $configFile = Join-Path $configDir ".tfs-analyzer-config"

    $configContent = @"
TFS_URL=$($Config.TfsUrl)
PROJECT_NAME=$($Config.ProjectName)
USER_DISPLAY_NAME=$($Config.DisplayName)
DEFAULT_OUTPUT=$($Config.OutputMethod)
USE_WINDOWS_AUTH=false
"@

    if ($Config.AuthMethod -eq "PAT") {
        $configContent += "`nPAT=$($Config.Pat)"
    }

    $configContent | Out-File -FilePath $configFile -Encoding UTF8

    Write-Host "✓ Configuration saved" -ForegroundColor Green
}

function Test-Configuration {
    param(
        [hashtable]$Config
    )

    Write-Host ""
    Write-Host "Testing connection to TFS..." -ForegroundColor Cyan

    $scriptPath = Join-Path $PSScriptRoot "tfs-analyzer.ps1"

    try {
        & $scriptPath test-auth
        return $true
    } catch {
        Write-Host ""
        Write-Host "Connection test failed." -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Setup-Automation {
    param(
        [string]$Time,
        [string]$OutputMethod
    )

    Write-Host ""
    Write-Host "Setting up automatic daily analysis..." -ForegroundColor Cyan

    $schedulerScript = Join-Path $PSScriptRoot "tfs-scheduler-daily.ps1"

    # Check if running as admin
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

    if (-not $isAdmin) {
        Write-Host ""
        Write-Host "⚠ Administrator privileges required for automation setup" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "To set up automation:" -ForegroundColor White
        Write-Host "  1. Right-click PowerShell" -ForegroundColor Gray
        Write-Host "  2. Select 'Run as Administrator'" -ForegroundColor Gray
        Write-Host "  3. Run: .\tfs-scheduler-daily.ps1 -Time '$Time' -OutputMethod '$OutputMethod'" -ForegroundColor Gray
        Write-Host ""
        return
    }

    try {
        & $schedulerScript -Time $Time -OutputMethod $OutputMethod
        Write-Host "✓ Automation configured!" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Automation setup failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "You can set it up later by running:" -ForegroundColor White
        Write-Host "  .\tfs-scheduler-daily.ps1 -Time '$Time' -OutputMethod '$OutputMethod'" -ForegroundColor Gray
    }
}

function Show-CompletionSummary {
    param(
        [hashtable]$Config
    )

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║   Setup Complete! ✓                                       ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your TFS Ticket Analyzer is ready to use!" -ForegroundColor White
    Write-Host ""
    Write-Host "═══ Quick Start Commands ═══" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Analyze today's tickets:" -ForegroundColor Yellow
    Write-Host "  .\tfs-analyzer.ps1 1 -Browser" -ForegroundColor White
    Write-Host ""
    Write-Host "Analyze last 7 days:" -ForegroundColor Yellow
    Write-Host "  .\tfs-analyzer.ps1 7 -Browser" -ForegroundColor White
    Write-Host ""
    Write-Host "Get help:" -ForegroundColor Yellow
    Write-Host "  .\tfs-analyzer.ps1 -?" -ForegroundColor White
    Write-Host ""

    if ($Config.Automation) {
        Write-Host "═══ Automation ═══" -ForegroundColor Cyan
        Write-Host "Your analyzer will run automatically every day at $($Config.AutomationTime)" -ForegroundColor White
        Write-Host ""
    }

    Write-Host "═══ Configuration Saved To ═══" -ForegroundColor Cyan
    Write-Host "  $PSScriptRoot\.config\" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Need help? Check the README.md file for more details." -ForegroundColor Yellow
    Write-Host ""
}

# Main Setup Flow
try {
    if (-not $SkipWelcome) {
        Show-Welcome
    }

    # Collect all configuration
    $config = @{}

    # Step 1: TFS Configuration
    $tfsConfig = Get-TFSConfiguration
    $config.TfsUrl = $tfsConfig.TfsUrl
    $config.ProjectName = $tfsConfig.ProjectName

    # Store in global scope for PAT helper
    $global:TfsConfig = $tfsConfig

    # Step 2: Authentication
    $authConfig = Get-AuthenticationMethod
    $config.AuthMethod = $authConfig.Method
    $config.Pat = $authConfig.Pat

    # Step 3: Display Name
    $config.DisplayName = Get-UserDisplayName

    # Step 4: Output Preference
    $config.OutputMethod = Get-OutputPreference

    # Step 5: Automation
    $automationTime = Get-AutomationPreference
    $config.Automation = $automationTime -ne $null
    $config.AutomationTime = $automationTime

    # Save configuration
    Save-Configuration -Config $config

    # Test configuration
    Write-Host ""
    $testSuccess = Test-Configuration -Config $config

    if (-not $testSuccess) {
        Write-Host ""
        Write-Host "Setup completed but connection test failed." -ForegroundColor Yellow
        Write-Host "Please verify your TFS URL and credentials." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit
    }

    # Setup automation if requested
    if ($config.Automation) {
        Setup-Automation -Time $config.AutomationTime -OutputMethod $config.OutputMethod
    }

    # Show completion summary
    Show-CompletionSummary -Config $config

    Write-Host ""
    $runNow = Read-Host "Would you like to run the analyzer now? (Y/N)"
    if ($runNow -match '^[Yy]') {
        Write-Host ""
        Write-Host "Running TFS Ticket Analyzer..." -ForegroundColor Cyan
        $scriptPath = Join-Path $PSScriptRoot "tfs-analyzer.ps1"
        & $scriptPath 1 -Browser
    }

} catch {
    Write-Host ""
    Write-Host "Setup failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please try again or use manual setup:" -ForegroundColor Yellow
    Write-Host "  .\tfs-analyzer.ps1 setup" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}
