# Xiond Installation Reference

This document provides detailed installation instructions for `xiond` across different operating systems.

## Prerequisites

- Administrative privileges (sudo access) for Linux installations
- Homebrew installed for macOS
- Network connectivity to package repositories

## Installation Methods

### macOS

1. **Tap the burnt-labs/xion repository:**
   ```bash
   brew tap burnt-labs/xion
   ```

2. **Install xiond:**
   ```bash
   brew install xiond
   ```

3. **Verify Installation:**
   ```bash
   xiond version
   ```

### Debian-based Linux (Ubuntu, Debian)

1. **Download the repository key:**
   ```bash
   wget -qO - https://packages.burnt.com/apt/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/burnt-keyring.gpg
   ```

2. **Add the burnt repository to your apt sources list:**
   ```bash
   echo "deb [signed-by=/usr/share/keyrings/burnt-keyring.gpg] http://packages.burnt.com/apt /" | sudo tee /etc/apt/sources.list.d/burnt.list
   ```

3. **Update sources and install xiond:**
   ```bash
   sudo apt update
   sudo apt install xiond
   ```

4. **Verify Installation:**
   ```bash
   xiond version
   ```

### Red Hat-based Linux (CentOS, Fedora, RHEL)

1. **Import the burnt repository key:**
   ```bash
   sudo rpm --import https://packages.burnt.com/yum/gpg.key
   ```

2. **Add the burnt repository to your repos list:**
   ```bash
   printf "[burnt]\nname=Burnt Repo\nenabled=1\nbaseurl=https://packages.burnt.com/yum/\n" | sudo tee /etc/yum.repos.d/burnt.repo
   ```

3. **Install xiond:**
   ```bash
   sudo dnf install xiond
   ```
   or for older systems:
   ```bash
   sudo yum install xiond
   ```

4. **Verify Installation:**
   ```bash
   xiond version
   ```

### Alpine Linux

1. **Download the repository key:**
   ```bash
   wget -qO - https://alpine.fury.io/burnt/burnt@fury.io-b8abd990.rsa.pub | sudo tee /etc/apk/keys/burnt@fury.io-b8abd990.rsa.pub
   ```

2. **Add the burnt repository to your repository list:**
   ```bash
   echo "https://alpine.fury.io/burnt" | sudo tee -a /etc/apk/repositories
   ```

3. **Update sources and install xiond:**
   ```bash
   sudo apk update
   sudo apk add xiond
   ```

4. **Verify Installation:**
   ```bash
   xiond version
   ```

## Troubleshooting

### macOS Issues

- **Homebrew not found**: Install Homebrew from https://brew.sh
- **Tap fails**: Check network connectivity and try manually: `brew tap burnt-labs/xion`
- **Permission errors**: Ensure you have write access to Homebrew directories

### Linux Issues

- **GPG key import fails**: Check network connectivity and verify the key URL
- **Repository not found**: Verify the repository URL is correct for your OS
- **Permission denied**: Ensure you have sudo privileges
- **Package not found**: Run update command first (`apt update`, `dnf check-update`, or `apk update`)

### Verification Issues

- **Command not found**: Ensure installation completed successfully and PATH includes binary location
- **Version check fails**: Try running `xiond --version` or `xiond version` with verbose output

## Post-Installation

After successful installation, you can:

1. Verify the installation: `xiond version`
2. View available commands: `xiond --help`
3. Initialize a new node: `xiond init <moniker>`
4. Generate keys: `xiond keys add <keyname>`

For more information, refer to the [Xion documentation](https://docs.burnt.com/xion).
