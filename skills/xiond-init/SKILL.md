---
name: xiond-init
version: 1.0.0
description: |
  Install, upgrade, and verify the `xiond` CLI for Xion blockchain.
  
  Use when user specifically mentions xiond, contract development environment,
  validator setup, or needs the traditional Cosmos SDK CLI.
  
  For most Xion developers, xion-toolkit (MetaAccount) is recommended instead.
  
  Triggers: xiond, xiond install, contract development, validator, cosmos CLI,
  traditional wallet, mnemonic-based, xiond setup, xiond version, xiond upgrade.
---

# Xiond Installation & Management

Installs, upgrades, and manages the `xiond` command-line interface for interacting with the Xion blockchain. Cross-platform support for major operating systems.

## When to Use xiond vs xion-toolkit

| Scenario | Recommended Tool |
|----------|------------------|
| Regular development | xion-toolkit (MetaAccount) |
| Gasless transactions | xion-toolkit |
| Contract deployment | xiond (this skill) |
| Chain queries | xiond (this skill) |
| Validator operations | xiond (this skill) |
| Mnemonic-based wallets | xiond (this skill) |

**Note**: For most Xion developers building applications with MetaAccount, OAuth2 authentication, or gasless transactions, use [xion-toolkit](https://github.com/burnt-labs/xion-agent-toolkit) instead.

## When to Use This Skill

- User needs to install xiond for the first time
- User wants to check if xiond is installed and its version
- User wants to upgrade to the latest xiond version
- User encounters "xiond: command not found" error
- User is setting up their Xion development environment

## How It Works

1. **Detect OS**: Automatically identifies macOS, Debian, Red Hat, or Alpine Linux
2. **Check Status**: Verifies if xiond is already installed and its version
3. **Install/Upgrade**: Uses appropriate package manager for the detected OS
4. **Verify**: Confirms successful installation by checking version

## Compatibility

- Requires `bash` and `python3`
- May require `sudo` (Linux installs)
- Requires network access to Burnt package repositories
- See `references/installation.md` for detailed OS-specific instructions

## Usage

### Install xiond

```bash
bash /mnt/skills/user/xiond-init/scripts/install.sh
```

Installs xiond using the appropriate package manager for your OS.

### Check Version

```bash
bash /mnt/skills/user/xiond-init/scripts/check-version.sh
```

Checks if xiond is installed and returns version information.

### Upgrade xiond

```bash
bash /mnt/skills/user/xiond-init/scripts/upgrade.sh
```

Upgrades xiond to the latest version using your system's package manager.

## Output

All scripts output JSON to stdout:

**Check Version (installed):**
```json
{
  "success": true,
  "installed": true,
  "version": "xiond version 1.0.0",
  "path": "/usr/local/bin/xiond",
  "message": "xiond is installed"
}
```

**Check Version (not installed):**
```json
{
  "success": true,
  "installed": false,
  "version": null,
  "path": null,
  "message": "xiond is not installed"
}
```

**Install/Upgrade Success:**
```json
{
  "success": true,
  "os": "macOS",
  "version": "xiond version 1.0.0",
  "message": "xiond installed successfully"
}
```

## Present Results to User

- **Already installed**: "xiond is already installed (version: X.X.X)"
- **Installation succeeds**: "xiond has been successfully installed (version: X.X.X)"
- **Upgrade succeeds**: "xiond upgraded from vOLD to vNEW"
- **Failure**: "Installation failed: [error]. Check references/installation.md for manual steps."

## Troubleshooting

**macOS:**
- Ensure Homebrew is installed: `brew --version`
- If tap fails, try: `brew tap burnt-labs/xion` manually
 - If Homebrew is not installed, follow the installation guide at `https://brew.sh` and then rerun this skill.

**Debian-based Linux:**
- Requires sudo privileges
- If GPG key import fails, check network connectivity
- Repository: `http://packages.burnt.com/apt`

**Red Hat-based Linux:**
- Requires sudo privileges
- Ensure dnf or yum is available
- Repository: `https://packages.burnt.com/yum/`

**Alpine Linux:**
- Requires sudo privileges
- Repository: `https://alpine.fury.io/burnt`

**General:**
- If installation fails, refer to `references/installation.md` for manual steps
- Verify network connectivity to package repositories
- Check system logs for detailed error messages
 - For alternative installation methods (pre-built binaries, Docker images, or building from source), see the official XION docs section on xiond: `https://docs.burnt.com/xion/developers/getting-started-advanced/setup-local-environment/installation-prerequisites-setup-local-environment#xiond`

## References

- `references/installation.md` — Detailed OS-specific installation instructions and troubleshooting
