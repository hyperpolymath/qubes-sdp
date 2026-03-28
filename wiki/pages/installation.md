# Installation Guide

Complete installation instructions for Qubes SDP.

## Prerequisites

### System Requirements

* **Qubes OS 4.1 or later** - Tested on 4.1 and 4.2
* **dom0 access** - All scripts must run in dom0
* **Sufficient RAM** - Minimum 8GB recommended (16GB+ ideal)
* **Disk space** - At least 50GB free for qubes and templates

### Required Knowledge

* Basic Qubes OS concepts (qubes, templates, domains)
* Comfort with command line interface
* Understanding of VM management

### Required Templates

At minimum, you need:
* **fedora-40-minimal** (default) OR
* **debian-12-minimal**

The setup script can automatically install missing templates.

## Installation Methods

### Method 1: Direct Download to dom0

**Warning**: Directly downloading to dom0 is generally discouraged. Use Method 2 or 3 instead.

```bash
# Only if absolutely necessary
cd /tmp
# Download from trusted source
./qubes-setup.sh
```

### Method 2: Via AppVM (Recommended)

```bash
# Step 1: Download in a qube (e.g., work or personal)
cd ~/Downloads
git clone https://github.com/yourusername/qubes-sdp.git
# OR download and extract zip file

# Step 2: Transfer to dom0
# In dom0:
qvm-run --pass-io work 'cat /home/user/Downloads/qubes-sdp/qubes-setup.sh' > qubes-setup.sh
qvm-run --pass-io work 'cat /home/user/Downloads/qubes-sdp/qubes-config.conf' > qubes-config.conf

# For entire directory:
cd /tmp
qvm-run --pass-io work 'tar -C /home/user/Downloads/qubes-sdp -c .' | tar -x
```

### Method 3: Using qvm-copy

```bash
# In source qube:
cd /home/user/Downloads
qvm-copy qubes-sdp

# In dom0:
# Files will be in ~/QubesIncoming/<source-qube>/
mv ~/QubesIncoming/<source-qube>/qubes-sdp /tmp/
cd /tmp/qubes-sdp
```

### Method 4: Install System-Wide

```bash
# After copying files to dom0:
cd /tmp/qubes-sdp
make -f Makefile.qubes install

# This installs to:
# /usr/local/bin/qubes-sdp/        - Scripts
# /usr/local/share/qubes-sdp/      - Documentation
# /etc/qubes-sdp/                  - Configuration examples

# Now you can run from anywhere:
qubes-setup
qubes-setup-advanced
```

## Post-Installation Setup

### 1. Verify Installation

```bash
# Check script syntax
bash -n qubes-setup.sh
bash -n qubes-setup-advanced.sh

# Test dry-run
./qubes-setup.sh --dry-run
```

### 2. Configure Templates

```bash
# List available templates
qvm-template list --installed

# Install required templates if missing
qubes-dom0-update --enablerepo=qubes-templates-itl fedora-40-minimal

# Update templates
sudo qubes-dom0-update
qvm-run -u root fedora-40-minimal 'dnf update -y'
```

### 3. Review Configuration

```bash
# Edit configuration file
vi qubes-config.conf

# Key settings to review:
# - DEFAULT_TEMPLATE
# - Memory allocations
# - Network settings
# - Enabled qubes
# - Topology preset
```

### 4. Run Pre-flight Checks

```bash
# Validate environment
./qubes-setup-advanced.sh --validate

# Check what would be created
./qubes-setup-advanced.sh --dry-run
```

## First Run

### Simple Setup

```bash
./qubes-setup.sh
```

### Advanced Setup

```bash
./qubes-setup-advanced.sh --config qubes-config.conf
```

### Interactive Setup

```bash
./qubes-setup-advanced.sh --interactive
```

## Verification

After setup completes:

```bash
# List created qubes
qvm-ls | grep -E "(work|vault|anon|untrusted)"

# Check properties
qvm-prefs work
qvm-prefs vault

# Verify firewall
qvm-firewall work list

# Run health check
./qubes-setup-advanced.sh --health-check

# View logs
less /var/log/qubes-sdp-setup.log
```

## Troubleshooting Installation

### Script Won't Run

```bash
# Check permissions
ls -l qubes-setup.sh
# Should show -rwxr-xr-x

# Make executable if needed
chmod +x qubes-setup.sh

# Check for syntax errors
bash -n qubes-setup.sh
```

### Template Not Found

```bash
# Install missing template
qubes-dom0-update --enablerepo=qubes-templates-itl <template-name>

# Or set AUTO_INSTALL_TEMPLATES=true in config
```

### Insufficient Memory

```bash
# Check available memory
xl info | grep free_memory

# Reduce memory allocations in config:
WORK_MEMORY="1024"
VAULT_MEMORY="512"
```

### Network Qube Missing

```bash
# Verify sys-firewall exists
qvm-ls sys-firewall

# If missing, Qubes installation may be incomplete
# Use different netvm or create sys-firewall
```

### Whonix Not Available

The setup automatically falls back to sys-firewall if sys-whonix isn't installed:

```bash
# To install Whonix:
qubes-dom0-update --enablerepo=qubes-templates-community whonix-*
```

## Updating

### Update Scripts

```bash
# Download new version to qube, then:
qvm-run --pass-io <qube> 'cat /path/to/new/qubes-setup.sh' > qubes-setup.sh
chmod +x qubes-setup.sh
```

### Update Templates

```bash
# Using the template manager
make -f Makefile.qubes template-update

# Or manually
qvm-run -u root <template> 'dnf update -y'
```

## Uninstallation

### Remove Qubes

```bash
# Remove all SDP qubes (DESTRUCTIVE!)
make -f Makefile.qubes clean-all

# Or manually:
qvm-remove work
qvm-remove vault
qvm-remove anon
qvm-remove untrusted
```

### Remove System-Wide Installation

```bash
make -f Makefile.qubes uninstall

# This removes:
# - /usr/local/bin/qubes-sdp/
# - /usr/local/share/qubes-sdp/
# - Symbolic links

# Preserves:
# - /etc/qubes-sdp/ (configuration)
```

### Clean Logs

```bash
make -f Makefile.qubes clean
```

## Salt Stack Installation

### Copy Salt States

```bash
# Copy to Salt directory
sudo cp -r qubes-salt/*.sls /srv/salt/

# Or create user salt directory
sudo mkdir -p /srv/salt/user
sudo cp qubes-salt/*.sls /srv/salt/user/
```

### Apply States

```bash
# Test mode (dry run)
sudo qubesctl state.apply qubes-sdp test=True

# Apply for real
sudo qubesctl state.apply qubes-sdp
```

### Verify Salt Installation

```bash
# Check state file syntax
sudo qubesctl state.show_sls qubes-sdp

# View available states
sudo qubesctl state.show_top
```

## Next Steps

1. **[Configuration](configuration.html)** - Customize your setup
2. **[Getting Started](getting-started.html)** - First steps
3. **[Security Guide](security-guide.html)** - Harden your system

## Additional Resources

* [Qubes OS Installation Guide](https://www.qubes-os.org/doc/installation-guide/)
* [Qubes OS Customization](https://www.qubes-os.org/doc/#customization-guides)
* [Salt Stack for Qubes](https://www.qubes-os.org/doc/salt/)
