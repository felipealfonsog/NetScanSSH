#!/bin/bash

# Function to display a welcome message
welcome_message() {
    echo "Welcome to NetCtrl!"
    echo "NetCtrl is a script to remotely manage multiple machines on your local network."
    echo "By computer science engineer Felipe Alfonso González - GitHub.com/felipealfonsog"
    echo "Let's get started."
    echo
}

# Function to list all IP addresses on the local network for Linux or macOS machines with SSH port open
list_local_ips() {
    echo "Listing all IP addresses on the local network with SSH port open for Linux or macOS machines:"
    local count=1
    local_ips=$(nmap -p 22 -oG - 192.168.1.0/24 | grep '22/open' | awk '{print $2}')
    for ip in $local_ips; do
        hostname=$(get_hostname "$ip")
        os=$(check_os "$ip")
        echo "$count - $ip - $hostname - SSH ($(check_ssh_port "$ip"))"
        ((count++))
    done
}

# Function to check if SSH port is open for an IP
check_ssh_port() {
    local ip="$1"

    # Use nmap to scan for open SSH port
    local status=$(nmap -p 22 "$ip" | grep "^22/tcp")

    if [[ -n "$status" ]]; then
        echo "open"
    else
        echo "closed"
    fi
}

# Function to get the hostname for an IP
get_hostname() {
    local ip="$1"
    local hostname=$(host "$ip" | awk '{print $5}')
    if [ -n "$hostname" ]; then
        echo "$hostname"
    else
        echo "Unknown"
    fi
}

# Function to determine if a machine is Linux or macOS
check_os() {
    local ip="$1"
    local os=$(ssh -o ConnectTimeout=2 -o BatchMode=yes "$ip" 'uname -s' 2>/dev/null || echo "Unknown")
    if [ "$os" == "Darwin" ]; then
        echo "macOS"
    elif [ "$os" == "Linux" ]; then
        echo "Linux"
    else
        echo "Unknown"
    fi
}

# Function to perform actions on a selected machine
perform_action() {
    local ip="$1"
    local action="$2"
    local password

    case $action in
        1)
            echo "Enter your sudo password: "
            read -s password
            if [ "$(check_os "$ip")" == "macOS" ]; then
                sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username@$ip" "echo '$password' | sudo -S shutdown -h now"
            else
                sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username@$ip" "echo '$password' | sudo -S systemctl poweroff"
            fi
            ;;
        2)
            echo "Enter your sudo password: "
            read -s password
            if [ "$(check_os "$ip")" == "macOS" ]; then
                sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username@$ip" "echo '$password' | sudo -S pmset sleepnow"
            else
                sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username@$ip" "echo '$password' | sudo -S systemctl suspend"
            fi
            ;;
        3)
            echo "Enter your sudo password: "
            read -s password
            if [ "$(check_os "$ip")" == "macOS" ]; then
                sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username@$ip" "echo '$password' | sudo -S shutdown -r now"
            else
                sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username@$ip" "echo '$password' | sudo -S reboot"
            fi
            ;;
        4)
            echo "Exiting host $ip..."
            return 0
            ;;
        *)
            echo "Invalid action."
            ;;
    esac
}

# Function to install Homebrew and dependencies
install_dependencies() {
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    if ! command -v sshpass &> /dev/null; then
        echo "Installing sshpass..."
        if command -v brew &> /dev/null; then
            brew install hudochenkov/sshpass/sshpass
        else
            echo "sshpass not found. Please install it manually."
        fi
    fi
    if ! command -v nmap &> /dev/null; then
        echo "Installing nmap..."
        if command -v brew &> /dev/null; then
            brew install nmap
        else
            sudo pacman -Sy nmap
        fi
    fi
    if [[ $(uname -s) == "Linux" ]]; then
        if grep -qi arch /etc/os-release; then
            if ! command -v host &> /dev/null; then
                echo "Installing bind-tools (includes 'host' command)..."
                sudo pacman -Sy bind-tools
            fi
        elif grep -qi debian /etc/os-release; then
            if ! command -v host &> /dev/null; then
                echo "Installing bind9-host..."
                sudo apt-get update
                sudo apt-get install -y bind9-host
            fi
        fi
    fi
}

# Main function
main() {
    welcome_message
    install_dependencies

    while true; do
        list_local_ips

        read -p "Enter the number of the IP address you want to connect to (or q to quit): " selection
        if [ "$selection" == "q" ]; then
            echo "Exiting program."
            exit 0
        elif (( selection >= 1 && selection <= $(echo "$local_ips" | wc -w) )); then
            selected_ip=$(echo "$local_ips" | awk "{ if (NR == $selection) print \$1 }")
            echo "Enter your SSH username: "
            read username

            while true; do
                echo "Enter your sudo password (or type 'q' to return to host selection): "
                read -s password
                if [ "$password" == "q" ]; then
                    break
                fi

                echo "Select an action:"
                echo "1. Power off"
                echo "2. Suspend"
                echo "3. Reboot"
                echo "4. Abort"
                read -p "Enter the number of the action: " action

                perform_action "$selected_ip" "$action"
            done
        else
            echo "Invalid selection."
            exit 1
        fi
    done
}

# Run the main function
main
