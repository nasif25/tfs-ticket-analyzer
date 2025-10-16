param([string]$TriggerType = "unknown")

# Get current time and date
$Now = Get-Date
$Today = $Now.ToString("yyyy-MM-dd")
$CurrentHour = $Now.Hour
$LogFile = "$env:TEMP\tfs-analyzer-last-run.txt"

# Check if script has already run today
$AlreadyRan = $false
if (Test-Path $LogFile) {
    $LastRun = Get-Content $LogFile -ErrorAction SilentlyContinue
    if ($LastRun -eq $Today) {
        $AlreadyRan = $true
    }
}

# Determine if we should run based on trigger type and conditions
$ShouldRun = $false
$Reason = ""

if (-not $AlreadyRan) {
    $ShouldRun = $true
    $Reason = "First run today"
} elseif ($TriggerType -eq "daily") {
    # For daily trigger, always run (even if startup ran earlier)
    # This ensures daily schedule works even if PC never turns off
    $ShouldRun = $true 
    $Reason = "Daily scheduled run"
} elseif ($TriggerType -eq "startup") {
    # For startup trigger, only run if not already run today
    $ShouldRun = $false
    $Reason = "Already ran today, skipping startup trigger"
}

if ($ShouldRun) {
    Write-Host "Running TFS Ticket Analyzer - $Reason ($Today)" -ForegroundColor Green

    # Build parameter based on output method
    switch ("html".ToLower()) {
        "browser" { & "C:\tipgit\tfs-ticket-analyzer\tfs-analyzer.ps1" 1 -Browser }
        "html" { & "C:\tipgit\tfs-ticket-analyzer\tfs-analyzer.ps1" 1 -Html }
        "text" { & "C:\tipgit\tfs-ticket-analyzer\tfs-analyzer.ps1" 1 -Text }
        "email" { & "C:\tipgit\tfs-ticket-analyzer\tfs-analyzer.ps1" 1 -Email }
        default { & "C:\tipgit\tfs-ticket-analyzer\tfs-analyzer.ps1" 1 -Browser }
    }

    # Update the log file with current date and trigger info
    "$Today ($TriggerType)" | Out-File -FilePath $LogFile -Encoding UTF8
    Write-Host "TFS Analyzer completed" -ForegroundColor Green
} else {
    Write-Host "TFS Analyzer skipped - $Reason ($Today)" -ForegroundColor Yellow
}
