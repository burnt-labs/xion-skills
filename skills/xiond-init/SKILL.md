---
name: xiond-init
description: Install xiond CLI tool when not present in the environment. Use when user needs to install xiond, setup xion daemon, or verify xiond installation.
---

# Xiond Installation

Installs the `xiond` command-line interface (CLI) daemon for interacting with the Xion blockchain. Supports multiple operating systems including macOS, Debian-based Linux, Red Hat-based Linux, and Alpine Linux.

## How It Works

1. Detects the operating system type
2. Checks if xiond is already installed
3. Executes the appropriate package manager installation command for the detected OS
4. Verifies installation by running `xiond version`
5. Returns installation status and version information

## Usage

```bash
bash /mnt/skills/user/xiond-init/scripts/install.sh
```

**Arguments:**

- No arguments required - the script auto-detects the OS

**Examples:**

```bash
# Install xiond on macOS
bash /mnt/skills/user/xiond-init/scripts/install.sh

# Install xiond on Debian/Ubuntu
bash /mnt/skills/user/xiond-init/scripts/install.sh

# Install xiond on Red Hat/CentOS/Fedora
bash /mnt/skills/user/xiond-init/scripts/install.sh
```

## Output

The script outputs JSON to stdout with the following structure:

```json
{
  "success": true,
  "os": "macOS",
  "installed": true,
  "version": "xiond version 1.0.0",
  "message": "xiond is already installed"
}
```

or

```json
{
  "success": true,
  "os": "macOS",
  "installed": false,
  "version": "xiond version 1.0.0",
  "message": "xiond installed successfully"
}
```

## Present Results to User

When presenting results to the user:

- **If already installed**: "xiond is already installed (version: X.X.X)"
- **If installation succeeds**: "xiond has been successfully installed (version: X.X.X)"
- **If installation fails**: "Installation failed: [error message]. Please check the installation reference for manual steps."

## Troubleshooting

**macOS:**
- Ensure Homebrew is installed: `brew --version`
- If tap fails, try: `brew tap burnt-labs/xion` manually

**Debian-based Linux:**
- Requires sudo privileges for apt operations
- If GPG key import fails, check network connectivity
- Verify repository URL: `http://packages.burnt.com/apt`

**Red Hat-based Linux:**
- Requires sudo privileges for dnf/yum operations
- Ensure dnf or yum is available
- Check repository URL: `https://packages.burnt.com/yum/`

**Alpine Linux:**
- Requires sudo privileges for apk operations
- Verify repository URL: `https://alpine.fury.io/burnt`

**General:**
- If installation fails, refer to `references/installation.md` for manual installation steps
- Verify network connectivity to package repositories
- Check system logs for detailed error messages
