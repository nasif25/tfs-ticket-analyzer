#!/usr/bin/env python3
"""
TFS Ticket Analyzer - Easy Setup Wizard
Simple guided setup for non-technical users
Cross-platform Python version
"""

import os
import sys
import subprocess
import platform
import getpass
from pathlib import Path

# Color codes for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    CYAN = '\033[0;36m'
    GRAY = '\033[0;90m'
    WHITE = '\033[1;37m'
    NC = '\033[0m'  # No Color

    @staticmethod
    def is_windows():
        return platform.system() == 'Windows'

    @staticmethod
    def strip_colors_if_windows():
        """Windows cmd.exe doesn't support ANSI colors by default"""
        if Colors.is_windows():
            Colors.RED = ''
            Colors.GREEN = ''
            Colors.YELLOW = ''
            Colors.CYAN = ''
            Colors.GRAY = ''
            Colors.WHITE = ''
            Colors.NC = ''

# Initialize colors
Colors.strip_colors_if_windows()

# Global configuration
config = {
    'tfs_url': '',
    'project_name': '',
    'auth_method': '',
    'pat': '',
    'display_name': '',
    'output_method': '',
    'automation_time': ''
}

SCRIPT_DIR = Path(__file__).parent.resolve()
CONFIG_DIR = SCRIPT_DIR / '.config'
CONFIG_FILE = CONFIG_DIR / '.tfs-analyzer-config'


def clear_screen():
    """Clear the terminal screen"""
    os.system('cls' if platform.system() == 'Windows' else 'clear')


def show_welcome():
    """Display welcome screen"""
    clear_screen()
    print(f"{Colors.CYAN}╔════════════════════════════════════════════════════════════╗{Colors.NC}")
    print(f"{Colors.CYAN}║   TFS Ticket Analyzer - Easy Setup Wizard                 ║{Colors.NC}")
    print(f"{Colors.CYAN}╚════════════════════════════════════════════════════════════╝{Colors.NC}")
    print()
    print(f"{Colors.WHITE}Welcome! This wizard will help you set up your TFS Ticket Analyzer.{Colors.NC}")
    print()
    print(f"{Colors.YELLOW}What this tool does:{Colors.NC}")
    print(f"{Colors.GREEN}  ✓ Analyzes your TFS/Azure DevOps tickets{Colors.NC}")
    print(f"{Colors.GREEN}  ✓ Shows you what needs attention{Colors.NC}")
    print(f"{Colors.GREEN}  ✓ Helps prioritize your work{Colors.NC}")
    print(f"{Colors.GREEN}  ✓ Can run automatically every day{Colors.NC}")
    print()
    print(f"{Colors.WHITE}Setup takes about 2-3 minutes.{Colors.NC}")
    print()

    continue_setup = input("Ready to start? (Y/N): ").strip().upper()
    if continue_setup not in ['Y', 'YES']:
        print(f"{Colors.YELLOW}Setup cancelled. Run this script again when you're ready!{Colors.NC}")
        sys.exit(0)


def get_tfs_configuration():
    """Get TFS/Azure DevOps connection details"""
    print()
    print(f"{Colors.CYAN}════════════════════════════════════════════════════{Colors.NC}")
    print(f"{Colors.CYAN}  Step 1: TFS/Azure DevOps Connection{Colors.NC}")
    print(f"{Colors.CYAN}════════════════════════════════════════════════════{Colors.NC}")
    print()
    print(f"{Colors.WHITE}We need to know where your TFS server is located.{Colors.NC}")
    print()
    print(f"{Colors.YELLOW}Common examples:{Colors.NC}")
    print(f"{Colors.GRAY}  - https://dev.azure.com/yourcompany{Colors.NC}")
    print(f"{Colors.GRAY}  - https://tfs.yourcompany.com/tfs/YourCollection{Colors.NC}")
    print()

    # Get TFS URL
    while True:
        tfs_url = input("Enter your TFS/Azure DevOps URL: ").strip()

        if not tfs_url:
            print(f"{Colors.RED}URL cannot be empty. Please try again.{Colors.NC}")
            continue

        if not (tfs_url.startswith('http://') or tfs_url.startswith('https://')):
            print(f"{Colors.RED}URL must start with http:// or https://. Please try again.{Colors.NC}")
            continue

        config['tfs_url'] = tfs_url
        break

    # Get project name
    print()
    print(f"{Colors.WHITE}What project do you want to analyze?{Colors.NC}")
    print(f"{Colors.GRAY}(This is the name of your team project){Colors.NC}")
    print()

    while True:
        project_name = input("Enter your project name: ").strip()

        if not project_name:
            print(f"{Colors.RED}Project name cannot be empty. Please try again.{Colors.NC}")
            continue

        config['project_name'] = project_name
        break


def check_azure_cli():
    """Check if Azure CLI is installed"""
    try:
        subprocess.run(['az', '--version'],
                      stdout=subprocess.DEVNULL,
                      stderr=subprocess.DEVNULL,
                      check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def get_authentication_method():
    """Get authentication method"""
    print()
    print(f"{Colors.CYAN}════════════════════════════════════════════════════{Colors.NC}")
    print(f"{Colors.CYAN}  Step 2: Authentication Setup{Colors.NC}")
    print(f"{Colors.CYAN}════════════════════════════════════════════════════{Colors.NC}")
    print()
    print(f"{Colors.WHITE}How would you like to connect to TFS?{Colors.NC}")
    print()
    print(f"{Colors.GREEN}1. Azure CLI (Recommended - most secure){Colors.NC}")
    print(f"{Colors.GRAY}   Uses your Microsoft account to log in{Colors.NC}")
    print()
    print(f"{Colors.YELLOW}2. Personal Access Token{Colors.NC}")
    print(f"{Colors.GRAY}   Uses a password-like token you create in TFS{Colors.NC}")
    print()

    choice = input("Choose option (1 or 2): ").strip()

    if choice == "1":
        # Check if Azure CLI is installed
        if check_azure_cli():
            print()
            print(f"{Colors.GREEN}✓ Azure CLI is installed{Colors.NC}")
        else:
            print()
            print(f"{Colors.RED}Azure CLI is not installed.{Colors.NC}")
            print()
            print(f"{Colors.YELLOW}Would you like to:{Colors.NC}")
            print(f"{Colors.WHITE}  A. Install Azure CLI now{Colors.NC}")
            print(f"{Colors.WHITE}  B. Use Personal Access Token instead{Colors.NC}")
            print()

            install_choice = input("Choose (A or B): ").strip().upper()

            if install_choice == 'A':
                print()
                print(f"{Colors.CYAN}To install Azure CLI:{Colors.NC}")
                print()

                if platform.system() == 'Windows':
                    print(f"{Colors.WHITE}Download from: https://aka.ms/installazurecliwindows{Colors.NC}")
                elif platform.system() == 'Darwin':
                    print(f"{Colors.WHITE}On macOS:{Colors.NC}")
                    print(f"{Colors.GRAY}  brew install azure-cli{Colors.NC}")
                else:
                    print(f"{Colors.WHITE}On Linux (Ubuntu/Debian):{Colors.NC}")
                    print(f"{Colors.GRAY}  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash{Colors.NC}")

                print()
                print(f"{Colors.YELLOW}After installing:{Colors.NC}")
                print(f"{Colors.WHITE}  1. Close and reopen your terminal{Colors.NC}")
                print(f"{Colors.WHITE}  2. Run this setup again{Colors.NC}")
                print()
                input("Press Enter to exit")
                sys.exit(0)
            else:
                get_personal_access_token()
                return

        # Try to authenticate with Azure CLI
        print()
        print(f"{Colors.CYAN}Authenticating with Azure CLI...{Colors.NC}")
        print(f"{Colors.YELLOW}This will open your browser to log in.{Colors.NC}")
        print()

        try:
            subprocess.run(['az', 'login', '--allow-no-subscriptions'],
                          check=True,
                          stdout=subprocess.DEVNULL,
                          stderr=subprocess.DEVNULL)
            print()
            print(f"{Colors.GREEN}✓ Successfully authenticated!{Colors.NC}")
            config['auth_method'] = 'AzureCLI'
            config['pat'] = ''
        except subprocess.CalledProcessError:
            print()
            print(f"{Colors.RED}Azure CLI login failed.{Colors.NC}")
            print(f"{Colors.YELLOW}Let's try Personal Access Token instead.{Colors.NC}")
            get_personal_access_token()
    else:
        get_personal_access_token()


def get_personal_access_token():
    """Get Personal Access Token from user"""
    print()
    print(f"{Colors.CYAN}═══ Setting up Personal Access Token ═══{Colors.NC}")
    print()
    print(f"{Colors.YELLOW}To create a Personal Access Token (PAT):{Colors.NC}")
    print()
    print(f"{Colors.WHITE}1. Open your browser and go to your TFS/Azure DevOps{Colors.NC}")
    print(f"{Colors.WHITE}2. Click your profile picture (top right){Colors.NC}")
    print(f"{Colors.WHITE}3. Go to: Security > Personal Access Tokens{Colors.NC}")
    print(f"{Colors.WHITE}4. Click 'New Token'{Colors.NC}")
    print(f"{Colors.WHITE}5. Give it a name like 'TFS Analyzer'{Colors.NC}")
    print(f"{Colors.WHITE}6. Check the 'Work Items (Read)' permission{Colors.NC}")
    print(f"{Colors.WHITE}7. Click 'Create' and copy the token{Colors.NC}")
    print()

    open_browser = input("Would you like me to open your TFS page? (Y/N): ").strip().upper()
    if open_browser in ['Y', 'YES'] and config['tfs_url']:
        try:
            if platform.system() == 'Windows':
                os.startfile(config['tfs_url'])
            elif platform.system() == 'Darwin':
                subprocess.run(['open', config['tfs_url']])
            else:
                subprocess.run(['xdg-open', config['tfs_url']])
        except Exception:
            pass

    print()
    pat = getpass.getpass("Enter your Personal Access Token: ")

    config['auth_method'] = 'PAT'
    config['pat'] = pat


def get_user_display_name():
    """Get user's display name"""
    print()
    print(f"{Colors.CYAN}════════════════════════════════════════════════════{Colors.NC}")
    print(f"{Colors.CYAN}  Step 3: Your Display Name{Colors.NC}")
    print(f"{Colors.CYAN}════════════════════════════════════════════════════{Colors.NC}")
    print()
    print(f"{Colors.WHITE}What is your display name in TFS/Azure DevOps?{Colors.NC}")
    print(f"{Colors.GRAY}This helps find tickets where you're mentioned.{Colors.NC}")
    print()
    print(f"{Colors.YELLOW}Examples: 'John Smith', 'Jane Doe'{Colors.NC}")
    print()

    while True:
        display_name = input("Enter your display name: ").strip()

        if not display_name:
            print(f"{Colors.RED}Display name cannot be empty. Please try again.{Colors.NC}")
            continue

        config['display_name'] = display_name
        break


def get_output_preference():
    """Get output preference"""
    print()
    print(f"{Colors.CYAN}════════════════════════════════════════════════════{Colors.NC}")
    print(f"{Colors.CYAN}  Step 4: How to Show Results{Colors.NC}")
    print(f"{Colors.CYAN}════════════════════════════════════════════════════{Colors.NC}")
    print()
    print(f"{Colors.WHITE}How would you like to see your ticket analysis?{Colors.NC}")
    print()
    print(f"{Colors.GREEN}1. Open in Browser (Recommended){Colors.NC}")
    print(f"{Colors.GRAY}   Opens a nice HTML report automatically{Colors.NC}")
    print()
    print(f"{Colors.YELLOW}2. Save HTML File{Colors.NC}")
    print(f"{Colors.GRAY}   Saves report to your Downloads/Documents folder{Colors.NC}")
    print()
    print(f"{Colors.YELLOW}3. Show in Terminal{Colors.NC}")
    print(f"{Colors.GRAY}   Displays results right here{Colors.NC}")
    print()

    choice = input("Choose option (1, 2, or 3): ").strip()

    output_methods = {
        '1': 'browser',
        '2': 'html',
        '3': 'console'
    }

    config['output_method'] = output_methods.get(choice, 'browser')


def get_automation_preference():
    """Get automation preference"""
    print()
    print(f"{Colors.CYAN}════════════════════════════════════════════════════{Colors.NC}")
    print(f"{Colors.CYAN}  Step 5: Automatic Daily Analysis (Optional){Colors.NC}")
    print(f"{Colors.CYAN}════════════════════════════════════════════════════{Colors.NC}")
    print()
    print(f"{Colors.WHITE}Would you like to run the analysis automatically every day?{Colors.NC}")
    print()
    print(f"{Colors.YELLOW}If yes, it will:{Colors.NC}")
    print(f"{Colors.WHITE}  - Run once per day at your chosen time{Colors.NC}")
    print(f"{Colors.WHITE}  - Show you your tickets automatically{Colors.NC}")
    print(f"{Colors.WHITE}  - Save you time remembering to check{Colors.NC}")
    print()

    automate = input("Set up automatic daily analysis? (Y/N): ").strip().upper()

    if automate not in ['Y', 'YES']:
        config['automation_time'] = ''
        return

    print()
    print(f"{Colors.WHITE}What time should it run?{Colors.NC}")
    print(f"{Colors.GRAY}Enter time in 24-hour format (e.g., 08:00 for 8 AM, 14:30 for 2:30 PM){Colors.NC}")
    print()

    while True:
        time_str = input("Enter time (default: 08:00): ").strip()

        if not time_str:
            time_str = "08:00"
            break

        # Validate time format HH:MM
        import re
        if not re.match(r'^\d{1,2}:\d{2}$', time_str):
            print(f"{Colors.RED}Invalid time format. Please use HH:MM format (e.g., 08:00){Colors.NC}")
            continue

        # Validate hour and minute ranges
        try:
            hour, minute = map(int, time_str.split(':'))

            if hour < 0 or hour > 23 or minute < 0 or minute > 59:
                print(f"{Colors.RED}Invalid time. Hour must be 0-23, minute must be 0-59.{Colors.NC}")
                continue

            # Normalize format to HH:MM
            time_str = f"{hour:02d}:{minute:02d}"
            break
        except ValueError:
            print(f"{Colors.RED}Invalid time format. Please try again.{Colors.NC}")
            continue

    config['automation_time'] = time_str


def save_configuration():
    """Save configuration to file"""
    print()
    print(f"{Colors.CYAN}Saving configuration...{Colors.NC}")

    # Create config directory
    CONFIG_DIR.mkdir(exist_ok=True)

    # Set restrictive permissions on Unix-like systems
    if platform.system() != 'Windows':
        os.chmod(CONFIG_DIR, 0o700)

    # Save configuration file
    with open(CONFIG_FILE, 'w') as f:
        f.write(f"TFS_URL={config['tfs_url']}\n")
        f.write(f"PROJECT_NAME={config['project_name']}\n")
        f.write(f"USER_DISPLAY_NAME={config['display_name']}\n")
        f.write(f"DEFAULT_OUTPUT={config['output_method']}\n")
        f.write("USE_WINDOWS_AUTH=false\n")

        if config['auth_method'] == 'PAT':
            f.write(f"PAT={config['pat']}\n")

    # Set restrictive permissions on Unix-like systems
    if platform.system() != 'Windows':
        os.chmod(CONFIG_FILE, 0o600)

    print(f"{Colors.GREEN}✓ Configuration saved{Colors.NC}")


def test_configuration():
    """Test TFS connection"""
    print()
    print(f"{Colors.CYAN}Testing connection to TFS...{Colors.NC}")

    script_path = SCRIPT_DIR / 'tfs-analyzer.py'

    if not script_path.exists():
        print(f"{Colors.RED}Error: tfs-analyzer.py not found{Colors.NC}")
        return False

    try:
        result = subprocess.run([sys.executable, str(script_path), '--test-auth'],
                              stdout=subprocess.DEVNULL,
                              stderr=subprocess.DEVNULL,
                              check=True)
        return True
    except subprocess.CalledProcessError:
        print()
        print(f"{Colors.RED}Connection test failed.{Colors.NC}")
        return False


def setup_automation():
    """Setup automation (cron on Unix, Task Scheduler on Windows)"""
    print()
    print(f"{Colors.CYAN}Setting up automatic daily analysis...{Colors.NC}")

    if platform.system() == 'Windows':
        scheduler_script = SCRIPT_DIR / 'tfs-scheduler-daily.ps1'

        if scheduler_script.exists():
            try:
                # Check if running as admin
                import ctypes
                is_admin = ctypes.windll.shell32.IsUserAnAdmin()

                if not is_admin:
                    print()
                    print(f"{Colors.YELLOW}⚠ Administrator privileges required for automation setup{Colors.NC}")
                    print()
                    print(f"{Colors.WHITE}To set up automation:{Colors.NC}")
                    print(f"{Colors.GRAY}  1. Right-click PowerShell{Colors.NC}")
                    print(f"{Colors.GRAY}  2. Select 'Run as Administrator'{Colors.NC}")
                    print(f"{Colors.GRAY}  3. Run: .\\tfs-scheduler-daily.ps1 -Time '{config['automation_time']}' -OutputMethod '{config['output_method']}'{Colors.NC}")
                    print()
                    return

                subprocess.run(['powershell', '-ExecutionPolicy', 'Bypass', '-File', str(scheduler_script),
                              '-Time', config['automation_time'], '-OutputMethod', config['output_method']],
                              check=True)
                print(f"{Colors.GREEN}✓ Automation configured!{Colors.NC}")
            except Exception as e:
                print(f"{Colors.YELLOW}⚠ Automation setup failed{Colors.NC}")
                print(f"{Colors.WHITE}You can set it up later using tfs-scheduler-daily.ps1{Colors.NC}")
    else:
        scheduler_script = SCRIPT_DIR / 'tfs-scheduler.sh'

        if scheduler_script.exists():
            try:
                subprocess.run(['bash', str(scheduler_script), '--time', config['automation_time'],
                              '--output', config['output_method']],
                              check=True,
                              stdout=subprocess.DEVNULL,
                              stderr=subprocess.DEVNULL)
                print(f"{Colors.GREEN}✓ Automation configured!{Colors.NC}")
            except Exception:
                print(f"{Colors.YELLOW}⚠ Automation setup failed{Colors.NC}")
                print(f"{Colors.WHITE}You can set it up later by running:{Colors.NC}")
                print(f"{Colors.GRAY}  ./tfs-scheduler.sh --time '{config['automation_time']}' --output '{config['output_method']}'{Colors.NC}")


def show_completion_summary():
    """Show completion summary"""
    print()
    print(f"{Colors.GREEN}╔════════════════════════════════════════════════════════════╗{Colors.NC}")
    print(f"{Colors.GREEN}║   Setup Complete! ✓                                       ║{Colors.NC}")
    print(f"{Colors.GREEN}╚════════════════════════════════════════════════════════════╝{Colors.NC}")
    print()
    print(f"{Colors.WHITE}Your TFS Ticket Analyzer is ready to use!{Colors.NC}")
    print()
    print(f"{Colors.CYAN}═══ Quick Start Commands ═══{Colors.NC}")
    print()
    print(f"{Colors.YELLOW}Analyze today's tickets:{Colors.NC}")
    print(f"{Colors.WHITE}  python tfs-analyzer.py 1 --browser{Colors.NC}")
    print()
    print(f"{Colors.YELLOW}Analyze last 7 days:{Colors.NC}")
    print(f"{Colors.WHITE}  python tfs-analyzer.py 7 --browser{Colors.NC}")
    print()
    print(f"{Colors.YELLOW}Get help:{Colors.NC}")
    print(f"{Colors.WHITE}  python tfs-analyzer.py --help{Colors.NC}")
    print()

    if config['automation_time']:
        print(f"{Colors.CYAN}═══ Automation ═══{Colors.NC}")
        print(f"{Colors.WHITE}Your analyzer will run automatically every day at {config['automation_time']}{Colors.NC}")
        print()

    print(f"{Colors.CYAN}═══ Configuration Saved To ═══{Colors.NC}")
    print(f"{Colors.GRAY}  {CONFIG_DIR}{Colors.NC}")
    print()
    print(f"{Colors.YELLOW}Need help? Check the README.md file for more details.{Colors.NC}")
    print()


def main():
    """Main setup flow"""
    try:
        # Show welcome screen
        show_welcome()

        # Step 1: TFS Configuration
        get_tfs_configuration()

        # Step 2: Authentication
        get_authentication_method()

        # Step 3: Display Name
        get_user_display_name()

        # Step 4: Output Preference
        get_output_preference()

        # Step 5: Automation
        get_automation_preference()

        # Save configuration
        save_configuration()

        # Test configuration
        if not test_configuration():
            print()
            print(f"{Colors.YELLOW}Setup completed but connection test failed.{Colors.NC}")
            print(f"{Colors.YELLOW}Please verify your TFS URL and credentials.{Colors.NC}")
            print()
            input("Press Enter to exit")
            sys.exit(1)

        # Setup automation if requested
        if config['automation_time']:
            setup_automation()

        # Show completion summary
        show_completion_summary()

        # Offer to run now
        run_now = input("Would you like to run the analyzer now? (Y/N): ").strip().upper()
        if run_now in ['Y', 'YES']:
            print()
            print(f"{Colors.CYAN}Running TFS Ticket Analyzer...{Colors.NC}")
            script_path = SCRIPT_DIR / 'tfs-analyzer.py'
            subprocess.run([sys.executable, str(script_path), '1', '--browser'])

    except KeyboardInterrupt:
        print()
        print(f"{Colors.YELLOW}Setup cancelled by user.{Colors.NC}")
        sys.exit(0)
    except Exception as e:
        print()
        print(f"{Colors.RED}Setup failed: {e}{Colors.NC}")
        print()
        print(f"{Colors.YELLOW}Please try again or use manual setup:{Colors.NC}")
        print(f"{Colors.WHITE}  python tfs-analyzer.py --setup{Colors.NC}")
        print()
        sys.exit(1)


if __name__ == '__main__':
    main()
