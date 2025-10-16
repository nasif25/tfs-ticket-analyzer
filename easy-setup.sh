#!/bin/bash
# TFS Ticket Analyzer - Easy Setup Wizard
# Simple guided setup for non-technical users

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/.config"
CONFIG_FILE="$CONFIG_DIR/.tfs-analyzer-config"

# Configuration variables
TFS_URL=""
PROJECT_NAME=""
AUTH_METHOD=""
PAT=""
DISPLAY_NAME=""
OUTPUT_METHOD=""
AUTOMATION_TIME=""

show_welcome() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   TFS Ticket Analyzer - Easy Setup Wizard                 ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}Welcome! This wizard will help you set up your TFS Ticket Analyzer.${NC}"
    echo ""
    echo -e "${YELLOW}What this tool does:${NC}"
    echo -e "${GREEN}  ✓ Analyzes your TFS/Azure DevOps tickets${NC}"
    echo -e "${GREEN}  ✓ Shows you what needs attention${NC}"
    echo -e "${GREEN}  ✓ Helps prioritize your work${NC}"
    echo -e "${GREEN}  ✓ Can run automatically every day${NC}"
    echo ""
    echo -e "${WHITE}Setup takes about 2-3 minutes.${NC}"
    echo ""

    read -p "Ready to start? (Y/N): " continue
    if [[ ! "$continue" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Setup cancelled. Run this script again when you're ready!${NC}"
        exit 0
    fi
}

get_tfs_configuration() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Step 1: TFS/Azure DevOps Connection${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}We need to know where your TFS server is located.${NC}"
    echo ""
    echo -e "${YELLOW}Common examples:${NC}"
    echo -e "${GRAY}  - https://dev.azure.com/yourcompany${NC}"
    echo -e "${GRAY}  - https://tfs.yourcompany.com/tfs/YourCollection${NC}"
    echo ""

    while true; do
        read -p "Enter your TFS/Azure DevOps URL: " TFS_URL
        TFS_URL=$(echo "$TFS_URL" | xargs) # Trim whitespace

        if [[ -z "$TFS_URL" ]]; then
            echo -e "${RED}URL cannot be empty. Please try again.${NC}"
            continue
        fi

        if [[ ! "$TFS_URL" =~ ^https?:// ]]; then
            echo -e "${RED}URL must start with http:// or https://. Please try again.${NC}"
            continue
        fi

        break
    done

    echo ""
    echo -e "${WHITE}What project do you want to analyze?${NC}"
    echo -e "${GRAY}(This is the name of your team project)${NC}"
    echo ""

    while true; do
        read -p "Enter your project name: " PROJECT_NAME
        PROJECT_NAME=$(echo "$PROJECT_NAME" | xargs) # Trim whitespace

        if [[ -z "$PROJECT_NAME" ]]; then
            echo -e "${RED}Project name cannot be empty. Please try again.${NC}"
            continue
        fi

        break
    done
}

get_authentication_method() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Step 2: Authentication Setup${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}How would you like to connect to TFS?${NC}"
    echo ""
    echo -e "${GREEN}1. Azure CLI (Recommended - most secure)${NC}"
    echo -e "${GRAY}   Uses your Microsoft account to log in${NC}"
    echo ""
    echo -e "${YELLOW}2. Personal Access Token${NC}"
    echo -e "${GRAY}   Uses a password-like token you create in TFS${NC}"
    echo ""

    read -p "Choose option (1 or 2): " choice

    if [[ "$choice" == "1" ]]; then
        # Check if Azure CLI is installed
        if command -v az &> /dev/null; then
            echo ""
            echo -e "${GREEN}✓ Azure CLI is installed${NC}"
        else
            echo ""
            echo -e "${RED}Azure CLI is not installed.${NC}"
            echo ""
            echo -e "${YELLOW}Would you like to:${NC}"
            echo -e "${WHITE}  A. Install Azure CLI now${NC}"
            echo -e "${WHITE}  B. Use Personal Access Token instead${NC}"
            echo ""

            read -p "Choose (A or B): " install_choice

            if [[ "$install_choice" =~ ^[Aa]$ ]]; then
                echo ""
                echo -e "${CYAN}To install Azure CLI:${NC}"
                echo ""
                echo -e "${WHITE}On Linux (Ubuntu/Debian):${NC}"
                echo -e "${GRAY}  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash${NC}"
                echo ""
                echo -e "${WHITE}On macOS:${NC}"
                echo -e "${GRAY}  brew install azure-cli${NC}"
                echo ""
                echo -e "${YELLOW}After installing:${NC}"
                echo -e "${WHITE}  1. Close and reopen your terminal${NC}"
                echo -e "${WHITE}  2. Run this setup again${NC}"
                echo ""
                read -p "Press Enter to exit"
                exit 0
            else
                get_personal_access_token
                return
            fi
        fi

        # Try to authenticate with Azure CLI
        echo ""
        echo -e "${CYAN}Authenticating with Azure CLI...${NC}"
        echo -e "${YELLOW}This will open your browser to log in.${NC}"
        echo ""

        if az login --allow-no-subscriptions &> /dev/null; then
            echo ""
            echo -e "${GREEN}✓ Successfully authenticated!${NC}"
            AUTH_METHOD="AzureCLI"
            PAT=""
        else
            echo ""
            echo -e "${RED}Azure CLI login failed.${NC}"
            echo -e "${YELLOW}Let's try Personal Access Token instead.${NC}"
            get_personal_access_token
        fi
    else
        get_personal_access_token
    fi
}

get_personal_access_token() {
    echo ""
    echo -e "${CYAN}═══ Setting up Personal Access Token ═══${NC}"
    echo ""
    echo -e "${YELLOW}To create a Personal Access Token (PAT):${NC}"
    echo ""
    echo -e "${WHITE}1. Open your browser and go to your TFS/Azure DevOps${NC}"
    echo -e "${WHITE}2. Click your profile picture (top right)${NC}"
    echo -e "${WHITE}3. Go to: Security > Personal Access Tokens${NC}"
    echo -e "${WHITE}4. Click 'New Token'${NC}"
    echo -e "${WHITE}5. Give it a name like 'TFS Analyzer'${NC}"
    echo -e "${WHITE}6. Check the 'Work Items (Read)' permission${NC}"
    echo -e "${WHITE}7. Click 'Create' and copy the token${NC}"
    echo ""

    read -p "Would you like me to open your TFS page? (Y/N): " open_browser
    if [[ "$open_browser" =~ ^[Yy]$ ]] && [[ -n "$TFS_URL" ]]; then
        if command -v xdg-open &> /dev/null; then
            xdg-open "$TFS_URL" 2>/dev/null &
        elif command -v open &> /dev/null; then
            open "$TFS_URL" 2>/dev/null &
        fi
    fi

    echo ""
    read -s -p "Enter your Personal Access Token: " PAT
    echo ""

    AUTH_METHOD="PAT"
}

get_user_display_name() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Step 3: Your Display Name${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}What is your display name in TFS/Azure DevOps?${NC}"
    echo -e "${GRAY}This helps find tickets where you're mentioned.${NC}"
    echo ""
    echo -e "${YELLOW}Examples: 'John Smith', 'Jane Doe'${NC}"
    echo ""

    while true; do
        read -p "Enter your display name: " DISPLAY_NAME
        DISPLAY_NAME=$(echo "$DISPLAY_NAME" | xargs) # Trim whitespace

        if [[ -z "$DISPLAY_NAME" ]]; then
            echo -e "${RED}Display name cannot be empty. Please try again.${NC}"
            continue
        fi

        break
    done
}

get_output_preference() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Step 4: How to Show Results${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}How would you like to see your ticket analysis?${NC}"
    echo ""
    echo -e "${GREEN}1. Open in Browser (Recommended)${NC}"
    echo -e "${GRAY}   Opens a nice HTML report automatically${NC}"
    echo ""
    echo -e "${YELLOW}2. Save HTML File${NC}"
    echo -e "${GRAY}   Saves report to your Downloads/Documents folder${NC}"
    echo ""
    echo -e "${YELLOW}3. Show in Terminal${NC}"
    echo -e "${GRAY}   Displays results right here${NC}"
    echo ""

    read -p "Choose option (1, 2, or 3): " choice

    case "$choice" in
        1) OUTPUT_METHOD="browser" ;;
        2) OUTPUT_METHOD="html" ;;
        3) OUTPUT_METHOD="console" ;;
        *) OUTPUT_METHOD="browser" ;;
    esac
}

get_automation_preference() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Step 5: Automatic Daily Analysis (Optional)${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}Would you like to run the analysis automatically every day?${NC}"
    echo ""
    echo -e "${YELLOW}If yes, it will:${NC}"
    echo -e "${WHITE}  - Run once per day at your chosen time${NC}"
    echo -e "${WHITE}  - Show you your tickets automatically${NC}"
    echo -e "${WHITE}  - Save you time remembering to check${NC}"
    echo ""

    read -p "Set up automatic daily analysis? (Y/N): " automate

    if [[ ! "$automate" =~ ^[Yy]$ ]]; then
        AUTOMATION_TIME=""
        return
    fi

    echo ""
    echo -e "${WHITE}What time should it run?${NC}"
    echo -e "${GRAY}Enter time in 24-hour format (e.g., 08:00 for 8 AM, 14:30 for 2:30 PM)${NC}"
    echo ""

    while true; do
        read -p "Enter time (default: 08:00): " time

        if [[ -z "$time" ]]; then
            time="08:00"
            break
        fi

        # Validate time format HH:MM
        if [[ ! "$time" =~ ^[0-9]{1,2}:[0-9]{2}$ ]]; then
            echo -e "${RED}Invalid time format. Please use HH:MM format (e.g., 08:00)${NC}"
            continue
        fi

        # Validate hour and minute ranges
        hour=$(echo "$time" | cut -d':' -f1)
        minute=$(echo "$time" | cut -d':' -f2)

        # Remove leading zeros
        hour=$((10#$hour))
        minute=$((10#$minute))

        if [[ $hour -lt 0 || $hour -gt 23 || $minute -lt 0 || $minute -gt 59 ]]; then
            echo -e "${RED}Invalid time. Hour must be 0-23, minute must be 0-59.${NC}"
            continue
        fi

        # Normalize format to HH:MM
        time=$(printf "%02d:%02d" $hour $minute)
        break
    done

    AUTOMATION_TIME="$time"
}

save_configuration() {
    echo ""
    echo -e "${CYAN}Saving configuration...${NC}"

    # Create config directory
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"

    # Save configuration file
    cat > "$CONFIG_FILE" << EOF
TFS_URL=$TFS_URL
PROJECT_NAME=$PROJECT_NAME
USER_DISPLAY_NAME=$DISPLAY_NAME
DEFAULT_OUTPUT=$OUTPUT_METHOD
USE_WINDOWS_AUTH=false
EOF

    if [[ "$AUTH_METHOD" == "PAT" ]]; then
        echo "PAT=$PAT" >> "$CONFIG_FILE"
    fi

    # Set restrictive permissions
    chmod 600 "$CONFIG_FILE"

    echo -e "${GREEN}✓ Configuration saved${NC}"
}

test_configuration() {
    echo ""
    echo -e "${CYAN}Testing connection to TFS...${NC}"

    local script_path="$SCRIPT_DIR/tfs-analyzer.sh"

    if [[ -f "$script_path" ]]; then
        if bash "$script_path" test-auth &> /dev/null; then
            return 0
        else
            echo ""
            echo -e "${RED}Connection test failed.${NC}"
            return 1
        fi
    else
        echo -e "${RED}Error: tfs-analyzer.sh not found${NC}"
        return 1
    fi
}

setup_automation() {
    echo ""
    echo -e "${CYAN}Setting up automatic daily analysis...${NC}"

    local scheduler_script="$SCRIPT_DIR/tfs-scheduler.sh"

    if [[ -f "$scheduler_script" ]]; then
        if bash "$scheduler_script" --time "$AUTOMATION_TIME" --output "$OUTPUT_METHOD" &> /dev/null; then
            echo -e "${GREEN}✓ Automation configured!${NC}"
        else
            echo -e "${YELLOW}⚠ Automation setup failed${NC}"
            echo -e "${WHITE}You can set it up later by running:${NC}"
            echo -e "${GRAY}  ./tfs-scheduler.sh --time '$AUTOMATION_TIME' --output '$OUTPUT_METHOD'${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Scheduler script not found${NC}"
        echo -e "${WHITE}You can set up automation manually later.${NC}"
    fi
}

show_completion_summary() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Setup Complete! ✓                                       ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}Your TFS Ticket Analyzer is ready to use!${NC}"
    echo ""
    echo -e "${CYAN}═══ Quick Start Commands ═══${NC}"
    echo ""
    echo -e "${YELLOW}Analyze today's tickets:${NC}"
    echo -e "${WHITE}  ./tfs-analyzer.sh 1 --browser${NC}"
    echo ""
    echo -e "${YELLOW}Analyze last 7 days:${NC}"
    echo -e "${WHITE}  ./tfs-analyzer.sh 7 --browser${NC}"
    echo ""
    echo -e "${YELLOW}Get help:${NC}"
    echo -e "${WHITE}  ./tfs-analyzer.sh --help${NC}"
    echo ""

    if [[ -n "$AUTOMATION_TIME" ]]; then
        echo -e "${CYAN}═══ Automation ═══${NC}"
        echo -e "${WHITE}Your analyzer will run automatically every day at $AUTOMATION_TIME${NC}"
        echo ""
    fi

    echo -e "${CYAN}═══ Configuration Saved To ═══${NC}"
    echo -e "${GRAY}  $CONFIG_DIR/${NC}"
    echo ""
    echo -e "${YELLOW}Need help? Check the README.md file for more details.${NC}"
    echo ""
}

# Main Setup Flow
main() {
    # Show welcome screen
    show_welcome

    # Step 1: TFS Configuration
    get_tfs_configuration

    # Step 2: Authentication
    get_authentication_method

    # Step 3: Display Name
    get_user_display_name

    # Step 4: Output Preference
    get_output_preference

    # Step 5: Automation
    get_automation_preference

    # Save configuration
    save_configuration

    # Test configuration
    if ! test_configuration; then
        echo ""
        echo -e "${YELLOW}Setup completed but connection test failed.${NC}"
        echo -e "${YELLOW}Please verify your TFS URL and credentials.${NC}"
        echo ""
        read -p "Press Enter to exit"
        exit 1
    fi

    # Setup automation if requested
    if [[ -n "$AUTOMATION_TIME" ]]; then
        setup_automation
    fi

    # Show completion summary
    show_completion_summary

    # Offer to run now
    echo ""
    read -p "Would you like to run the analyzer now? (Y/N): " run_now
    if [[ "$run_now" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${CYAN}Running TFS Ticket Analyzer...${NC}"
        bash "$SCRIPT_DIR/tfs-analyzer.sh" 1 --browser
    fi
}

# Run main function
main
