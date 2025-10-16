# Setup Daily TFS Ticket Analysis Schedule - No SMTP Required
# This script creates a Windows Task Scheduler task using the multi-output version

param(
    [string]$Time = "08:00",
    [string]$ScriptPath = "",
    [string]$OutputMethod = "browser",
    [switch]$Remove = $false
)

$TaskName = "TFS-Daily-Ticket-Analysis-NoSMTP"

if ($Remove) {
    Write-Host "Removing scheduled task..." -ForegroundColor Yellow
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        Write-Host "Task '$TaskName' removed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Task may not exist or error occurred: $($_.Exception.Message)" -ForegroundColor Red
    }
    exit
}

# Auto-detect script path if not provided
if ([string]::IsNullOrEmpty($ScriptPath)) {
    $ScriptPath = Join-Path $PSScriptRoot "tfs-analyzer.ps1"
}

if (-not (Test-Path $ScriptPath)) {
    Write-Host "Error: Cannot find tfs-analyzer.ps1 at: $ScriptPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please specify the full path using -ScriptPath parameter:" -ForegroundColor Yellow
    Write-Host "  .\tfs-scheduler-daily.ps1 -ScriptPath 'C:\path\to\tfs-analyzer.ps1'" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "Setting up daily TFS ticket analysis (No SMTP required)..." -ForegroundColor Cyan
Write-Host "Script: $ScriptPath" -ForegroundColor Gray
Write-Host "Time: $Time daily" -ForegroundColor Gray
Write-Host "Output Method: $OutputMethod" -ForegroundColor Gray
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "This script needs to run as Administrator to create scheduled tasks." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

try {
    # Remove existing task if it exists
    Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

    # Determine the PowerShell argument based on output method
    $Arguments = switch ($OutputMethod.ToLower()) {
        "browser" { "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" 1 -Browser" }
        "html" { "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" 1 -Html" }
        "text" { "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" 1 -Text" }
        default { "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" 1 -Browser" }
    }
    
    # Create the action (what to run)
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $Arguments
    
    # Create the trigger (when to run)
    $Trigger = New-ScheduledTaskTrigger -Daily -At $Time
    
    # Create task settings
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    # Create the principal (run as current user)
    $Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
    
    # Register the task
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description "Daily TFS ticket analysis with $OutputMethod output (No SMTP required)" | Out-Null

    Write-Host "Task created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Task Details:" -ForegroundColor Cyan
    Write-Host "  Name: $TaskName"
    Write-Host "  Schedule: Daily at $Time"
    Write-Host "  Output: $OutputMethod"
    Write-Host "  Script: $ScriptPath"
    Write-Host "  User: $env:USERNAME"
    Write-Host ""
    Write-Host "Management Commands:" -ForegroundColor Yellow
    Write-Host "  View task: Get-ScheduledTask -TaskName '$TaskName'"
    Write-Host "  Run now: Start-ScheduledTask -TaskName '$TaskName'"
    Write-Host "  Remove: .\tfs-scheduler-daily.ps1 -Remove"
    Write-Host ""
    
    # Show what happens daily
    switch ($OutputMethod.ToLower()) {
        "browser" {
            Write-Host "What happens daily:" -ForegroundColor Yellow
            Write-Host "  Analysis runs at $Time"
            Write-Host "  HTML summary opens in your default browser"
            Write-Host "  File saved to: $env:USERPROFILE\Documents\TFS-Daily-Summary.html"
        }
        "html" {
            Write-Host "What happens daily:" -ForegroundColor Yellow
            Write-Host "  Analysis runs at $Time"
            Write-Host "  HTML summary saved to: $env:USERPROFILE\Documents\TFS-Daily-Summary.html"
            Write-Host "  Double-click the file to view in browser"
        }
        "text" {
            Write-Host "What happens daily:" -ForegroundColor Yellow
            Write-Host "  Analysis runs at $Time"
            Write-Host "  Text summary saved to: $env:USERPROFILE\Documents\TFS-Daily-Summary.txt"
            Write-Host "  Open with any text editor"
        }
    }
    
} catch {
    Write-Host "Error creating scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure you are running as Administrator." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Alternative Output Methods:" -ForegroundColor Cyan
Write-Host "  Browser (default): .\tfs-scheduler-daily.ps1 -OutputMethod browser"
Write-Host "  HTML file only:    .\tfs-scheduler-daily.ps1 -OutputMethod html"
Write-Host "  Text file:         .\tfs-scheduler-daily.ps1 -OutputMethod text"