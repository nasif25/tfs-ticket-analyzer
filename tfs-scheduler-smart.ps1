# Setup TFS Ticket Analyzer to run at startup if not run today
# Usage: Run as Administrator - .\setup-startup-schedule.ps1

param(
    [string]$OutputMethod = "browser",
    [string]$Time = "08:00",
    [switch]$NoAI = $false,
    [switch]$Remove
)

$TaskName = "TFS-Startup-Analysis"
$ScriptPath = "$PSScriptRoot\tfs-analyzer.ps1"

if ($Remove) {
    try {
        Unregister-ScheduledTask -TaskName "$TaskName-Startup" -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        Unregister-ScheduledTask -TaskName "$TaskName-Daily" -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        
        # Remove wrapper script
        $WrapperPath = "$PSScriptRoot\tfs-startup-wrapper.ps1"
        if (Test-Path $WrapperPath) {
            Remove-Item $WrapperPath -Force
        }
        
        Write-Host "Removed startup tasks: $TaskName-Startup, $TaskName-Daily" -ForegroundColor Green
    } catch {
        Write-Host "Tasks not found or already removed" -ForegroundColor Yellow
    }
    exit
}

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator to create scheduled tasks." -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "Setting up TFS Ticket Analyzer to run at startup..." -ForegroundColor Cyan
Write-Host "Output Method: $OutputMethod" -ForegroundColor White
Write-Host "Fallback Time: $Time" -ForegroundColor White
Write-Host "AI Analysis: $(if ($NoAI) { 'Disabled' } else { 'Enabled (default)' })" -ForegroundColor White

# Create wrapper script that handles both startup and daily triggers
$WrapperScript = @"
param([string]`$TriggerType = "unknown")

# Get current time and date
`$Now = Get-Date
`$Today = `$Now.ToString("yyyy-MM-dd")
`$CurrentHour = `$Now.Hour
`$LogFile = "`$env:TEMP\tfs-analyzer-last-run.txt"

# Check if script has already run today
`$AlreadyRan = `$false
if (Test-Path `$LogFile) {
    `$LastRun = Get-Content `$LogFile -ErrorAction SilentlyContinue
    if (`$LastRun -eq `$Today) {
        `$AlreadyRan = `$true
    }
}

# Determine if we should run based on trigger type and conditions
`$ShouldRun = `$false
`$Reason = ""

if (-not `$AlreadyRan) {
    `$ShouldRun = `$true
    `$Reason = "First run today"
} elseif (`$TriggerType -eq "daily") {
    # For daily trigger, always run (even if startup ran earlier)
    # This ensures daily schedule works even if PC never turns off
    `$ShouldRun = `$true 
    `$Reason = "Daily scheduled run"
} elseif (`$TriggerType -eq "startup") {
    # For startup trigger, only run if not already run today
    `$ShouldRun = `$false
    `$Reason = "Already ran today, skipping startup trigger"
}

if (`$ShouldRun) {
    Write-Host "Running TFS Ticket Analyzer - `$Reason (`$Today)" -ForegroundColor Green

    # Build parameter based on output method
    `$NoAIParam = if ("$NoAI" -eq "True") { "-NoAI" } else { "" }
    switch ("$OutputMethod".ToLower()) {
        "browser" { & "$ScriptPath" 1 -Browser `$NoAIParam }
        "html" { & "$ScriptPath" 1 -Html `$NoAIParam }
        "text" { & "$ScriptPath" 1 -Text `$NoAIParam }
        "email" { & "$ScriptPath" 1 -Email `$NoAIParam }
        default { & "$ScriptPath" 1 -Browser `$NoAIParam }
    }

    # Update the log file with current date and trigger info
    "`$Today (`$TriggerType)" | Out-File -FilePath `$LogFile -Encoding UTF8
    Write-Host "TFS Analyzer completed" -ForegroundColor Green
} else {
    Write-Host "TFS Analyzer skipped - `$Reason (`$Today)" -ForegroundColor Yellow
}
"@

$WrapperPath = "$PSScriptRoot\tfs-startup-wrapper.ps1"
$WrapperScript | Out-File -FilePath $WrapperPath -Encoding UTF8

# Create actions for different triggers
$StartupAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$WrapperPath`" -TriggerType startup"
$DailyAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$WrapperPath`" -TriggerType daily"

# Create triggers
$StartupTrigger = New-ScheduledTaskTrigger -AtStartup
$DailyTrigger = New-ScheduledTaskTrigger -Daily -At $Time

# Task settings
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd

# Create startup task
$StartupTask = New-ScheduledTask -Action $StartupAction -Trigger $StartupTrigger -Settings $Settings -Description "Run TFS Ticket Analyzer at startup (only if not run today)"

# Create daily task  
$DailyTask = New-ScheduledTask -Action $DailyAction -Trigger $DailyTrigger -Settings $Settings -Description "Run TFS Ticket Analyzer daily at $Time"

try {
    # Remove existing tasks first
    Unregister-ScheduledTask -TaskName "$TaskName-Startup" -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
    Unregister-ScheduledTask -TaskName "$TaskName-Daily" -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

    # Register both tasks
    Register-ScheduledTask -TaskName "$TaskName-Startup" -InputObject $StartupTask -Force | Out-Null
    Register-ScheduledTask -TaskName "$TaskName-Daily" -InputObject $DailyTask -Force | Out-Null

    Write-Host "`nTask created successfully!" -ForegroundColor Green
    Write-Host "The TFS Ticket Analyzer will now:" -ForegroundColor White
    Write-Host "  - Run at startup if not already run today" -ForegroundColor White
    Write-Host "  - Run daily at $Time as backup" -ForegroundColor White
    Write-Host "  - Output method: $OutputMethod" -ForegroundColor White
    Write-Host "  - AI Analysis: $(if ($NoAI) { 'Disabled' } else { 'Enabled' })" -ForegroundColor White
    Write-Host "`nTo test startup: Start-ScheduledTask -TaskName '$TaskName-Startup'" -ForegroundColor Cyan
    Write-Host "To test daily: Start-ScheduledTask -TaskName '$TaskName-Daily'" -ForegroundColor Cyan
    Write-Host "To remove: .\tfs-scheduler-smart.ps1 -Remove" -ForegroundColor Cyan
    Write-Host "`nDisable AI: .\tfs-scheduler-smart.ps1 -OutputMethod browser -NoAI" -ForegroundColor Yellow
} catch {
    Write-Host "Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}