# Configuration Guide

Complete guide to configuring Qubes SDP for your specific needs.

## Configuration File

The main configuration file is `qubes-config.conf`. This file controls all aspects of your qube topology.

### Configuration Structure

The config file is organized into sections:

1. **Global Settings** - System-wide options
2. **Qube Configurations** - Per-qube settings (work, vault, anon, untrusted)
3. **Advanced Features** - VPN, USB, split-GPG, split-SSH
4. **Policies** - Qrexec and security policies
5. **Backup Settings** - Automated backup configuration
6. **Topology Presets** - Pre-configured layouts

## Global Settings

### Templates

```bash
# Default template for all qubes
DEFAULT_TEMPLATE="fedora-40-minimal"

# Auto-install missing templates
AUTO_INSTALL_TEMPLATES="true"

# Update templates before setup
UPDATE_TEMPLATES="true"

# Required templates (comma-separated)
REQUIRED_TEMPLATES="fedora-40-minimal"
```

**Supported templates**:
* fedora-40-minimal
* fedora-39-minimal
* debian-12-minimal
* debian-11-minimal

### Logging and Debugging

```bash
# Enable verbose output
VERBOSE="true"

# Log file location
LOG_FILE="/var/log/qubes-sdp-setup.log"

# Dry-run mode (test without changes)
DRY_RUN="false"
```

### Backup Settings

```bash
# Enable automatic backups
AUTO_BACKUP="true"

# Backup destination
BACKUP_DEST="dom0:/var/backups/qubes-sdp"

# Backup schedule (cron format)
BACKUP_SCHEDULE="0 2 * * *"  # Daily at 2 AM

# Qubes to backup (comma-separated or "all")
BACKUP_QUBES="vault,work"

# Enable compression
BACKUP_COMPRESSION="true"
```

## Qube Configuration

### Work Qube

General-purpose work environment with restricted network access.

```bash
# Enable/disable
ENABLE_WORK="true"

# Basic settings
WORK_NAME="work"
WORK_LABEL="green"
WORK_MEMORY="2048"  # MB
WORK_NETVM="sys-firewall"
WORK_TEMPLATE="${DEFAULT_TEMPLATE}"

# Firewall policy
WORK_FIREWALL_POLICY="custom"
WORK_ALLOWED_PORTS="tcp:80,tcp:443,udp:53"

# Packages to install
WORK_PACKAGES="vim git curl wget"

# Autostart on boot
WORK_AUTOSTART="false"
```

**Firewall Policies**:
* `allow-all` - No restrictions (not recommended)
* `deny-all` - Block all traffic
* `custom` - Use WORK_ALLOWED_PORTS

**Label Colors**:
red, orange, yellow, green, blue, purple, gray, black

### Vault Qube

Air-gapped storage for sensitive data (NO NETWORK).

```bash
ENABLE_VAULT="true"

VAULT_NAME="vault"
VAULT_LABEL="black"
VAULT_MEMORY="1024"
VAULT_NETVM=""  # MUST be empty for security
VAULT_TEMPLATE="${DEFAULT_TEMPLATE}"
VAULT_PACKAGES="vim keepassxc"
VAULT_AUTOSTART="false"
```

**Security Note**: NEVER set VAULT_NETVM to anything other than empty string. This ensures complete network isolation.

### Anon Qube

Anonymous communications via Tor/Whonix.

```bash
ENABLE_ANON="true"

ANON_NAME="anon"
ANON_LABEL="purple"
ANON_MEMORY="1024"
ANON_NETVM="sys-whonix"
ANON_NETVM_FALLBACK="sys-firewall"
ANON_TEMPLATE="${DEFAULT_TEMPLATE}"
ANON_PACKAGES="vim tor-browser"
ANON_AUTOSTART="false"
```

**Note**: If sys-whonix is not installed, automatically falls back to ANON_NETVM_FALLBACK.

### Untrusted Qube

Disposable environment for risky activities.

```bash
ENABLE_UNTRUSTED="true"

UNTRUSTED_NAME="untrusted"
UNTRUSTED_LABEL="red"
UNTRUSTED_MEMORY="1024"
UNTRUSTED_NETVM="sys-firewall"
UNTRUSTED_TEMPLATE="${DEFAULT_TEMPLATE}"
UNTRUSTED_IS_DISPVM_TEMPLATE="true"
UNTRUSTED_PACKAGES="vim"
UNTRUSTED_AUTOSTART="false"
```

## Advanced Features

### VPN Qube

ProxyVM for VPN connections.

```bash
ENABLE_VPN="false"

VPN_NAME="vpn"
VPN_LABEL="blue"
VPN_MEMORY="512"
VPN_NETVM="sys-firewall"
VPN_TEMPLATE="${DEFAULT_TEMPLATE}"
VPN_PROVIDES_NETWORK="true"
VPN_PACKAGES="openvpn wireguard-tools"

# VPN configuration file (optional)
VPN_CONFIG_FILE=""
```

To use the VPN qube for other qubes:
```bash
qvm-prefs work netvm vpn
```

### USB Qube

Dedicated qube for USB device management.

```bash
ENABLE_USB="false"

USB_NAME="sys-usb"
USB_LABEL="red"
USB_MEMORY="512"
USB_TEMPLATE="${DEFAULT_TEMPLATE}"

# PCI devices to attach (comma-separated)
USB_PCI_DEVICES=""  # e.g., "dom0:00_14.0"
```

### Split-GPG

Secure GPG key management.

```bash
ENABLE_SPLIT_GPG="false"

# Backend qube (where keys are stored)
SPLIT_GPG_BACKEND="${VAULT_NAME}"

# Client qubes (comma-separated)
SPLIT_GPG_CLIENTS="${WORK_NAME}"
```

**Usage**: After setup, use `qubes-gpg-client` in client qubes.

### Split-SSH

Secure SSH key management.

```bash
ENABLE_SPLIT_SSH="false"

SPLIT_SSH_BACKEND="${VAULT_NAME}"
SPLIT_SSH_CLIENTS="${WORK_NAME}"
```

**Usage**: SSH keys stored in vault, accessed from work via qrexec.

## Qrexec Policies

Control inter-qube communication.

```bash
ENABLE_QREXEC_POLICIES="true"

# Allow file copy from work to vault
ALLOW_WORK_TO_VAULT_COPY="true"

# Allow file copy from untrusted to work (ask, allow, deny)
ALLOW_UNTRUSTED_TO_WORK_COPY="ask"

# Allow clipboard between work and vault
ALLOW_WORK_VAULT_CLIPBOARD="ask"
```

**Policy Options**:
* `allow` - Always allow
* `deny` - Always deny
* `ask` - Prompt user each time

## Topology Presets

Use pre-configured layouts optimized for specific use cases.

```bash
# Options: custom, journalist, developer, researcher, teacher, pentester
TOPOLOGY_PRESET="custom"
```

### Available Presets

**journalist**:
* work + vault + anon + untrusted
* Split-GPG enabled
* Emphasis on source protection

**developer**:
* work (4GB) + vault + untrusted
* Split-SSH enabled
* Development tools

**researcher**:
* work + vault + anon + untrusted + vpn
* VPN qube for institutional access
* Data protection focus

**teacher**:
* work + vault + untrusted + usb
* USB qube for devices
* Usability focus

**pentester**:
* All qubes enabled
* High memory allocations
* Security testing tools

## Advanced Firewall Configuration

### Custom Ports

```bash
# Format: protocol:port
WORK_ALLOWED_PORTS="tcp:80,tcp:443,udp:53,tcp:22,tcp:8080"
```

### Port Ranges

```bash
# Allow port range (requires modification of script)
# tcp:8000-9000
```

### Protocol-Specific Rules

```bash
# ICMP (ping)
# Add to firewall function in script:
# qvm-firewall work add action=accept proto=icmp
```

## Memory Optimization

### Low Memory Systems (8GB RAM)

```bash
WORK_MEMORY="1024"
VAULT_MEMORY="512"
ANON_MEMORY="512"
UNTRUSTED_MEMORY="512"
VPN_MEMORY="256"
```

### High Memory Systems (32GB+ RAM)

```bash
WORK_MEMORY="4096"
VAULT_MEMORY="2048"
ANON_MEMORY="2048"
UNTRUSTED_MEMORY="1024"
```

### Memory Balancing

Qubes uses memory balancing. Initial allocation can exceed physical RAM:

```bash
# Set max memory (allows balancing)
qvm-prefs work maxmem 4096

# Set minimum memory
qvm-prefs work memory 2048
```

## Package Management

### Fedora Templates

```bash
WORK_PACKAGES="vim git curl wget gcc make"
```

### Debian Templates

```bash
WORK_PACKAGES="vim git curl wget build-essential"
```

### Template-Specific Packages

Edit the script to install template-specific packages:

```bash
if template is fedora:
    install rpm packages
else if template is debian:
    install deb packages
```

## Environment Variables

Override config file settings via environment variables:

```bash
# Override template
DEFAULT_TEMPLATE="debian-12-minimal" ./qubes-setup-advanced.sh

# Enable verbose mode
VERBOSE=true ./qubes-setup-advanced.sh

# Dry run
DRY_RUN=true ./qubes-setup-advanced.sh
```

## Configuration Examples

### Minimal Setup (4GB RAM system)

```bash
ENABLE_WORK="true"
ENABLE_VAULT="true"
ENABLE_ANON="false"
ENABLE_UNTRUSTED="true"

WORK_MEMORY="1024"
VAULT_MEMORY="512"
UNTRUSTED_MEMORY="512"
```

### Maximum Security

```bash
WORK_FIREWALL_POLICY="deny-all"
ENABLE_SPLIT_GPG="true"
ENABLE_SPLIT_SSH="true"
ALLOW_UNTRUSTED_TO_WORK_COPY="deny"
UNTRUSTED_IS_DISPVM_TEMPLATE="true"
```

### Development Environment

```bash
TOPOLOGY_PRESET="developer"
WORK_MEMORY="4096"
WORK_PACKAGES="vim git curl wget build-essential nodejs python3"
ENABLE_SPLIT_SSH="true"
```

## Validation

After editing configuration:

```bash
# Test syntax
source qubes-config.conf
echo $WORK_NAME

# Dry run
./qubes-setup-advanced.sh --dry-run

# Validate
./qubes-setup-advanced.sh --validate
```

## Best Practices

1. **Always dry-run first** - Test changes before applying
2. **Backup config** - Keep a copy of working configuration
3. **Start minimal** - Add qubes as needed
4. **Monitor resources** - Check memory usage regularly
5. **Document changes** - Comment your modifications

## Configuration Management

### Version Control

```bash
# Track configuration changes
git init
git add qubes-config.conf
git commit -m "Initial configuration"
```

### Multiple Configs

```bash
# Keep different configurations
cp qubes-config.conf qubes-config-work.conf
cp qubes-config.conf qubes-config-home.conf

# Use specific config
./qubes-setup-advanced.sh --config qubes-config-work.conf
```

## Troubleshooting

### Config Not Loading

```bash
# Check file path
ls -l qubes-config.conf

# Check syntax
bash -n qubes-config.conf
source qubes-config.conf
```

### Template Issues

```bash
# List installed templates
qvm-template list --installed

# Install missing template
qubes-dom0-update --enablerepo=qubes-templates-itl <template>
```

### Memory Errors

```bash
# Check available memory
xl info | grep free_memory

# Reduce allocations
```

## Next Steps

* **[Getting Started](getting-started.html)** - Run your first setup
* **[Security Guide](security-guide.html)** - Harden configuration
* **[Troubleshooting](troubleshooting.html)** - Common issues
