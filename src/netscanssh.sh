#!/bin/bash

# Function to install dependencies using Homebrew
install_dependencies() {
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install nmap
    if ! brew list --formula | grep -q "nmap"; then
        echo "Installing nmap..."
        brew install nmap
    fi

    # Install netcat
    if ! brew list --formula | grep -q "netcat"; then
        echo "Installing netcat..."
        brew install netcat
    fi
}

# Function to check if SSH port is open on a given IP
check_ssh() {
    nc -z -w1 "$1" 22 2>/dev/null && echo "SSH port open on $1" || echo "No SSH port open on $1"
}

# Function to get the hostname associated with an IP
get_hostname() {
    hostname=$(dig +short -x "$1" | sed 's/\.$//')
    echo "Hostname for $1: ${hostname:-Unknown}"
}

# Function to scan the local network
scan_network() {
    echo "Scanning the local network..."
    local_network=$(ip route | grep -oP '192\.168\.\d+\.0/\d+')
    nmap -p 22 --open -oG - "$local_network" | grep -oP '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b' | while read -r ip; do
        echo "Checking device: $ip"
        check_ssh "$ip"
        get_hostname "$ip"
        echo ""
    done
}

# Main function
main() {
    install_dependencies  # Install dependencies using Homebrew
    scan_network  # Scan the local network for devices with open SSH port
}

# Execute main function
main
