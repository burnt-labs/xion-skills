#!/bin/bash
set -euo pipefail

# Upgrade xiond to the latest version
# Usage: upgrade.sh
# Outputs JSON to stdout, status messages to stderr

emit_json() {
    python3 - <<'PY'
import json, os
payload = json.loads(os.environ["PAYLOAD_JSON"])
print(json.dumps(payload, ensure_ascii=False))
PY
}

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

# Check if xiond is installed
if ! command -v xiond &> /dev/null; then
    PAYLOAD_JSON='{"success":false,"error":"xiond is not installed. Use install.sh first."}' emit_json
    exit 1
fi

OS=$(detect_os)
OLD_VERSION=$(xiond version 2>&1 || echo "")

echo "Upgrading xiond on $OS (current version: $OLD_VERSION)..." >&2

UPGRADE_SUCCESS=false
UPGRADE_ERROR=""

case "$OS" in
    "macOS")
        echo "Upgrading via Homebrew..." >&2
        if brew upgrade xiond 2>&1; then
            UPGRADE_SUCCESS=true
        else
            UPGRADE_ERROR="Homebrew upgrade failed"
        fi
        ;;
    "Debian")
        echo "Upgrading via apt..." >&2
        if sudo apt update > /dev/null 2>&1 && sudo apt install -y --only-upgrade xiond 2>&1; then
            UPGRADE_SUCCESS=true
        else
            UPGRADE_ERROR="apt upgrade failed"
        fi
        ;;
    "RedHat")
        echo "Upgrading via dnf/yum..." >&2
        if command -v dnf &> /dev/null; then
            if sudo dnf upgrade -y xiond 2>&1; then
                UPGRADE_SUCCESS=true
            else
                UPGRADE_ERROR="dnf upgrade failed"
            fi
        elif command -v yum &> /dev/null; then
            if sudo yum update -y xiond 2>&1; then
                UPGRADE_SUCCESS=true
            else
                UPGRADE_ERROR="yum upgrade failed"
            fi
        else
            UPGRADE_ERROR="Neither dnf nor yum found"
        fi
        ;;
    "Alpine")
        echo "Upgrading via apk..." >&2
        if sudo apk update > /dev/null 2>&1 && sudo apk upgrade xiond 2>&1; then
            UPGRADE_SUCCESS=true
        else
            UPGRADE_ERROR="apk upgrade failed"
        fi
        ;;
    *)
        UPGRADE_ERROR="Unsupported operating system: $OS"
        ;;
esac

if [[ "$UPGRADE_SUCCESS" == "true" ]]; then
    NEW_VERSION=$(xiond version 2>&1 || echo "")
    PAYLOAD_JSON="$(OS="$OS" OLD_VERSION="$OLD_VERSION" NEW_VERSION="$NEW_VERSION" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": True,
    "os": os.environ["OS"],
    "old_version": os.environ.get("OLD_VERSION", ""),
    "new_version": os.environ.get("NEW_VERSION", ""),
    "message": "xiond upgraded successfully"
}))
PY
)" emit_json
else
    PAYLOAD_JSON="$(OS="$OS" ERR="$UPGRADE_ERROR" python3 - <<'PY'
import json, os
print(json.dumps({
    "success": False,
    "os": os.environ["OS"],
    "error": os.environ.get("ERR", ""),
    "message": "Upgrade failed"
}))
PY
)" emit_json
    exit 1
fi
