#!/bin/bash

# Setup automated TFS ticket analysis using cron (Linux/Mac)
# Usage: ./setup-cron-automation.sh [OPTIONS]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TFS_ANALYZER="$SCRIPT_DIR/tfs-analyzer.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

log_message() {
    local level="$1"
    local message="$2"
    local color=""
    
    case "$level" in
        "INFO")  color="$CYAN" ;;
        "WARN")  color="$YELLOW" ;;
        "ERROR") color="$RED" ;;
        "SUCCESS") color="$GREEN" ;;
    esac
    
    echo -e "${color}[$level]${NC} $message"
}

print_usage() {
    cat << EOF
Setup TFS Ticket Analyzer automation using cron

Usage: $0 [OPTIONS]

Options:
    --time TIME         Daily execution time in HH:MM format (default: 08:00)
    --output METHOD     Output method: browser|html|text|console (default: browser)
    --no-ai             Disable Claude AI (traditional analysis only)
    --remove           Remove existing cron job
    --list             List existing cron jobs
    --help             Show this help message

Automation Types:
    daily              Run at specified time every day
    startup            Run at system startup (using @reboot)
    login              Run when user logs in (requires desktop environment)

Examples:
    $0 --time 09:00 --output browser     # Daily at 9 AM, open in browser
    $0 --time 18:00 --output email       # Daily at 6 PM, send email
    $0 --output html                     # Daily at 8 AM (default), save HTML
    $0 --time 08:00 --output browser --no-ai  # Daily at 8 AM, no AI analysis
    $0 --remove                         # Remove automation
    $0 --list                          # Show current cron jobs

EOF
}

check_dependencies() {
    if [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
        log_message "ERROR" "This script is for Linux/Mac. Use PowerShell scripts for Windows."
        exit 1
    fi
    
    if ! command -v crontab > /dev/null; then
        log_message "ERROR" "crontab not found. Please install cron service."
        exit 1
    fi
    
    if [[ ! -f "$TFS_ANALYZER" ]]; then
        log_message "ERROR" "TFS analyzer script not found: $TFS_ANALYZER"
        exit 1
    fi
}

remove_existing_jobs() {
    log_message "INFO" "Removing existing TFS analyzer cron jobs..."
    
    # Remove all lines containing tfs-analyzer
    if crontab -l 2>/dev/null | grep -v "tfs-analyzer" | crontab -; then
        log_message "SUCCESS" "Existing cron jobs removed"
    else
        log_message "INFO" "No existing cron jobs found"
    fi
}

list_cron_jobs() {
    log_message "INFO" "Current cron jobs:"
    echo
    if crontab -l 2>/dev/null; then
        echo
    else
        log_message "INFO" "No cron jobs found"
    fi
    
    # Show TFS-specific jobs
    local tfs_jobs
    tfs_jobs=$(crontab -l 2>/dev/null | grep "tfs-analyzer" || true)
    
    if [[ -n "$tfs_jobs" ]]; then
        echo
        log_message "INFO" "TFS Analyzer jobs:"
        echo -e "${YELLOW}$tfs_jobs${NC}"
    fi
}

setup_daily_cron() {
    local time="$1"
    local output_method="$2"
    local no_ai="$3"

    local hour="${time%:*}"
    local minute="${time#*:}"

    # Validate time format
    if ! [[ "$hour" =~ ^[0-9]{1,2}$ ]] || ! [[ "$minute" =~ ^[0-9]{2}$ ]]; then
        log_message "ERROR" "Invalid time format. Use HH:MM (e.g., 09:30)"
        exit 1
    fi

    if [[ $hour -gt 23 ]] || [[ $minute -gt 59 ]]; then
        log_message "ERROR" "Invalid time values. Hour: 0-23, Minute: 0-59"
        exit 1
    fi

    log_message "INFO" "Setting up daily cron job..."
    log_message "INFO" "Time: $time"
    log_message "INFO" "Output method: $output_method"
    log_message "INFO" "AI Analysis: $(if [[ "$no_ai" == "true" ]]; then echo "Disabled"; else echo "Enabled"; fi)"

    # Convert output method to appropriate flag
    local output_flag=""
    case "$output_method" in
        browser) output_flag="--browser" ;;
        html) output_flag="--html" ;;
        text) output_flag="--text" ;;
        email) output_flag="--email" ;;
        console) output_flag="" ;;
        *) output_flag="--browser" ;;
    esac

    # Add no-ai flag if requested
    local no_ai_flag=""
    if [[ "$no_ai" == "true" ]]; then
        no_ai_flag=" --no-ai"
    fi

    # Create the cron entry
    local cron_line="$minute $hour * * * $TFS_ANALYZER 1 $output_flag$no_ai_flag # TFS Analyzer Daily"
    
    # Add to crontab
    (crontab -l 2>/dev/null | grep -v "# TFS Analyzer"; echo "$cron_line") | crontab -
    
    log_message "SUCCESS" "Daily cron job created!"
    echo -e "${WHITE}  Schedule: Every day at $time${NC}"
    echo -e "${WHITE}  Command: $TFS_ANALYZER 1 $output_flag$no_ai_flag${NC}"
    echo -e "${WHITE}  AI Analysis: $(if [[ "$no_ai" == "true" ]]; then echo "Disabled"; else echo "Enabled"; fi)${NC}"
    echo
    log_message "INFO" "To test immediately: $TFS_ANALYZER 1 $output_flag$no_ai_flag"
}

setup_startup_cron() {
    local output_method="$1"
    
    log_message "INFO" "Setting up startup cron job..."
    log_message "INFO" "Output method: $output_method"
    
    # Create the cron entry using @reboot
    local cron_line="@reboot sleep 60 && $TFS_ANALYZER 1 --output $output_method # TFS Analyzer Startup"
    
    # Add to crontab
    (crontab -l 2>/dev/null | grep -v "# TFS Analyzer"; echo "$cron_line") | crontab -
    
    log_message "SUCCESS" "Startup cron job created!"
    echo -e "${WHITE}  Schedule: At system startup (with 60 second delay)${NC}"
    echo -e "${WHITE}  Command: $TFS_ANALYZER 1 --output $output_method${NC}"
    echo
    log_message "INFO" "Job will run automatically after next system restart"
}

setup_login_automation() {
    local output_method="$1"
    
    log_message "INFO" "Setting up login automation..."
    
    # Determine desktop environment and setup method
    if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]] || [[ -n "${DESKTOP_SESSION:-}" ]]; then
        # Linux with desktop environment
        setup_linux_login_automation "$output_method"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        setup_macos_login_automation "$output_method"
    else
        log_message "WARN" "Desktop environment not detected. Using cron with user session detection."
        setup_session_cron "$output_method"
    fi
}

setup_linux_login_automation() {
    local output_method="$1"
    
    local autostart_dir="$HOME/.config/autostart"
    mkdir -p "$autostart_dir"
    
    local desktop_file="$autostart_dir/tfs-analyzer.desktop"
    
    cat > "$desktop_file" << EOF
[Desktop Entry]
Type=Application
Name=TFS Ticket Analyzer
Comment=Daily TFS ticket analysis
Exec=$TFS_ANALYZER 1 --output $output_method
Icon=applications-office
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=30
EOF
    
    chmod +x "$desktop_file"
    
    log_message "SUCCESS" "Linux login automation created!"
    echo -e "${WHITE}  File: $desktop_file${NC}"
    echo -e "${WHITE}  Will run when you log into desktop session${NC}"
}

setup_macos_login_automation() {
    local output_method="$1"
    
    local plist_file="$HOME/Library/LaunchAgents/com.tfs.analyzer.plist"
    local launch_agents_dir="$HOME/Library/LaunchAgents"
    
    mkdir -p "$launch_agents_dir"
    
    cat > "$plist_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.tfs.analyzer</string>
    <key>ProgramArguments</key>
    <array>
        <string>$TFS_ANALYZER</string>
        <string>1</string>
        <string>--output</string>
        <string>$output_method</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>86400</integer>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/tfs-analyzer.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/tfs-analyzer.error.log</string>
</dict>
</plist>
EOF
    
    # Load the launch agent
    launchctl unload "$plist_file" 2>/dev/null || true
    launchctl load "$plist_file"
    
    log_message "SUCCESS" "macOS login automation created!"
    echo -e "${WHITE}  File: $plist_file${NC}"
    echo -e "${WHITE}  Will run at login and daily${NC}"
    echo -e "${WHITE}  Logs: $HOME/Library/Logs/tfs-analyzer.log${NC}"
}

setup_session_cron() {
    local output_method="$1"
    
    # This creates a cron job that checks if user session is active
    local wrapper_script="$SCRIPT_DIR/tfs-login-wrapper.sh"
    
    cat > "$wrapper_script" << EOF
#!/bin/bash
# Check if user session is active and run TFS analyzer if not run today

# Check if today's analysis already happened
TODAY=\$(date +%Y-%m-%d)
LOG_FILE="\$HOME/.tfs-analyzer-last-run"

if [[ -f "\$LOG_FILE" ]]; then
    LAST_RUN=\$(cat "\$LOG_FILE" 2>/dev/null || echo "never")
    if [[ "\$LAST_RUN" == "\$TODAY" ]]; then
        exit 0  # Already ran today
    fi
fi

# Check if user session is active (varies by system)
if who | grep -q "\$(whoami)"; then
    # Run the analyzer
    "$TFS_ANALYZER" 1 --output "$output_method"
    
    # Mark as run today
    echo "\$TODAY" > "\$LOG_FILE"
fi
EOF
    
    chmod +x "$wrapper_script"
    
    # Add cron job that runs every hour during typical work hours
    local cron_line="0 8-18 * * * $wrapper_script # TFS Analyzer Session Check"
    
    (crontab -l 2>/dev/null | grep -v "# TFS Analyzer"; echo "$cron_line") | crontab -
    
    log_message "SUCCESS" "Session-based automation created!"
    echo -e "${WHITE}  Will check hourly during work hours (8 AM - 6 PM)${NC}"
    echo -e "${WHITE}  Runs once per day when user session is active${NC}"
}

interactive_setup() {
    echo -e "${CYAN}🔧 TFS Ticket Analyzer Automation Setup${NC}"
    echo "========================================"
    echo
    
    echo "Choose automation type:"
    echo "1. Daily - Run at specific time every day"
    echo "2. Startup - Run when system starts up"
    echo "3. Login - Run when you log into desktop"
    echo
    
    read -p "Choose option (1-3): " -n 1 -r
    echo
    
    local automation_type=""
    case $REPLY in
        1) automation_type="daily" ;;
        2) automation_type="startup" ;;
        3) automation_type="login" ;;
        *) 
            log_message "ERROR" "Invalid selection"
            exit 1
            ;;
    esac
    
    echo
    echo "Choose output method:"
    echo "1. Browser - Open HTML report in browser"
    echo "2. HTML - Save report to ~/Downloads or ~/Documents"  
    echo "3. Text - Save plain text summary"
    echo "4. Console - Display in terminal"
    echo
    
    read -p "Choose output (1-4): " -n 1 -r
    echo
    
    local output_method=""
    case $REPLY in
        1) output_method="browser" ;;
        2) output_method="html" ;;
        3) output_method="text" ;;
        4) output_method="console" ;;
        *)
            log_message "ERROR" "Invalid selection"
            exit 1
            ;;
    esac
    
    local time="08:00"
    if [[ "$automation_type" == "daily" ]]; then
        echo
        read -p "Daily execution time (HH:MM, default 08:00): " time_input
        if [[ -n "$time_input" ]]; then
            time="$time_input"
        fi
    fi
    
    echo
    case "$automation_type" in
        "daily")
            setup_daily_cron "$time" "$output_method"
            ;;
        "startup")  
            setup_startup_cron "$output_method"
            ;;
        "login")
            setup_login_automation "$output_method"
            ;;
    esac
    
    echo
    log_message "INFO" "Management commands:"
    echo -e "${CYAN}  List jobs: $0 --list${NC}"
    echo -e "${CYAN}  Remove automation: $0 --remove${NC}"
    echo -e "${CYAN}  Test manually: $TFS_ANALYZER 1 --output $output_method${NC}"
}

main() {
    local time="08:00"
    local output_method="browser"
    local no_ai="false"
    local action="setup"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --time)
                time="$2"
                shift 2
                ;;
            --output)
                output_method="$2"
                shift 2
                ;;
            --no-ai)
                no_ai="true"
                shift
                ;;
            --remove)
                action="remove"
                shift
                ;;
            --list)
                action="list"
                shift
                ;;
            --help|-h)
                print_usage
                exit 0
                ;;
            *)
                log_message "ERROR" "Unknown argument: $1"
                print_usage
                exit 1
                ;;
        esac
    done
    
    check_dependencies
    
    case "$action" in
        "remove")
            remove_existing_jobs
            ;;
        "list")
            list_cron_jobs
            ;;
        "setup")
            if [[ $# -eq 0 ]] && [[ -t 0 ]]; then
                # Interactive mode
                interactive_setup
            else
                # Non-interactive mode
                remove_existing_jobs
                setup_daily_cron "$time" "$output_method" "$no_ai"
            fi
            ;;
    esac
}

# Run main function
main "$@"