
#!/usr/bin/env bash

set -uo pipefail

# Cross-distribution Linux App Manager
# Supports Ubuntu, Debian, Kali, Parrot, Fedora,
# Rocky Linux, AlmaLinux, and compatible distributions.

if [[ $EUID -ne 0 ]]; then
    echo "[-] Run with sudo: sudo bash $0"
    exit 1
fi

# Load distribution information
if [[ -r /etc/os-release ]]; then
    . /etc/os-release
else
    echo "[-] Cannot detect Linux distribution."
    exit 1
fi

DISTRO="${ID:-unknown}"
DISTRO_FAMILY="${ID_LIKE:-}"

# Determine package manager
if command -v apt-get >/dev/null 2>&1; then
    PKG_MANAGER="apt"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
else
    echo "[-] APT or DNF is required."
    exit 1
fi

# One editable catalog:
# Name|Category|APT package|DNF package|Flatpak ID

APP_CATALOG=(
    # --- Office & PDF ---
    # Linux alternatives to Microsoft 365 and Adobe Acrobat Reader
    "LibreOffice|standard|libreoffice|libreoffice|org.libreoffice.LibreOffice"
    "PDF Reader (Okular)|standard|okular|okular|org.kde.okular"

    # --- Development, Containers & System Administration ---
    "Python 3|standard|python3|python3|"
    "Python pip|standard|python3-pip|python3-pip|"
    "Python venv|standard|python3-venv|python3|"
    "Git|standard|git|git|"
    "Visual Studio Code|standard|||com.visualstudio.code"
    "Docker Engine|standard|docker.io|moby-engine|"
    "Docker Compose|standard|docker-compose-v2|docker-compose|"
    "Android Studio|standard|||com.google.AndroidStudio"
    "7-Zip|standard|7zip|p7zip|"
    "Tailscale VPN|standard|tailscale|tailscale|"
    "OpenVPN|standard|openvpn|openvpn|"
    "Minicom|standard|minicom|minicom|"
    "GNS3|standard|gns3-gui|gns3-gui|"
    "Sysinternals Alternatives (htop)|standard|htop|htop|"
    "Remote Desktop (Remmina)|standard|remmina|remmina|org.remmina.Remmina"

    # --- Browsers & Password Management ---
    "Bitwarden|standard|||com.bitwarden.desktop"
    "Google Chrome|standard|||com.google.Chrome"
    "Mozilla Firefox|standard|firefox|firefox|org.mozilla.firefox"
    "Chromium|standard|chromium|chromium|org.chromium.Chromium"

    # --- Communication & Collaboration ---
    "Discord|standard|||com.discordapp.Discord"
    "Zoom|standard|||us.zoom.Zoom"
    "Microsoft Teams Alternative (Web)|standard|||"
    "Proton VPN|standard|||com.protonvpn.www"

    # --- Security & Network Tools ---
    "Nmap|security|nmap|nmap|"
    "OWASP ZAP|security|||org.zaproxy.ZAP"
    "Wireshark|security|wireshark|wireshark|"
    "Hashcat|security|hashcat|hashcat|"
    "Postman|security|||com.getpostman.Postman"
    "Ghidra|security|ghidra|ghidra|"
    "Radare2|security|radare2|radare2|"
    "ClamAV|security|clamav|clamav|"
    "Burp Suite Community|security|||"
    "IDA Free|security|||"
    "x64dbg Alternative (GDB)|security|gdb|gdb|"
    "CyberChef Alternative (Web)|security|||"

    # --- Media, Gaming & Content Creation ---
    "VLC Media Player|standard|vlc|vlc|org.videolan.VLC"
    "Audacity|standard|audacity|audacity|org.audacityteam.Audacity"
    "OBS Studio|standard|obs-studio|obs-studio|com.obsproject.Studio"
    "Kdenlive|standard|||org.kde.kdenlive"
    "KiCad|standard|kicad|kicad|org.kicad.KiCad"
    "FreeCAD|standard|freecad|freecad|org.freecad.FreeCAD"
    "Blender|standard|blender|blender|org.blender.Blender"
    "GIMP|standard|gimp|gimp|org.gimp.GIMP"
    "Steam|standard|||com.valvesoftware.Steam"
    "Lutris|standard|||net.lutris.Lutris"
    "Heroic Games Launcher|standard|||com.heroicgameslauncher.hgl"
)

OK_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

log()  { echo "[*] $*"; }
good() { echo "[+] $*"; }
warn() { echo "[!] $*"; }

# Initialize the package environment
initialize_managers() {
    log "Distribution: $PRETTY_NAME"
    log "Package manager: $PKG_MANAGER"

    if [[ "$PKG_MANAGER" == "apt" ]]; then
        apt-get update
    else
        dnf makecache
    fi

    if ! command -v flatpak >/dev/null 2>&1; then
        log "Installing Flatpak..."
        if [[ "$PKG_MANAGER" == "apt" ]]; then
            apt-get install -y flatpak || return 1
        else
            dnf install -y flatpak || return 1
        fi
    fi

    flatpak remote-add --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo || return 1

    good "Package environment initialized."
}

# Read a catalog row and install the application
install_app() {
    local name="$1"
    local category="$2"
    local apt_pkg="$3"
    local dnf_pkg="$4"
    local flatpak_id="$5"

    echo
    log "Installing $name..."

    if [[ -n "$flatpak_id" ]]; then
        if flatpak install --system -y flathub "$flatpak_id"; then
            good "$name installed."
            ((OK_COUNT+=1))
        else
            warn "Could not install $name."
            ((FAIL_COUNT+=1))
        fi
        return
    fi

    local package=""
    if [[ "$PKG_MANAGER" == "apt" ]]; then
        package="$apt_pkg"
    else
        package="$dnf_pkg"
    fi

    if [[ -z "$package" ]]; then
        warn "No native package mapping for $name."
        ((SKIP_COUNT+=1))
        return
    fi

    local rc=0
    if [[ "$PKG_MANAGER" == "apt" ]]; then
        apt-get install -y "$package" || rc=$?
    else
        dnf install -y "$package" || rc=$?
    fi

    if (( rc == 0 )); then
        good "$name installed."
        ((OK_COUNT+=1))
    else
        warn "$name unavailable or installation failed."
        ((FAIL_COUNT+=1))
    fi
}

# Install every application in a category
install_category() {
    local selected_category="$1"
    local entry name category apt_pkg dnf_pkg flatpak_id

    for entry in "${APP_CATALOG[@]}"; do
        IFS='|' read -r name category apt_pkg dnf_pkg flatpak_id \
            <<< "$entry"

        if [[ "$selected_category" == "all" ||
              "$category" == "$selected_category" ]]; then
            install_app "$name" "$category" \
                "$apt_pkg" "$dnf_pkg" "$flatpak_id"
        fi
    done
}

# Show the complete editable application catalog
list_apps() {
    local i entry name category apt_pkg dnf_pkg flatpak_id

    echo
    echo "Available applications:"
    echo "---------------------------------------------"

    for i in "${!APP_CATALOG[@]}"; do
        IFS='|' read -r name category apt_pkg dnf_pkg flatpak_id \
            <<< "${APP_CATALOG[$i]}"
        printf "%2d) %-22s [%s]\n" "$((i+1))" "$name" "$category"
    done

    echo "---------------------------------------------"
}

# Install applications selected by their menu numbers
install_selected() {
    local selection item index entry
    local name category apt_pkg dnf_pkg flatpak_id

    list_apps
    read -r -p "Enter app numbers (e.g. 1,3,8): " selection

    IFS=',' read -ra choices <<< "$selection"

    for item in "${choices[@]}"; do
        item="${item//[[:space:]]/}"

        if [[ ! "$item" =~ ^[0-9]+$ ]] ||
           (( item < 1 || item > ${#APP_CATALOG[@]} )); then
            warn "Invalid selection: $item"
            ((SKIP_COUNT+=1))
            continue
        fi

        index=$((item-1))
        entry="${APP_CATALOG[$index]}"

        IFS='|' read -r name category apt_pkg dnf_pkg flatpak_id \
            <<< "$entry"

        install_app "$name" "$category" \
            "$apt_pkg" "$dnf_pkg" "$flatpak_id"
    done
}

# Upgrade native packages and Flatpak apps
update_everything() {
    local rc=0

    echo
    log "Updating system packages..."

    if [[ "$PKG_MANAGER" == "apt" ]]; then
        apt-get update && apt-get upgrade -y || rc=$?
    else
        dnf upgrade --refresh -y || rc=$?
    fi

    if (( rc != 0 )); then
        warn "Native package update encountered an error."
    else
        good "Native package update finished."
    fi

    if command -v flatpak >/dev/null 2>&1; then
        echo
        log "Updating Flatpak applications..."
        if flatpak update --system -y; then
            good "Flatpak update finished."
        else
            warn "Flatpak update encountered an error."
            rc=1
        fi
    fi

    return "$rc"
}

# Start Docker only if its service exists
start_docker_if_available() {
    if command -v systemctl >/dev/null 2>&1 &&
       systemctl cat docker.service >/dev/null 2>&1; then
        systemctl enable --now docker.service ||
            warn "Docker is installed but could not be started."
    fi
}

# Main menu
initialize_managers || {
    echo "[-] Package environment setup failed."
    exit 1
}

while true; do
    echo
    echo "============================================="
    echo "        CROSS-DISTRO LINUX APP MANAGER"
    echo "============================================="
    echo "OS: $PRETTY_NAME"
    echo "Package manager: $PKG_MANAGER"
    echo
    echo "1) Install standard suite"
    echo "2) Install security suite"
    echo "3) Install all applications"
    echo "4) Install selected applications"
    echo "5) Update system and Flatpak applications"
    echo "6) List application catalog"
    echo "7) Exit"
    echo "============================================="

    read -r -p "Select option [1-7]: " choice

    case "$choice" in
        1)
            install_category essential
            install_category development
            install_category containers
            install_category communication
            install_category vpn
            install_category media
            install_category gaming
            start_docker_if_available
            ;;
        2)
            install_category security
            ;;
        3)
            install_category all
            start_docker_if_available
            ;;
        4)
            install_selected
            start_docker_if_available
            ;;
        5)
            update_everything
            ;;
        6)
            list_apps
            ;;
        7)
            echo "Exiting."
            break
            ;;
        *)
            warn "Invalid menu option."
            ;;
    esac

    echo
    echo "Session totals: $OK_COUNT installed,"
    echo "$FAIL_COUNT failed, $SKIP_COUNT skipped."
done
