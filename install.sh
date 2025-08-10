#!/bin/bash

# install.sh - Installation and setup script for NTP Tools
# Part of NTP Tools suite using Chrony

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default installation directory
INSTALL_DIR="/usr/local/bin"
USER_INSTALL_DIR="$HOME/.local/bin"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Installation flags
SYSTEM_INSTALL=false
USER_INSTALL=false
CHECK_DEPS=false

# Function to show help
show_help() {
    echo "NTP Tools Installation Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -h, --help         Show this help message"
    echo "  -s, --system       Install system-wide (requires sudo)"
    echo "  -u, --user         Install for current user only"
    echo "  -c, --check        Check dependencies only"
    echo "  --prefix DIR       Custom installation directory"
    echo
    echo "Examples:"
    echo "  $0 --user          # Install for current user"
    echo "  $0 --system        # System install"
    echo "  $0 --check         # Check dependencies only"
}

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[ERROR] $message${NC}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN] $message${NC}" >&2
            ;;
        "INFO")
            echo -e "${GREEN}[INFO] $message${NC}"
            ;;
        "DEBUG")
            echo -e "${BLUE}[DEBUG] $message${NC}"
            ;;
    esac
}

# Function to check if running as root
is_root() {
    [ "$(id -u)" = "0" ]
}

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif command -v lsb_release >/dev/null 2>&1; then
        lsb_release -si | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

# Function to install dependencies
check_dependencies() {
    local os
    os=$(detect_os)
    
    log_message "INFO" "Checking dependencies for: $os"
    
    local missing_deps=()
    local optional_missing=()
    
    # Required dependencies
    for dep in bash nc host ping; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    # Optional but recommended dependencies
    for dep in chronyc ntpdate bc; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            optional_missing+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_message "ERROR" "Missing required dependencies: ${missing_deps[*]}"
        log_message "INFO" "Please install them manually based on your distribution:"
        case "$os" in
            ubuntu|debian)
                echo "  sudo apt update && sudo apt install -y chrony bc netcat-openbsd dnsutils iputils-ping"
                ;;
            centos|rhel|fedora)
                echo "  sudo dnf install -y chrony bc nc bind-utils iputils"
                ;;
            arch)
                echo "  sudo pacman -S chrony bc gnu-netcat bind iputils"
                ;;
            *)
                echo "  Install: chrony, bc, netcat, dnsutils, iputils-ping"
                ;;
        esac
        return 1
    fi
    
    if [ ${#optional_missing[@]} -gt 0 ]; then
        log_message "WARN" "Missing optional dependencies: ${optional_missing[*]}"
        log_message "INFO" "Some features may not work optimally without them"
    else
        log_message "INFO" "All dependencies are available"
    fi
    
    # Check if chrony is running
    if ! systemctl is-active --quiet chronyd 2>/dev/null; then
        log_message "WARN" "Chrony daemon is not running"
        log_message "INFO" "Start it with: sudo systemctl start chronyd"
        log_message "INFO" "Enable at boot: sudo systemctl enable chronyd"
    else
        log_message "INFO" "Chrony daemon is running"
    fi
    
    return 0
}

# Function to setup chrony
check_chrony_status() {
    log_message "INFO" "Checking chrony status..."
    
    if ! command -v chronyc >/dev/null 2>&1; then
        log_message "ERROR" "Chrony is not installed"
        log_message "INFO" "Please install chrony first:"
        echo "  Debian/Ubuntu: sudo apt install chrony"
        echo "  RHEL/CentOS: sudo dnf install chrony"
        echo "  Arch: sudo pacman -S chrony"
        return 1
    fi
    
    if ! systemctl is-active --quiet chronyd 2>/dev/null; then
        log_message "ERROR" "Chrony daemon is not running"
        log_message "INFO" "Start it with: sudo systemctl start chronyd"
        log_message "INFO" "Enable at boot: sudo systemctl enable chronyd"
        return 1
    fi
    
    log_message "INFO" "Chrony is installed and running"
    return 0
}

# Function to install tools
install_tools() {
    local target_dir="$1"
    
    log_message "INFO" "Installing NTP tools to $target_dir"
    
    # Create target directory if it doesn't exist
    if [ ! -d "$target_dir" ]; then
        if [ "$SYSTEM_INSTALL" = true ]; then
            if is_root; then
                mkdir -p "$target_dir"
            else
                sudo mkdir -p "$target_dir"
            fi
        else
            mkdir -p "$target_dir"
        fi
    fi
    
    # Copy tools
    local tools=("gettime" "ntpdetail" "monitor" "timediff" "ntpcheck")
    
    for tool in "${tools[@]}"; do
        local src_file="$CURRENT_DIR/bin/$tool"
        local dst_file="$target_dir/$tool"
        
        if [ -f "$src_file" ]; then
            log_message "INFO" "Installing $tool..."
            
            if [ "$SYSTEM_INSTALL" = true ]; then
                if is_root; then
                    cp "$src_file" "$dst_file"
                    chmod 755 "$dst_file"
                else
                    sudo cp "$src_file" "$dst_file"
                    sudo chmod 755 "$dst_file"
                fi
            else
                cp "$src_file" "$dst_file"
                chmod 755 "$dst_file"
            fi
        else
            log_message "ERROR" "Source file not found: $src_file"
            return 1
        fi
    done
    
    # Install library
    local lib_target_dir
    if [ "$SYSTEM_INSTALL" = true ]; then
        lib_target_dir="/usr/local/lib/ntp-tools"
    else
        lib_target_dir="$HOME/.local/lib/ntp-tools"
    fi
    
    log_message "INFO" "Installing library to $lib_target_dir"
    
    if [ "$SYSTEM_INSTALL" = true ]; then
        if is_root; then
            mkdir -p "$lib_target_dir"
            cp "$CURRENT_DIR/lib/ntp_common.sh" "$lib_target_dir/"
            chmod 644 "$lib_target_dir/ntp_common.sh"
        else
            sudo mkdir -p "$lib_target_dir"
            sudo cp "$CURRENT_DIR/lib/ntp_common.sh" "$lib_target_dir/"
            sudo chmod 644 "$lib_target_dir/ntp_common.sh"
        fi
    else
        mkdir -p "$lib_target_dir"
        cp "$CURRENT_DIR/lib/ntp_common.sh" "$lib_target_dir/"
        chmod 644 "$lib_target_dir/ntp_common.sh"
    fi
    
    # Update library path in tools
    for tool in "${tools[@]}"; do
        local tool_file="$target_dir/$tool"
        if [ -f "$tool_file" ]; then
            # Update the LIB_DIR path in each tool
            if [ "$SYSTEM_INSTALL" = true ]; then
                if is_root; then
                    sed -i "s|LIB_DIR=\".*\"|LIB_DIR=\"$lib_target_dir\"|" "$tool_file"
                else
                    sudo sed -i "s|LIB_DIR=\".*\"|LIB_DIR=\"$lib_target_dir\"|" "$tool_file"
                fi
            else
                sed -i "s|LIB_DIR=\".*\"|LIB_DIR=\"$lib_target_dir\"|" "$tool_file"
            fi
        fi
    done
    
    log_message "INFO" "NTP tools installation completed successfully"
}

# Function to update PATH
update_path() {
    local bin_dir="$1"
    
    if [ "$USER_INSTALL" = true ]; then
        # Add to user's PATH
        local shell_rc=""
        if [ -n "$BASH_VERSION" ]; then
            shell_rc="$HOME/.bashrc"
        elif [ -n "$ZSH_VERSION" ]; then
            shell_rc="$HOME/.zshrc"
        else
            shell_rc="$HOME/.profile"
        fi
        
        if [ -f "$shell_rc" ]; then
            if ! grep -q "$bin_dir" "$shell_rc"; then
                echo "export PATH=\"$bin_dir:\$PATH\"" >> "$shell_rc"
                log_message "INFO" "Added $bin_dir to PATH in $shell_rc"
                log_message "INFO" "Please run: source $shell_rc or restart your shell"
            fi
        fi
    fi
}

# Function to run post-installation tests
run_tests() {
    local bin_dir="$1"
    
    log_message "INFO" "Running post-installation tests..."
    
    # Test if tools are accessible
    local tools=("gettime" "ntpdetail" "monitor" "timediff" "ntpcheck")
    
    for tool in "${tools[@]}"; do
        local tool_path="$bin_dir/$tool"
        if [ -x "$tool_path" ]; then
            log_message "INFO" "✓ $tool is installed and executable"
        else
            log_message "ERROR" "✗ $tool is not properly installed"
            return 1
        fi
    done
    
    # Test a simple command
    log_message "INFO" "Testing gettime with help option..."
    if "$bin_dir/gettime" --help >/dev/null 2>&1; then
        log_message "INFO" "✓ Tools are working correctly"
    else
        log_message "ERROR" "✗ Tools are not working properly"
        return 1
    fi
    
    log_message "INFO" "All tests passed!"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--system)
            SYSTEM_INSTALL=true
            USER_INSTALL=false
            INSTALL_DIR="/usr/local/bin"
            shift
            ;;
        -u|--user)
            USER_INSTALL=true
            SYSTEM_INSTALL=false
            INSTALL_DIR="$USER_INSTALL_DIR"
            shift
            ;;
        -c|--check)
            CHECK_DEPS=true
            shift
            ;;
        --prefix)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -*)
            log_message "ERROR" "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            log_message "ERROR" "Unexpected argument: $1"
            show_help
            exit 1
            ;;
    esac
done

# Default to user install if no option specified
if [ "$SYSTEM_INSTALL" = false ] && [ "$USER_INSTALL" = false ]; then
    USER_INSTALL=true
    INSTALL_DIR="$USER_INSTALL_DIR"
fi

# Main installation process
echo -e "${BLUE}=== NTP Tools Installation Script ===${NC}"
echo "Installation mode: $([ "$SYSTEM_INSTALL" = true ] && echo "System-wide" || echo "User")"
echo "Target directory: $INSTALL_DIR"
echo "Check dependencies: $CHECK_DEPS"
echo

# Check if source files exist
if [ ! -d "$CURRENT_DIR/bin" ] || [ ! -f "$CURRENT_DIR/lib/ntp_common.sh" ]; then
    log_message "ERROR" "Source files not found. Please run this script from the ntp-tools directory."
    exit 1
fi

# Check dependencies
if [ "$CHECK_DEPS" = true ]; then
    log_message "INFO" "Checking dependencies only..."
    check_dependencies
    exit $?
fi

# Always check dependencies before installation
log_message "INFO" "Checking dependencies..."
if ! check_dependencies; then
    log_message "ERROR" "Please install missing dependencies before proceeding"
    exit 1
fi
echo

# Install the tools
if ! install_tools "$INSTALL_DIR"; then
    log_message "ERROR" "Failed to install tools"
    exit 1
fi

# Update PATH if user install
if [ "$USER_INSTALL" = true ]; then
    update_path "$INSTALL_DIR"
fi

echo

# Run tests
if ! run_tests "$INSTALL_DIR"; then
    log_message "ERROR" "Post-installation tests failed"
    exit 1
fi

echo
log_message "INFO" "Installation completed successfully!"
echo
echo -e "${GREEN}Next steps:${NC}"
echo "1. If this was a user installation, restart your shell or run:"
echo "   export PATH=\"$INSTALL_DIR:\$PATH\""
echo
echo "2. Test the installation:"
echo "   gettime --help"
echo "   ntpcheck time.google.com"
echo
echo "3. Start using the tools:"
echo "   gettime pool.ntp.org"
echo "   ntpdetail -s time.google.com"
echo "   monitor --status"
echo

exit 0
