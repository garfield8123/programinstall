#!/bin/bash

# Ensure script is run as root/sudo
if [ "$EUID" -ne 0 ]; then
  echo "[-] Please run this script with sudo or as root."
  exit 1
fi

# Detect Linux Distribution Family
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        DISTRO="unknown"
    fi
    echo "[*] Detected Linux distribution: $DISTRO"
}

# Setup package managers / Flatpak universally
initialize_managers() {
    echo "[*] Setting up package environment..."
    case "$DISTRO" in
        ubuntu|debian|pop|linuxmint|kali)
            PKG_MANAGER="apt"
            apt update -y
            ;;
        fedora|rhel|centos|rocky|almalinux)
            PKG_MANAGER="dnf"
            dnf check-update || true
            ;;
        *)
            if command -v apt &> /dev/null; then
                PKG_MANAGER="apt"
            elif command -v dnf &> /dev/null; then
                PKG_MANAGER="dnf"
            else
                echo "[-] Unsupported package manager. Exiting."
                exit 1
            fi
            ;;
    esac

    # Ensure Flatpak is available
    if ! command -v flatpak &> /dev/null; then
        echo "[*] Installing Flatpak..."
        if [ "$PKG_MANAGER" == "apt" ]; then
            apt install flatpak -y
        elif [ "$PKG_MANAGER" == "dnf" ]; then
            dnf install flatpak -y
        fi
    fi
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

# --- Installation Functions ---

install_standard_suite() {
    echo "[+] Installing Standard Suite (Utils, Dev, Media, VPN)..."
    
    if [ "$PKG_MANAGER" == "apt" ]; then
        # Native deb downloads
        curl -L "https://bitwarden.com/download/?app=desktop&platform=linux&variant=deb" --output /tmp/bitwarden.deb
        apt install -y /tmp/bitwarden.deb && rm /tmp/bitwarden.deb

        curl -L "https://discord.com/api/download?platform=linux&format=deb" --output /tmp/discord.deb
        apt install -y /tmp/discord.deb && rm /tmp/discord.deb

        # Core utils & Dev tools
        apt install -y curl wget git git-lfs python3 python3-pip python3-venv 7zip docker.io docker-compose-v2
        
    elif [ "$PKG_MANAGER" == "dnf" ]; then
        flatpak install -y flathub com.bitwarden.desktop
        flatpak install -y flathub com.discordapp.Discord
        dnf install -y curl wget git git-lfs python3 python3-pip p7zip p7zip-plugins docker docker-compose
    fi

    systemctl enable --now docker

    # Flatpak Applications (Media, Browsers, VPN, Dev)
    echo "[+] Installing Flatpak applications..."
    flatpak install -y flathub com.visualstudio.code
    flatpak install -y flathub com.protonvpn.www
    flatpak install -y flathub org.openvpn.OpenVPN
    flatpak install -y flathub org.kde.kdenlive
    flatpak install -y flathub org.freecad.FreeCAD
    flatpak install -y flathub org.kicad.KiCad
    flatpak install -y flathub org.blender.Blender
    flatpak install -y flathub org.gimp.GIMP
    flatpak install -y flathub com.obsproject.Studio
    flatpak install -y flathub com.valvesoftware.Steam
}

install_security_tools() {
    echo "[+] Installing Security and Reversing Suite..."
    if [ "$PKG_MANAGER" == "apt" ]; then
        apt install -y ghidra radare2 nmap wireshark exploitdb clamav
    elif [ "$PKG_MANAGER" == "dnf" ]; then
        dnf install -y ghidra radare2 nmap wireshark exploitdb clamav
    fi
}

# --- Main Execution Flow ---
detect_distro
initialize_managers

echo "--------------------------------------------------"
echo "Select Installation Option:"
echo "1) Install Standard Suite (Browsers, Dev, Media, VPN, Docker)"
echo "2) Install Security & Reversing Suite (Ghidra, Radare2, Nmap)"
echo "3) Install EVERYTHING (Standard + Security)"
echo "--------------------------------------------------"
read -p "Enter choice [1-3]: " choice

case $choice in
    1)
        install_standard_suite
        ;;
    2)
        install_security_tools
        ;;
    3)
        install_standard_suite
        install_security_tools
        ;;
    *)
        echo "Invalid selection. Exiting."
        exit 1
        ;;
esac

echo "[+] All selected installations completed successfully!"
