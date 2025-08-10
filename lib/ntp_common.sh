#!/bin/bash

# NTP Common Library Functions
# This library provides common functions for NTP operations using chrony

# Colors for output formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to display error messages
error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

# Function to check if chrony is installed
check_chrony() {
    if ! command -v chronyc >/dev/null 2>&1; then
        echo -e "${RED}Error: chronyc is not installed. Please install chrony package.${NC}" >&2
        echo "  Debian/Ubuntu: sudo apt install chrony" >&2
        echo "  RHEL/CentOS: sudo yum install chrony" >&2
        return 1
    fi
    return 0
}

# Function to validate NTP server hostname/IP
validate_ntp_server() {
    local server="$1"
    
    if [ -z "$server" ]; then
        echo -e "${RED}Error: NTP server not specified${NC}" >&2
        return 1
    fi
    
    # Check if it's a valid hostname or IP
    if ! host "$server" >/dev/null 2>&1 && ! ping -c 1 -W 1 "$server" >/dev/null 2>&1; then
        echo -e "${RED}Error: Cannot resolve NTP server '$server'${NC}" >&2
        return 1
    fi
    
    return 0
}

# Function to check if NTP port is reachable
check_ntp_port() {
    local server="$1"
    local port="${2:-123}"
    
    if command -v nc >/dev/null 2>&1; then
        if ! timeout 5 nc -u -z "$server" "$port" 2>/dev/null; then
            echo -e "${YELLOW}Warning: NTP port $port may not be reachable on $server${NC}" >&2
            return 1
        fi
    fi
    return 0
}

# Function to get time from NTP server using chrony
get_ntp_time() {
    local server="$1"
    
    if ! validate_ntp_server "$server"; then
        return 1
    fi
    
    # Use chronyc to get time from specific server
    local result
    result=$(timeout 10 chronyc -h "$server" tracking 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$result" ]; then
        # Fallback to manual NTP query using date and ntpdate if available
        if command -v ntpdate >/dev/null 2>&1; then
            ntpdate -q "$server" 2>/dev/null | grep "offset" | tail -1
        else
            echo -e "${RED}Error: Unable to query NTP server $server${NC}" >&2
            return 1
        fi
    else
        echo "$result"
    fi
}

# Function to get detailed NTP information
get_ntp_details() {
    local server="$1"
    
    if ! validate_ntp_server "$server"; then
        return 1
    fi
    
    echo -e "${BLUE}=== NTP Server Details for $server ===${NC}"
    echo
    
    # Get chrony sources information
    echo -e "${GREEN}Sources Information:${NC}"
    timeout 10 chronyc sources -v 2>/dev/null | grep -A 5 -B 5 "$server" || {
        echo "Unable to get sources info from chrony"
    }
    
    echo
    echo -e "${GREEN}Tracking Information:${NC}"
    timeout 10 chronyc tracking 2>/dev/null || {
        echo "Unable to get tracking info from chrony"
    }
    
    echo
    echo -e "${GREEN}Server Reachability Test:${NC}"
    check_ntp_port "$server" 123
    
    # Try to get additional info using ntpq if available
    if command -v ntpq >/dev/null 2>&1; then
        echo
        echo -e "${GREEN}Extended Server Information (ntpq):${NC}"
        timeout 10 ntpq -p "$server" 2>/dev/null || {
            echo "ntpq query failed or timed out"
        }
    fi
}

# Function to format time output
format_time_output() {
    local timestamp="$1"
    local format="${2:-%Y-%m-%d %H:%M:%S %Z}"
    
    if [ -n "$timestamp" ]; then
        date -d "@$timestamp" +"$format" 2>/dev/null || echo "$timestamp"
    fi
}

# Function to calculate time difference in milliseconds
calculate_time_diff() {
    local time1="$1"
    local time2="$2"
    
    local diff=$((time2 - time1))
    local abs_diff=${diff#-}
    
    echo "${diff} seconds (${abs_diff}000 ms)"
}

# Function to show usage information
show_usage() {
    local script_name="$1"
    local description="$2"
    
    echo "Usage: $script_name [OPTIONS] <ntp_server>"
    echo
    echo "$description"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Enable verbose output"
    echo "  -t, --timeout  Set timeout in seconds (default: 10)"
    echo
    echo "Examples:"
    echo "  $script_name pool.ntp.org"
    echo "  $script_name time.google.com"
    echo "  $script_name -v 0.pool.ntp.org"
}

# Function to log messages with timestamp
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "ERROR")
            echo -e "${RED}[$timestamp] ERROR: $message${NC}" >&2
            ;;
        "WARN")
            echo -e "${YELLOW}[$timestamp] WARN: $message${NC}" >&2
            ;;
        "INFO")
            echo -e "${GREEN}[$timestamp] INFO: $message${NC}"
            ;;
        "DEBUG")
            echo -e "${BLUE}[$timestamp] DEBUG: $message${NC}"
            ;;
        *)
            echo "[$timestamp] $message"
            ;;
    esac
}
