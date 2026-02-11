#!/bin/bash
set -e

# Detect OS and install xiond
# Outputs JSON to stdout, status messages to stderr

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [[ -f /etc/debian_version ]]; then
        echo "Debian"
    elif [[ -f /etc/redhat-release ]] || [[ -f /etc/fedora-release ]]; then
        echo "RedHat"
    elif [[ -f /etc/alpine-release ]]; then
        echo "Alpine"
    else
        echo "Unknown"
    fi
}

check_installed() {
    if command -v xiond &> /dev/null; then
        xiond version 2>&1 || echo ""
    else
        echo ""
    fi
}

install_macos() {
    echo "Detected macOS, installing via Homebrew..." >&2
    
    # Tap the repository
    if ! brew tap burnt-labs/xion 2>&1; then
        echo "Failed to tap burnt-labs/xion repository" >&2
        return 1
    fi
    
    # Install xiond
    if ! brew install xiond 2>&1; then
        echo "Failed to install xiond" >&2
        return 1
    fi
}

install_debian() {
    echo "Detected Debian-based Linux, installing via apt..." >&2
    
    # Download and import GPG key
    if ! wget -qO - https://packages.burnt.com/apt/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/burnt-keyring.gpg 2>&1; then
        echo "Failed to import GPG key" >&2
        return 1
    fi
    
    # Add repository
    if ! echo "deb [signed-by=/usr/share/keyrings/burnt-keyring.gpg] http://packages.burnt.com/apt /" | sudo tee /etc/apt/sources.list.d/burnt.list > /dev/null 2>&1; then
        echo "Failed to add repository" >&2
        return 1
    fi
    
    # Update and install
    if ! sudo apt update > /dev/null 2>&1; then
        echo "Failed to update apt sources" >&2
        return 1
    fi
    
    if ! sudo apt install -y xiond 2>&1; then
        echo "Failed to install xiond" >&2
        return 1
    fi
}

install_redhat() {
    echo "Detected Red Hat-based Linux, installing via dnf/yum..." >&2
    
    # Import GPG key
    if ! sudo rpm --import https://packages.burnt.com/yum/gpg.key 2>&1; then
        echo "Failed to import GPG key" >&2
        return 1
    fi
    
    # Add repository
    if ! printf "[burnt]\nname=Burnt Repo\nenabled=1\nbaseurl=https://packages.burnt.com/yum/\n" | sudo tee /etc/yum.repos.d/burnt.repo > /dev/null 2>&1; then
        echo "Failed to add repository" >&2
        return 1
    fi
    
    # Install (try dnf first, fallback to yum)
    if command -v dnf &> /dev/null; then
        if ! sudo dnf install -y xiond 2>&1; then
            echo "Failed to install xiond" >&2
            return 1
        fi
    elif command -v yum &> /dev/null; then
        if ! sudo yum install -y xiond 2>&1; then
            echo "Failed to install xiond" >&2
            return 1
        fi
    else
        echo "Neither dnf nor yum found" >&2
        return 1
    fi
}

install_alpine() {
    echo "Detected Alpine Linux, installing via apk..." >&2
    
    # Download GPG key
    if ! wget -qO - https://alpine.fury.io/burnt/burnt@fury.io-b8abd990.rsa.pub | sudo tee /etc/apk/keys/burnt@fury.io-b8abd990.rsa.pub > /dev/null 2>&1; then
        echo "Failed to download GPG key" >&2
        return 1
    fi
    
    # Add repository
    if ! echo "https://alpine.fury.io/burnt" | sudo tee -a /etc/apk/repositories > /dev/null 2>&1; then
        echo "Failed to add repository" >&2
        return 1
    fi
    
    # Update and install
    if ! sudo apk update > /dev/null 2>&1; then
        echo "Failed to update apk sources" >&2
        return 1
    fi
    
    if ! sudo apk add xiond 2>&1; then
        echo "Failed to install xiond" >&2
        return 1
    fi
}

# Main execution
OS=$(detect_os)
VERSION=$(check_installed)

if [[ -n "$VERSION" ]]; then
    echo "{\"success\": true, \"os\": \"$OS\", \"installed\": true, \"version\": \"$VERSION\", \"message\": \"xiond is already installed\"}"
    exit 0
fi

INSTALL_SUCCESS=false
INSTALL_ERROR=""

case "$OS" in
    "macOS")
        if install_macos; then
            INSTALL_SUCCESS=true
        else
            INSTALL_ERROR="macOS installation failed"
        fi
        ;;
    "Debian")
        if install_debian; then
            INSTALL_SUCCESS=true
        else
            INSTALL_ERROR="Debian installation failed"
        fi
        ;;
    "RedHat")
        if install_redhat; then
            INSTALL_SUCCESS=true
        else
            INSTALL_ERROR="Red Hat installation failed"
        fi
        ;;
    "Alpine")
        if install_alpine; then
            INSTALL_SUCCESS=true
        else
            INSTALL_ERROR="Alpine installation failed"
        fi
        ;;
    *)
        INSTALL_ERROR="Unsupported operating system: $OS"
        ;;
esac

if [[ "$INSTALL_SUCCESS" == "true" ]]; then
    NEW_VERSION=$(check_installed)
    if [[ -n "$NEW_VERSION" ]]; then
        echo "{\"success\": true, \"os\": \"$OS\", \"installed\": false, \"version\": \"$NEW_VERSION\", \"message\": \"xiond installed successfully\"}"
    else
        echo "{\"success\": false, \"os\": \"$OS\", \"installed\": false, \"version\": \"\", \"message\": \"Installation completed but xiond version check failed\"}"
        exit 1
    fi
else
    echo "{\"success\": false, \"os\": \"$OS\", \"installed\": false, \"version\": \"\", \"message\": \"$INSTALL_ERROR\"}"
    exit 1
fi
