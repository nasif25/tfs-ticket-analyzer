#!/bin/bash

# TFS Ticket Analyzer for Linux/Mac
# A comprehensive bash script that analyzes TFS tickets with cross-platform support

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
CONFIG_FILE="$CONFIG_DIR/.tfs-analyzer-config"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Create config directory
mkdir -p "$CONFIG_DIR"

print_usage() {
    cat << EOF
TFS Ticket Analyzer - Cross-platform bash version

Usage: $0 [DAYS] [OPTIONS]

Arguments:
    DAYS                Number of days to analyze (default: 1)

Options:
    setup               Run initial configuration
    setup-output        Configure default output method  
    test-auth           Test TFS authentication
    setup-cron [TIME]   Setup daily cron job (default time: 08:00)
    --output METHOD     Output method: browser|html|text|console|email
    --windows-auth      Use Windows/Kerberos authentication
    --verbose           Show detailed processing information
    --help              Show this help message

Examples:
    $0 setup                           # Initial setup
    $0 1 --output browser             # Analyze 1 day, show in browser
    $0 7 --output html                # Analyze 1 week, save HTML
    $0 setup-cron 09:00               # Setup daily cron at 9 AM
    $0 test-auth                      # Test connection

EOF
}

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

load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        return 1
    fi
    
    # Source the config file
    source "$CONFIG_FILE"
    return 0
}

save_config() {
    cat > "$CONFIG_FILE" << EOF
# TFS Analyzer Configuration
TFS_URL="$TFS_URL"
PROJECT_NAME="$PROJECT_NAME"
PAT="$PAT"
USER_DISPLAY_NAME="$USER_DISPLAY_NAME"
DEFAULT_OUTPUT="$DEFAULT_OUTPUT"
USE_WINDOWS_AUTH="$USE_WINDOWS_AUTH"

# Email Configuration (if applicable)
EMAIL_ADDRESS="$EMAIL_ADDRESS"
EMAIL_PASSWORD="$EMAIL_PASSWORD"
SMTP_SERVER="$SMTP_SERVER"
SMTP_PORT="$SMTP_PORT"
EOF
    
    chmod 600 "$CONFIG_FILE"
    log_message "SUCCESS" "Configuration saved to $CONFIG_FILE"
}

setup_config() {
    local use_windows_auth="${1:-false}"
    
    log_message "INFO" "TFS Ticket Analyzer Setup"
    echo "=================================="
    
    read -p "TFS URL (e.g., https://tfs.company.com/tfs/Collection): " TFS_URL
    read -p "Project Name (e.g., MyProject): " PROJECT_NAME
    
    if [[ "$use_windows_auth" == "true" ]]; then
        USE_WINDOWS_AUTH="true"
        PAT=""
        log_message "INFO" "Using Windows/Kerberos authentication"
    else
        USE_WINDOWS_AUTH="false"
        read -s -p "Personal Access Token: " PAT
        echo
    fi
    
    read -p "Your Display Name (for @mention detection): " USER_DISPLAY_NAME
    
    echo
    log_message "INFO" "Default Output Method:"
    echo "1. Browser (opens HTML in default browser)"
    echo "2. HTML File (saves to ~/Downloads or ~/Documents)"
    echo "3. Text File (saves plain text summary)"
    echo "4. Console (displays in terminal)"
    echo "5. Email (sends via SMTP)"
    
    read -p "Choose default output method (1-5): " choice
    
    case "$choice" in
        1) DEFAULT_OUTPUT="browser" ;;
        2) DEFAULT_OUTPUT="html" ;;
        3) DEFAULT_OUTPUT="text" ;;
        4) DEFAULT_OUTPUT="console" ;;
        5) DEFAULT_OUTPUT="email"; setup_email_config ;;
        *) DEFAULT_OUTPUT="console" ;;
    esac
    
    # Initialize email variables if not set
    EMAIL_ADDRESS="${EMAIL_ADDRESS:-}"
    EMAIL_PASSWORD="${EMAIL_PASSWORD:-}"
    SMTP_SERVER="${SMTP_SERVER:-}"
    SMTP_PORT="${SMTP_PORT:-587}"
    
    save_config
    log_message "SUCCESS" "Setup completed! Ready to analyze TFS tickets."
}

setup_email_config() {
    echo
    log_message "INFO" "Email Configuration:"
    read -p "Email Address: " EMAIL_ADDRESS
    read -s -p "Email Password: " EMAIL_PASSWORD
    echo
    
    # Auto-configure common email providers
    local domain="${EMAIL_ADDRESS##*@}"
    case "$domain" in
        "gmail.com")
            SMTP_SERVER="smtp.gmail.com"
            SMTP_PORT="587"
            log_message "INFO" "Using Gmail SMTP configuration"
            ;;
        "outlook.com"|"office365.com"|*.onmicrosoft.com)
            SMTP_SERVER="smtp.office365.com" 
            SMTP_PORT="587"
            log_message "INFO" "Using Office 365 SMTP configuration"
            ;;
        "yahoo.com")
            SMTP_SERVER="smtp.mail.yahoo.com"
            SMTP_PORT="587"
            log_message "INFO" "Using Yahoo SMTP configuration"
            ;;
        *)
            read -p "SMTP Server: " SMTP_SERVER
            read -p "SMTP Port (587/465): " SMTP_PORT
            ;;
    esac
}

test_auth() {
    if ! load_config; then
        log_message "ERROR" "No configuration found. Run 'setup' first."
        return 1
    fi
    
    log_message "INFO" "Testing TFS authentication..."
    
    local auth_header=""
    if [[ "$USE_WINDOWS_AUTH" == "true" ]]; then
        # Use current user credentials with curl --negotiate
        auth_header="--negotiate -u :"
    else
        # Use PAT authentication
        auth_header="-u :$PAT"
    fi
    
    local url="$TFS_URL/$PROJECT_NAME/_apis/wit/workitems?\$top=1&api-version=6.0"
    
    if curl -s --fail $auth_header "$url" > /dev/null 2>&1; then
        log_message "SUCCESS" "Authentication successful!"
        return 0
    else
        log_message "ERROR" "Authentication failed. Check your credentials."
        return 1
    fi
}

get_work_items() {
    local days="$1"
    
    if ! load_config; then
        log_message "ERROR" "No configuration found. Run 'setup' first."
        return 1
    fi
    
    local start_date
    start_date=$(date -d "$days days ago" +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -v-"${days}d" +%Y-%m-%dT%H:%M:%S)
    
    # Build WIQL query
    local wiql_query="SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType], [System.AssignedTo], [System.Priority], [Microsoft.VSTS.Common.Severity], [System.Description], [System.Tags], [System.CreatedDate], [System.ChangedDate] FROM workitems WHERE [System.TeamProject] = '$PROJECT_NAME' AND ([System.AssignedTo] = '$USER_DISPLAY_NAME' OR [System.History] CONTAINS '@$USER_DISPLAY_NAME') AND [System.ChangedDate] >= '$start_date' ORDER BY [System.Priority] ASC, [System.ChangedDate] DESC"
    
    local auth_header=""
    if [[ "$USE_WINDOWS_AUTH" == "true" ]]; then
        auth_header="--negotiate -u :"
    else
        auth_header="-u :$PAT"
    fi
    
    local wiql_url="$TFS_URL/$PROJECT_NAME/_apis/wit/wiql?api-version=6.0"
    
    # Execute WIQL query
    local wiql_response
    wiql_response=$(curl -s $auth_header \
        -H "Content-Type: application/json" \
        -d "{\"query\":\"$wiql_query\"}" \
        "$wiql_url")
    
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Failed to execute WIQL query"
        return 1
    fi
    
    # Extract work item IDs using simple grep/sed (avoiding jq dependency)
    local work_item_ids
    work_item_ids=$(echo "$wiql_response" | grep -o '"id":[0-9]*' | sed 's/"id"://' | tr '\n' ',' | sed 's/,$//')
    
    if [[ -z "$work_item_ids" ]]; then
        log_message "INFO" "No work items found for the specified criteria."
        return 0
    fi
    
    # Get detailed work item information
    local details_url="$TFS_URL/$PROJECT_NAME/_apis/wit/workitems?ids=$work_item_ids&\$expand=all&api-version=6.0"
    
    local work_items_json
    work_items_json=$(curl -s $auth_header "$details_url")
    
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Failed to retrieve work item details"
        return 1
    fi
    
    # Save work items to temp file for processing
    echo "$work_items_json" > "/tmp/tfs_work_items_$$.json"
    echo "/tmp/tfs_work_items_$$.json"
}

calculate_priority_score() {
    local work_item_json="$1"
    
    # Extract fields using grep/sed (basic JSON parsing)
    local state=$(echo "$work_item_json" | grep -o '"System.State":"[^"]*"' | sed 's/.*:"//;s/"//' | tr '[:upper:]' '[:lower:]')
    local work_type=$(echo "$work_item_json" | grep -o '"System.WorkItemType":"[^"]*"' | sed 's/.*:"//;s/"//' | tr '[:upper:]' '[:lower:]')
    local title=$(echo "$work_item_json" | grep -o '"System.Title":"[^"]*"' | sed 's/.*:"//;s/"//' | tr '[:upper:]' '[:lower:]')
    local priority=$(echo "$work_item_json" | grep -o '"System.Priority":[0-9]*' | sed 's/.*://')
    
    local score=0
    
    # State weight
    case "$state" in
        "in progress") score=$((score + 5)) ;;
        "active") score=$((score + 4)) ;;
        "new"|"committed") score=$((score + 3)) ;;
        "to do") score=$((score + 2)) ;;
        "done"|"closed") score=$((score + 1)) ;;
    esac
    
    # Work item type weight
    case "$work_type" in
        "bug") score=$((score + 3)) ;;
        "task"|"product backlog item") score=$((score + 2)) ;;
        "epic") score=$((score + 1)) ;;
    esac
    
    # Priority field
    if [[ -n "$priority" && "$priority" != "null" ]]; then
        local priority_score=$((5 - priority))
        if [[ $priority_score -gt 0 ]]; then
            score=$((score + priority_score))
        fi
    fi
    
    # Keyword analysis
    if echo "$title" | grep -qE "showstopper|critical|urgent|blocker|production|down|crash"; then
        score=$((score + 3))
    elif echo "$title" | grep -qE "error|exception|fail|broken|issue"; then
        score=$((score + 2))
    fi
    
    # Classify priority
    if [[ $score -ge 8 ]]; then
        echo "$score HIGH"
    elif [[ $score -ge 5 ]]; then
        echo "$score MEDIUM"
    else
        echo "$score LOW"
    fi
}

generate_console_output() {
    local work_items_file="$1"
    local days="$2"
    
    if [[ ! -f "$work_items_file" ]]; then
        log_message "ERROR" "Work items file not found"
        return 1
    fi
    
    echo
    echo -e "${CYAN}🎯 TFS Ticket Analysis - Last $days days${NC}"
    echo "============================================="
    echo -e "${WHITE}📅 Generated: $(date)${NC}"
    
    # Count total items (basic JSON parsing)
    local total_count
    total_count=$(grep -c '"id":' "$work_items_file" || echo "0")
    echo -e "${WHITE}📊 Total items: $total_count${NC}"
    echo
    
    # Process each work item
    while IFS= read -r line; do
        if echo "$line" | grep -q '"fields":'; then
            # Extract basic information
            local title=$(echo "$line" | grep -o '"System.Title":"[^"]*"' | sed 's/.*:"//;s/"//')
            local work_type=$(echo "$line" | grep -o '"System.WorkItemType":"[^"]*"' | sed 's/.*:"//;s/"//')
            local state=$(echo "$line" | grep -o '"System.State":"[^"]*"' | sed 's/.*:"//;s/"//')
            local id=$(echo "$line" | grep -o '"id":[0-9]*' | sed 's/.*://')
            
            # Calculate priority
            local priority_info
            priority_info=$(calculate_priority_score "$line")
            local score=$(echo "$priority_info" | cut -d' ' -f1)
            local priority_level=$(echo "$priority_info" | cut -d' ' -f2)
            
            # Color based on priority
            local priority_color=""
            case "$priority_level" in
                "HIGH") priority_color="$RED" ;;
                "MEDIUM") priority_color="$YELLOW" ;;
                "LOW") priority_color="$GREEN" ;;
            esac
            
            # Display work item
            echo -e "${priority_color}[$priority_level]${NC} $title"
            echo -e "   📝 Type: $work_type"
            echo -e "   📊 State: $state"
            echo -e "   🔢 ID: $id"
            echo -e "   ⭐ Score: $score"
            
            # Simple action recommendation
            case "$work_type-$state" in
                "Bug-New") echo -e "   💡 Action: 🔍 Investigate and reproduce the issue" ;;
                "Bug-Active") echo -e "   💡 Action: ⚡ Continue debugging and provide status updates" ;;
                "Task-To Do") echo -e "   💡 Action: 📅 Schedule work and move to Active" ;;
                *) echo -e "   💡 Action: Continue work on $(echo "$work_type" | tr '[:upper:]' '[:lower:]')" ;;
            esac
            echo
        fi
    done < <(grep -A 50 '"fields":' "$work_items_file")
    
    # Cleanup temp file
    rm -f "$work_items_file"
}

generate_html_output() {
    local work_items_file="$1" 
    local days="$2"
    local open_browser="${3:-false}"
    
    # Determine output directory
    local output_dir="$HOME/Downloads"
    [[ ! -d "$output_dir" ]] && output_dir="$HOME/Documents"
    [[ ! -d "$output_dir" ]] && output_dir="$HOME"
    
    local output_file="$output_dir/TFS-Daily-Summary.html"
    
    # Generate HTML content
    cat > "$output_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>TFS Ticket Analysis</title>
    <meta charset="utf-8">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; margin: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; }
        .summary { background: #f8f9fa; padding: 15px; border-radius: 6px; margin: 20px 0; }
        .work-item { margin: 15px 0; padding: 15px; border-left: 4px solid #ddd; background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .high { border-left-color: #dc3545; }
        .medium { border-left-color: #ffc107; }
        .low { border-left-color: #28a745; }
        .priority { font-weight: bold; padding: 4px 8px; border-radius: 4px; color: white; display: inline-block; }
        .priority.high { background: #dc3545; }
        .priority.medium { background: #ffc107; color: #212529; }
        .priority.low { background: #28a745; }
        .title { font-size: 18px; font-weight: bold; margin: 10px 0; }
        .details { color: #666; font-size: 14px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🎯 TFS Ticket Analysis</h1>
EOF

    echo "        <p>Last $days days • Generated: $(date)</p>" >> "$output_file"
    
    cat >> "$output_file" << 'EOF'
    </div>
    
    <div class="summary">
        <h2>📊 Summary</h2>
EOF

    # Add work items to HTML
    local total_count
    total_count=$(grep -c '"id":' "$work_items_file" || echo "0")
    echo "        <p><strong>Total Items:</strong> $total_count</p>" >> "$output_file"
    echo "    </div>" >> "$output_file"
    
    # Process work items for HTML
    while IFS= read -r line; do
        if echo "$line" | grep -q '"fields":'; then
            local title=$(echo "$line" | grep -o '"System.Title":"[^"]*"' | sed 's/.*:"//;s/"//')
            local work_type=$(echo "$line" | grep -o '"System.WorkItemType":"[^"]*"' | sed 's/.*:"//;s/"//')
            local state=$(echo "$line" | grep -o '"System.State":"[^"]*"' | sed 's/.*:"//;s/"//')
            local id=$(echo "$line" | grep -o '"id":[0-9]*' | sed 's/.*://')
            
            local priority_info
            priority_info=$(calculate_priority_score "$line")
            local score=$(echo "$priority_info" | cut -d' ' -f1)
            local priority_level=$(echo "$priority_info" | cut -d' ' -f2)
            local priority_class=$(echo "$priority_level" | tr '[:upper:]' '[:lower:]')
            
            cat >> "$output_file" << EOF
    <div class="work-item $priority_class">
        <span class="priority $priority_class">$priority_level</span>
        <div class="title">$title</div>
        <div class="details">
            <strong>Type:</strong> $work_type | 
            <strong>State:</strong> $state | 
            <strong>ID:</strong> $id | 
            <strong>Score:</strong> $score
        </div>
    </div>
EOF
        fi
    done < <(grep -A 50 '"fields":' "$work_items_file")
    
    echo "</body></html>" >> "$output_file"
    
    log_message "SUCCESS" "HTML report saved to: $output_file"
    
    if [[ "$open_browser" == "true" ]]; then
        if command -v open > /dev/null; then
            open "$output_file"  # macOS
        elif command -v xdg-open > /dev/null; then
            xdg-open "$output_file"  # Linux
        else
            log_message "INFO" "Please open: $output_file"
        fi
        log_message "INFO" "Report opened in browser"
    fi
    
    # Cleanup temp file
    rm -f "$work_items_file"
}

setup_cron_job() {
    local cron_time="${1:-08:00}"
    local output_method="${2:-console}"
    
    if [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
        log_message "ERROR" "Cron jobs not supported on Windows. Use Task Scheduler instead."
        return 1
    fi
    
    local hour="${cron_time%:*}"
    local minute="${cron_time#*:}"
    local script_path="$(realpath "$0")"
    
    local cron_line="$minute $hour * * * $script_path 1 --output $output_method"
    
    echo
    log_message "INFO" "Add this line to your crontab (run 'crontab -e'):"
    echo
    echo -e "${CYAN}$cron_line${NC}"
    echo  
    log_message "INFO" "This will run daily at $cron_time with $output_method output"
    
    # Optionally add to crontab automatically
    read -p "Add to crontab automatically? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        (crontab -l 2>/dev/null; echo "$cron_line") | crontab -
        log_message "SUCCESS" "Cron job added successfully!"
    fi
}

main() {
    local days=1
    local output_method=""
    local use_windows_auth="false"
    local verbose="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            setup)
                setup_config "$use_windows_auth"
                exit 0
                ;;
            setup-output)
                setup_config "$use_windows_auth"
                exit 0
                ;;
            test-auth)
                test_auth
                exit 0
                ;;
            setup-cron)
                local cron_time="${2:-08:00}"
                setup_cron_job "$cron_time" "${output_method:-console}"
                exit 0
                ;;
            --output)
                output_method="$2"
                shift
                ;;
            --windows-auth)
                use_windows_auth="true"
                ;;
            --verbose)
                verbose="true"
                ;;
            --help|-h)
                print_usage
                exit 0
                ;;
            [0-9]*)
                days="$1"
                ;;
            *)
                log_message "ERROR" "Unknown argument: $1"
                print_usage
                exit 1
                ;;
        esac
        shift
    done
    
    # Load config and determine output method
    if ! load_config; then
        log_message "ERROR" "No configuration found. Run '$0 setup' first."
        exit 1
    fi
    
    if [[ -z "$output_method" ]]; then
        output_method="${DEFAULT_OUTPUT:-console}"
    fi
    
    if [[ "$verbose" == "true" ]]; then
        log_message "INFO" "Analyzing last $days days..."
        log_message "INFO" "Output method: $output_method"
    fi
    
    # Get work items
    local work_items_file
    work_items_file=$(get_work_items "$days")
    
    if [[ -z "$work_items_file" ]]; then
        exit 1
    fi
    
    # Generate output
    case "$output_method" in
        browser)
            generate_html_output "$work_items_file" "$days" "true"
            ;;
        html)
            generate_html_output "$work_items_file" "$days" "false"
            ;;
        console)
            generate_console_output "$work_items_file" "$days"
            ;;
        text)
            # For simplicity, use console output redirected to file
            local output_dir="$HOME/Downloads"
            [[ ! -d "$output_dir" ]] && output_dir="$HOME/Documents"
            [[ ! -d "$output_dir" ]] && output_dir="$HOME"
            
            generate_console_output "$work_items_file" "$days" > "$output_dir/TFS-Daily-Summary.txt"
            log_message "SUCCESS" "Text report saved to: $output_dir/TFS-Daily-Summary.txt"
            ;;
        email)
            log_message "WARN" "Email output not implemented in bash version. Use Python version instead."
            generate_console_output "$work_items_file" "$days"
            ;;
        *)
            log_message "ERROR" "Unknown output method: $output_method"
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi