#!/bin/bash

# TFS Ticket Analyzer for Linux/Mac
# A comprehensive bash script that analyzes TFS tickets with cross-platform support

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/.config"
CONFIG_FILE="$CONFIG_DIR/.tfs-analyzer-config"
CLAUDE_CONFIG_FILE="$CONFIG_DIR/claude-code-config.json"

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
TFS Ticket Analyzer - Cross-platform bash version with Claude AI support

Usage: $0 [DAYS] [OPTIONS]

Arguments:
    DAYS                Number of days to analyze (default: 1)

Setup Commands:
    setup               Run initial configuration
    setup-claude        Setup Claude AI integration
    setup-output        Configure default output method  
    test-auth           Test TFS authentication
    test-claude         Test Claude AI configuration with guided setup
    setup-cron [TIME]   Setup daily cron job (default time: 08:00)

Simplified Options:
    -b, --browser       Open results in browser (same as --output browser)
    -h, --html          Save as HTML file (same as --output html)
    -t, --text          Save as text file (same as --output text)
    -e, --email         Send via email (same as --output email)
    -c, --claude        Use Claude AI for enhanced analysis
    --no-ai             Disable Claude AI (traditional analysis only)
    -d, --details       Show detailed processing information
    --help              Show this help message

Traditional Options:
    --output METHOD     Output method: browser|html|text|console|email
    --windows-auth      Use Windows/Kerberos authentication
    --verbose           Show detailed processing information (same as --details)

Examples:
    $0 setup                           # Initial setup
    $0 setup-claude                    # Setup Claude AI integration
    $0 1 -b                           # Analyze 1 day, show in browser
    $0 7 -h                           # Analyze 1 week, save HTML
    $0 1 -c -b                        # Analyze with Claude AI, show in browser
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

test_claude_configuration() {
    log_message "INFO" "Testing Claude AI configuration..."
    
    # Step 1: Test Claude Code CLI availability
    echo "Step 1: Testing Claude Code CLI availability"
    if command -v claude-code > /dev/null 2>&1; then
        log_message "SUCCESS" "[OK] Claude Code CLI found"
    else
        log_message "ERROR" "[ERROR] Claude Code CLI not found"
        echo "Solution: Install Claude Code from https://claude.ai/code"
        return 1
    fi
    
    # Step 2: Test authentication methods
    echo "Step 2: Testing authentication methods"
    local auth_available="false"
    
    if command -v az > /dev/null 2>&1 && az account show > /dev/null 2>&1; then
        log_message "SUCCESS" "[OK] Azure CLI authentication verified"
        auth_available="true"
    elif [[ -n "$PAT" ]]; then
        log_message "SUCCESS" "[OK] PAT authentication available"  
        auth_available="true"
    else
        log_message "ERROR" "[ERROR] No valid authentication method found"
        echo "Solution: Run 'az login --allow-no-subscriptions' or ensure PAT is configured"
        return 1
    fi
    
    # Step 3: Test Claude Code MCP configuration
    echo "Step 3: Testing Claude Code MCP configuration"
    if [[ -f "$CLAUDE_CONFIG_FILE" ]]; then
        log_message "SUCCESS" "[OK] Claude Code MCP configuration found"
    else
        log_message "WARN" "[WARNING]  Claude Code MCP configuration not found"
        echo "Will create during setup"
    fi
    
    # Step 4: Test Claude Code basic functionality
    echo "Step 4: Testing Claude Code basic functionality"
    if claude-code --help > /dev/null 2>&1; then
        log_message "SUCCESS" "[OK] Claude Code basic functionality verified"
    else
        log_message "WARN" "[WARNING]  Claude Code basic test failed"
    fi
    
    echo
    log_message "SUCCESS" "Claude AI configuration test completed!"
    return 0
}

test_claude_configuration() {
    log_message "INFO" "Testing Claude AI Configuration..."
    echo ""
    
    # Step 1: Check if basic configuration exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_message "WARN" "[WARNING] No basic configuration found."
        echo "You need to run the initial setup first."
        echo ""
        read -p "Would you like to run the basic setup now? (y/n): " setup_basic
        if [[ "$setup_basic" =~ ^[Yy]$ ]]; then
            setup_config
            return
        else
            log_message "ERROR" "[ERROR] Cannot test Claude without basic configuration."
            return
        fi
    fi
    
    log_message "SUCCESS" "[OK] Basic configuration found"
    
    # Step 2: Test authentication availability
    echo ""
    log_message "INFO" "Checking Authentication..."
    
    local az_auth_working="false"
    local pat_available="false"
    
    # Test Azure CLI
    if command -v az > /dev/null 2>&1; then
        local token_result
        token_result=$(az account get-access-token --resource https://dev.azure.com --query accessToken --output tsv 2>/dev/null)
        
        if [[ -n "$token_result" && "$token_result" != "null" && ! "$token_result" =~ error ]]; then
            log_message "SUCCESS" "[OK] Azure CLI is authenticated and working"
            az_auth_working="true"
        fi
    fi
    
    # Test PAT availability
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        if [[ -n "$PAT" && "$PAT" != "" ]]; then
            log_message "SUCCESS" "[OK] Personal Access Token is configured"
            pat_available="true"
        fi
    fi
    
    # If no authentication method is available, guide user to set it up
    if [[ "$az_auth_working" == "false" && "$pat_available" == "false" ]]; then
        log_message "WARN" "[WARNING] No authentication method is available!"
        echo ""
        echo "AUTHENTICATION SETUP REQUIRED:"
        echo "You need at least one authentication method to use Claude AI."
        echo ""
        echo "OPTION 1 (RECOMMENDED): Azure CLI"
        echo "  1. Run: az login --allow-no-subscriptions"
        echo "  2. Follow the browser authentication prompts"
        echo "  3. Come back and run: $0 test-claude"
        echo ""
        echo "OPTION 2: Personal Access Token (PAT)"
        echo "  1. Run: $0 setup"
        echo "  2. Choose to configure PAT when prompted"
        echo "  3. Come back and run: $0 test-claude"
        echo ""
        
        read -p "Would you like to set up Azure CLI authentication now? (y/n): " auth_choice
        if [[ "$auth_choice" =~ ^[Yy]$ ]]; then
            echo ""
            log_message "INFO" "Starting Azure CLI authentication..."
            echo "This will open your browser for authentication..."
            
            if command -v az > /dev/null 2>&1; then
                if az login --allow-no-subscriptions --allow-no-subscriptions; then
                    log_message "SUCCESS" "[OK] Azure CLI authentication completed!"
                    echo "Run 'test-claude' again to verify the setup."
                else
                    log_message "ERROR" "[ERROR] Azure CLI authentication failed."
                    echo "You can try the PAT setup instead: $0 setup"
                fi
            else
                log_message "ERROR" "[ERROR] Azure CLI not found. Please install Azure CLI first."
                echo "Or run: $0 setup (for PAT configuration)"
            fi
        else
            echo "You can set up authentication later with:"
            echo "  - az login --allow-no-subscriptions (for Azure CLI)"
            echo "  - $0 setup (for PAT)"
        fi
        return
    fi
    
    # Step 3: Test Claude Code CLI
    echo ""
    log_message "INFO" "Testing Claude Code CLI..."
    
    if ! command -v claude-code > /dev/null 2>&1; then
        log_message "ERROR" "[ERROR] Claude Code CLI not found"
        echo ""
        echo "CLAUDE CODE INSTALLATION REQUIRED:"
        echo "1. Visit: https://claude.ai/code"
        echo "2. Download and install Claude Code"
        echo "3. Restart your terminal"
        echo "4. Run: $0 test-claude"
        return
    fi
    
    log_message "SUCCESS" "[OK] Claude Code CLI is available"
    
    # Step 4: Test full Claude integration
    echo ""
    log_message "INFO" "Testing Claude AI Integration..."
    
    # Try a basic verification
    if test_claude_configuration_basic; then
        echo ""
        log_message "SUCCESS" "[SUCCESS] Claude AI is fully configured and ready!"
        echo ""
        echo "Next Steps:"
        echo "- Test with: $0 1 -c -b"
        echo "- Use -d flag for troubleshooting if needed"
        echo ""
        echo "Ready! Claude AI will enhance your ticket analysis!"
    else
        echo ""
        log_message "WARN" "[WARNING] Claude AI configuration has issues"
        echo ""
        echo "Try these troubleshooting steps:"
        echo "1. Run: $0 setup-claude"
        echo "2. Verify Azure DevOps connectivity"
        echo "3. Check Claude Code installation"
        echo "4. Use -d flag for debug information"
    fi
}

setup_claude_config() {
    log_message "INFO" "Setting up Claude AI integration..."
    echo "This will configure AI-powered ticket analysis with enhanced insights."
    echo
    
    # Step 1: Test Claude Code availability
    if ! command -v claude-code > /dev/null 2>&1; then
        log_message "ERROR" "[ERROR] Claude Code CLI not found. Please install Claude Code first:"
        echo
        echo "Installation Installation Steps:"
        echo "1. Visit: https://claude.ai/code"
        echo "2. Download and install Claude Code"
        echo "3. Follow the setup instructions" 
        echo "4. Restart your terminal"
        echo "5. Run this setup again: $0 setup-claude"
        echo
        return 1
    fi
    log_message "SUCCESS" "[OK] Claude Code CLI found"
    
    # Step 2: Load existing configuration
    if ! load_config; then
        log_message "ERROR" "[ERROR] Main configuration not found. Please run: $0 setup"
        return 1
    fi
    
    echo
    log_message "INFO" "Claude AI Features Claude AI Features:"
    echo "- Intelligent priority assessment with AI reasoning"
    echo "- Smart content summarization and key point extraction"
    echo "- Actionable recommendations for next steps"
    echo "- Impact analysis and risk assessment"
    echo "- Enhanced decision tracking from ticket history"
    echo
    
    read -p "Enable Claude AI analysis by default? (y/n): " enable_claude
    local use_claude_by_default="false"
    if [[ "$enable_claude" == "y" || "$enable_claude" == "Y" ]]; then
        use_claude_by_default="true"
    fi
    
    # Step 3: Configure authentication
    echo
    log_message "INFO" "Authentication Configuration Authentication Configuration:"
    echo "Claude Code supports multiple authentication methods:"
    echo "1. Azure CLI (Recommended) - Uses your current Azure login"
    echo "2. Personal Access Token - Uses stored PAT from main config"
    echo
    
    # Test available authentication methods
    local azure_cli_auth="false"
    local pat_available="false"
    
    if command -v az > /dev/null 2>&1 && az account show > /dev/null 2>&1; then
        azure_cli_auth="true"
    fi
    
    if [[ -n "$PAT" ]]; then
        pat_available="true"
    fi
    
    echo "Authentication Status Authentication Status:"
    if [[ "$azure_cli_auth" == "true" ]]; then
        log_message "SUCCESS" "[OK] Azure CLI: Authenticated and ready"
    else
        log_message "WARN" "[ERROR] Azure CLI: Not authenticated (run 'az login --allow-no-subscriptions')"
    fi
    
    if [[ "$pat_available" == "true" ]]; then
        log_message "SUCCESS" "[OK] PAT: Available from main configuration"
    else
        log_message "WARN" "[ERROR] PAT: Not configured"
    fi
    
    echo
    read -p "Choose primary authentication method (1 for Azure CLI, 2 for PAT): " auth_choice
    local use_azure_cli="false"
    
    if [[ "$auth_choice" == "1" ]]; then
        if [[ "$azure_cli_auth" == "true" ]]; then
            use_azure_cli="true"
        else
            log_message "WARN" "[WARNING]  Azure CLI selected but not authenticated."
            echo "Please run: az login --allow-no-subscriptions"
            echo
            read -p "Continue with PAT as fallback? (y/n): " continue_with_pat
            if [[ "$continue_with_pat" != "y" && "$continue_with_pat" != "Y" ]]; then
                log_message "WARN" "Setup cancelled. Please run 'az login --allow-no-subscriptions' and try again."
                return 1
            fi
        fi
    fi
    
    if [[ "$use_azure_cli" == "false" && "$pat_available" == "false" ]]; then
        log_message "ERROR" "[ERROR] No valid authentication method available."
        echo "Please either:"
        echo "1. Run 'az login --allow-no-subscriptions' to authenticate Azure CLI, or"
        echo "2. Run '$0 setup' to configure PAT"
        return 1
    fi
    
    # Step 4: Configure Azure DevOps Organization URL
    echo
    log_message "INFO" "Azure DevOps Configuration Azure DevOps Configuration:"
    read -p "Enter your Azure DevOps Organization URL (e.g., https://dev.azure.com/yourorg): " AZURE_DEVOPS_ORG_URL
    
    if [[ -z "$AZURE_DEVOPS_ORG_URL" ]]; then
        log_message "ERROR" "[ERROR] Azure DevOps Organization URL is required for Claude AI integration."
        return 1
    fi
    
    # Step 5: Create Claude Code MCP server configuration
    log_message "INFO" "Setting up Claude Code MCP server configuration..."
    
    # Create Claude Code config file
    cat > "$CLAUDE_CONFIG_FILE" << EOF
{
    "mcpServers": {
        "azure-devops": {
            "command": "npx",
            "args": ["@anthropic/mcp-server-azure-devops"],
            "env": {
                "AZURE_DEVOPS_ORG_URL": "$AZURE_DEVOPS_ORG_URL"
            }
        }
    }
}
EOF
    
    log_message "SUCCESS" "[OK] Claude Code MCP configuration created"
    
    # Step 6: Update main configuration  
    USE_CLAUDE_AI="$use_claude_by_default"
    AZURE_DEVOPS_ORG_URL="$AZURE_DEVOPS_ORG_URL"
    
    # Step 7: Run comprehensive verification
    echo
    log_message "INFO" "Running Configuration Verification Running Configuration Verification..."
    if test_claude_configuration; then
        echo
        log_message "SUCCESS" "[SUCCESS] Claude AI integration setup completed successfully!"
        echo
        echo "Next Steps Next Steps:"
        echo "- Test with: $0 1 -c -b"
        echo "- Use -d flag for troubleshooting if needed"
        echo "- Run 'test-auth' to verify authentication setup"
        echo
        echo "Ready! Claude AI is now ready to enhance your ticket analysis!"
    else
        log_message "WARN" "[WARNING]  Setup completed with warnings. Some features may not work properly."
        echo
        echo "Troubleshooting Tips  Troubleshooting Tips:"
        echo "- Run: $0 test-claude"
        echo "- Check authentication with: az login --allow-no-subscriptions"
        echo "- Verify Claude Code installation"
        echo "- Use -d flag for debug information"
    fi
    
    return 0
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
    echo -e "${CYAN}TFS Ticket Analysis TFS Ticket Analysis - Last $days days${NC}"
    echo "============================================="
    echo -e "${WHITE}Generated: Generated: $(date)${NC}"
    
    # Count total items (basic JSON parsing)
    local total_count
    total_count=$(grep -c '"id":' "$work_items_file" || echo "0")
    echo -e "${WHITE}Authentication Status Total items: $total_count${NC}"
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
            echo -e "   Type: $work_type"
            echo -e "   State: $state"
            echo -e "   ID: $id"
            echo -e "   Score: $score"
            
            # Simple action recommendation
            case "$work_type-$state" in
                "Bug-New") echo -e "   Action: Investigate and reproduce the issue" ;;
                "Bug-Active") echo -e "   Action: Continue debugging and provide status updates" ;;
                "Task-To Do") echo -e "   Action: Schedule work and move to Active" ;;
                *) echo -e "   Action: Continue work on $(echo "$work_type" | tr '[:upper:]' '[:lower:]')" ;;
            esac
            echo
        fi
    done < <(grep -A 50 '"fields":' "$work_items_file")
    
    # Display Claude failure reason if present
    if [[ -n "$CLAUDE_FAILURE_REASON" ]]; then
        echo
        echo -e "${YELLOW}Claude Analysis Failure Reason:${NC}"
        echo -e "  - $CLAUDE_FAILURE_REASON"
        echo
    fi
    
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
        <h1>TFS Ticket Analysis TFS Ticket Analysis</h1>
EOF

    echo "        <p>Last $days days - Generated: $(date)</p>" >> "$output_file"
    
    cat >> "$output_file" << 'EOF'
    </div>
    
    <div class="summary">
        <h2>Authentication Status Summary</h2>
EOF

    # Add work items to HTML
    local total_count
    total_count=$(grep -c '"id":' "$work_items_file" || echo "0")
    echo "        <p><strong>Total Items:</strong> $total_count</p>" >> "$output_file"
    
    # Add Claude failure reason if present
    if [[ -n "$CLAUDE_FAILURE_REASON" ]]; then
        echo "        <div style='background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 4px; padding: 10px; margin: 10px 0;'>" >> "$output_file"
        echo "            <strong>[WARNING] Claude Analysis Failure:</strong> $CLAUDE_FAILURE_REASON" >> "$output_file"
        echo "        </div>" >> "$output_file"
    fi
    
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

invoke_claude_analysis() {
    local work_items_file="$1"
    local days="$2"
    local output_method="$3"
    
    if [[ ! -f "$work_items_file" ]]; then
        echo "ERROR: Work items file not found for Claude analysis"
        return 1
    fi
    
    # Count total work items for progress indication
    local total_count
    total_count=$(grep -c '"id":' "$work_items_file" 2>/dev/null || echo "0")
    
    # Progress indicator setup
    log_message "INFO" "Claude AI will analyze $total_count ticket(s) for enhanced insights..."
    echo "  [INFO] This may take a few minutes depending on ticket count and complexity" >&2
    echo -n "  [AI] Analyzing all tickets with Claude AI..." >&2
    
    # Step 1: Verify Claude Code is available
    if ! command -v claude-code > /dev/null 2>&1; then
        echo "ERROR: Claude Code CLI not found. Run setup-claude first."
        return 1
    fi
    
    # Step 2: Verify authentication
    local auth_available="false"
    if command -v az > /dev/null 2>&1 && az account show > /dev/null 2>&1; then
        auth_available="true" 
        log_message "INFO" "[OK] Using Azure CLI authentication for Claude analysis"
    elif [[ -n "$PAT" ]]; then
        log_message "INFO" "[OK] Using Personal Access Token for Claude analysis"
        # Set PAT for Azure DevOps MCP server
        export AZURE_DEVOPS_PAT="$PAT"
        auth_available="true"
    else
        echo "ERROR: No valid authentication method available. Configure Azure CLI or PAT."
        return 1
    fi
    
    if [[ "$auth_available" == "false" ]]; then
        echo "ERROR: Authentication verification failed."
        return 1
    fi
    
    # Step 3: Verify Claude Code MCP configuration
    if [[ ! -f "$CLAUDE_CONFIG_FILE" ]]; then
        log_message "WARN" "[WARNING]  Claude Code MCP configuration not found. This may cause issues."
        echo "Consider running: $0 setup-claude"
    fi
    
    # Create a temporary analysis request file
    local temp_request="/tmp/claude_analysis_request_$$.txt"
    cat > "$temp_request" << EOF
Please analyze the following TFS work items from the last $days days and provide:

1. Enhanced Priority Analysis - Review each work item and provide intelligent priority rankings
2. Action Recommendations - Suggest specific next steps for each item
3. Risk Assessment - Identify potential risks or blockers
4. Summary Insights - Overall patterns and key focus areas

Work Items Data:
\$(cat "$work_items_file")

Please format the response as structured analysis with clear sections for each work item, including priority level (HIGH/MEDIUM/LOW), recommended actions, and risk factors.
EOF
    
    # Invoke Claude Code with the analysis request using stdin
    local claude_response="/tmp/claude_response_$$.txt"
    local claude_error="/tmp/claude_error_$$.txt"
    
    # Use timeout and proper error capture
    if timeout 120 bash -c "cat '$temp_request' | claude-code --print --output-format json" > "$claude_response" 2> "$claude_error"; then
        if [[ -s "$claude_response" ]]; then
            echo " Done" >&2
            log_message "SUCCESS" "Claude AI analysis completed for all $total_count tickets!"
            
            # Process Claude's response and integrate with traditional analysis
            generate_enhanced_analysis "$work_items_file" "$claude_response" "$days" "$output_method"
            
            # Cleanup
            rm -f "$temp_request" "$claude_response" "$claude_error"
            return 0
        else
            echo " Failed" >&2
            local error_msg="Claude returned empty response"
            if [[ -s "$claude_error" ]]; then
                local error_content=$(head -n 3 "$claude_error" | tr '\n' ' ')
                error_msg="$error_msg: $error_content"
            fi
            echo "ERROR: $error_msg"
            rm -f "$temp_request" "$claude_response" "$claude_error"
            return 1
        fi
    else
        echo " Failed" >&2
        local exit_code=$?
        local error_msg=""
        
        if [[ $exit_code -eq 124 ]]; then
            error_msg="Command timed out after 120 seconds"
        elif [[ -s "$claude_error" ]]; then
            error_msg=$(head -n 3 "$claude_error" | tr '\n' ' ')
        else
            error_msg="Claude Code execution failed (exit code: $exit_code)"
        fi
        
        echo "ERROR: $error_msg"
        rm -f "$temp_request" "$claude_response" "$claude_error"
        return 1
    fi
}

generate_enhanced_analysis() {
    local work_items_file="$1"
    local claude_response="$2"
    local days="$3"
    local output_method="$4"
    
    log_message "INFO" "Generating enhanced analysis with Claude AI insights"
    
    case "$output_method" in
        "browser"|"html")
            generate_enhanced_html_output "$work_items_file" "$claude_response" "$days" "$([[ \"$output_method\" == \"browser\" ]] && echo \"true\" || echo \"false\")"
            ;;
        "console")
            generate_enhanced_console_output "$work_items_file" "$claude_response" "$days"
            ;;
        "text")
            generate_enhanced_text_output "$work_items_file" "$claude_response" "$days"
            ;;
        *)
            generate_enhanced_console_output "$work_items_file" "$claude_response" "$days"
            ;;
    esac
}

generate_enhanced_console_output() {
    local work_items_file="$1"
    local claude_response="$2"
    local days="$3"
    
    echo
    echo -e "${CYAN}AI TFS Ticket Analysis with Claude AI - Last $days days${NC}"
    echo "========================================================"
    echo -e "${WHITE}Generated: Generated: $(date)${NC}"
    
    # Count total items
    local total_count
    total_count=$(grep -c '"id":' "$work_items_file" || echo "0")
    echo -e "${WHITE}Authentication Status Total items: $total_count${NC}"
    echo -e "${WHITE}Enhanced with Claude AI analysis Enhanced with Claude AI analysis${NC}"
    echo
    
    # Display Claude's insights first
    echo -e "${PURPLE}Claude AI Features Claude AI Insights:${NC}"
    echo "------------------------"
    head -20 "$claude_response" 2>/dev/null || echo "Claude analysis available in detailed view"
    echo
    
    # Then display traditional analysis enhanced with any specific recommendations
    generate_console_output "$work_items_file" "$days"
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
    local use_claude_ai="false"
    local disable_ai="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            setup)
                setup_config "$use_windows_auth"
                exit 0
                ;;
            setup-claude)
                setup_claude_config
                exit 0
                ;;
            test-claude)
                test_claude_configuration
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
            # Simplified parameters
            -b|--browser)
                output_method="browser"
                ;;
            -h|--html)
                output_method="html"
                ;;
            -t|--text)
                output_method="text"
                ;;
            -e|--email)
                output_method="email"
                ;;
            -c|--claude)
                use_claude_ai="true"
                ;;
            --no-ai)
                disable_ai="true"
                ;;
            -d|--details)
                verbose="true"
                ;;
            # Traditional parameters for backward compatibility
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
            --help)
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
    
    # Determine if Claude AI should be used
    if [[ "$disable_ai" == "true" ]]; then
        use_claude_ai="false"
    elif [[ "$use_claude_ai" == "true" ]]; then
        # Verify Claude setup when explicitly requested
        log_message "INFO" "Verifying Verifying Claude AI configuration..."
        if test_claude_configuration > /dev/null 2>&1; then
            log_message "SUCCESS" "[OK] Claude AI verification passed - using AI analysis"
        else
            use_claude_ai="false"
            log_message "WARN" "[ERROR] Claude AI verification failed - falling back to traditional analysis"
            echo
            echo "Troubleshooting Tips  Quick Fixes:"
            echo "- Run: $0 setup-claude"
            echo "- Check: az login --allow-no-subscriptions"  
            echo "- Verify: Claude Code installation"
            echo
        fi
    elif [[ "$use_claude_ai" == "false" ]]; then
        # Check if Claude AI is configured by default
        local default_claude="${USE_CLAUDE_AI:-false}"
        if [[ "$default_claude" == "true" ]]; then
            # Quick verification for default usage (less verbose)
            if command -v claude-code > /dev/null 2>&1 && ( (command -v az > /dev/null 2>&1 && az account show > /dev/null 2>&1) || [[ -n "$PAT" ]] ); then
                use_claude_ai="true"
            else
                use_claude_ai="false"
                log_message "WARN" "[WARNING]  Claude AI configured by default but verification failed - using traditional analysis"
            fi
        else
            use_claude_ai="false"
        fi
    fi
    
    if [[ "$verbose" == "true" ]]; then
        log_message "INFO" "Analyzing last $days days..."
        log_message "INFO" "Output method: $output_method"
        log_message "INFO" "Claude AI: $([[ \"$use_claude_ai\" == \"true\" ]] && echo \"enabled\" || echo \"disabled\")"
    fi
    
    # Get work items
    local work_items_file
    work_items_file=$(get_work_items "$days")
    
    if [[ -z "$work_items_file" ]]; then
        exit 1
    fi
    
    # Use Claude AI analysis if enabled and available
    if [[ "$use_claude_ai" == "true" ]]; then
        local claude_error_output
        claude_error_output=$(invoke_claude_analysis "$work_items_file" "$days" "$output_method" 2>&1)
        
        if [[ $? -eq 0 ]]; then
            log_message "SUCCESS" "[OK] Analysis completed with Claude AI enhancement"
            exit 0
        else
            # Extract error message for display
            local claude_error_reason=""
            if echo "$claude_error_output" | grep -q "ERROR:"; then
                claude_error_reason=$(echo "$claude_error_output" | grep "ERROR:" | head -1 | sed 's/ERROR: //')
            else
                claude_error_reason="Unknown error occurred"
            fi
            
            log_message "INFO" "[INFO]  Falling back to traditional analysis"
            
            # Store error for summary display
            export CLAUDE_FAILURE_REASON="$claude_error_reason"
        fi
    fi
    
    # Generate traditional output
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