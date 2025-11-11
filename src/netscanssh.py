import subprocess
import sys
import socket
from scapy.layers.l2 import ARP, Ether
from scapy.sendrecv import srp
import netifaces as ni

def install_dependencies():
    """
    Function to install required dependencies.
    """
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "scapy", "netifaces"])
        print("Dependencies installed successfully.")
    except Exception as e:
        print(f"Error installing dependencies: {e}")

def check_dependencies():
    """
    Function to check if required dependencies are installed.
    """
    try:
        import scapy
        import netifaces
    except ImportError:
        print("scapy or netifaces not found. Installing dependencies...")
        install_dependencies()
        # Exit if installation failed
        try:
            import scapy
            import netifaces
        except ImportError:
            print("Unable to install required dependencies. Exiting.")
            sys.exit(1)

def get_default_gateway():
    """
    Function to get the default gateway IP address.
    """
    try:
        gateway = ni.gateways()['default'][ni.AF_INET][0]
        return gateway
    except KeyError:
        print("Default gateway not found.")
        return None

def scan_network():
    # Scanning the local network to find active devices
    arp_request = ARP(pdst="192.168.1.0/24")
    ether = Ether(dst="ff:ff:ff:ff:ff:ff")
    packet = ether / arp_request
    result = srp(packet, timeout=3, verbose=False)[0]
    devices = []
    gateway = get_default_gateway()
    if gateway:
        for sent, received in result:
            if received.psrc != gateway:
                devices.append({'ip': received.psrc, 'mac': received.hwsrc})
                print(f"Found device: {received.psrc}")
    return devices

def check_ssh(ip):
    # Checking if port 22 (SSH) is open on the given IP address
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)  # 1-second connection timeout
        result = sock.connect_ex((ip, 22))
        sock.close()
        return result == 0
    except socket.error:
        return False

def get_hostname(ip):
    # Getting the hostname associated with the given IP address
    try:
        hostname, _, _ = socket.gethostbyaddr(ip)
        return hostname
    except socket.herror:
        return "Unknown"

def main():
    check_dependencies()  # Check and install dependencies if necessary

    print("Scanning the local network...")
    devices = scan_network()

    print("\nDetecting devices with macOS or Linux and open SSH port...\n")
    found_devices = False
    for device in devices:
        ip = device['ip']
        print(f"Checking device: {ip}")
        if check_ssh(ip):
            hostname = get_hostname(ip)
            print(f"Machine Name: {hostname} | IP Address: {ip}")
            found_devices = True
        else:
            print(f"No SSH port open on device: {ip}")
    if not found_devices:
        print("No devices with macOS or Linux and open SSH port found on the network.")

if __name__ == "__main__":
    main()
