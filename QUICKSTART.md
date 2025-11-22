# Quick Start Guide

Get Qubes SDP running in 5 minutes.

## Prerequisites Check

✅ Running Qubes OS 4.1 or later
✅ At least 8GB RAM (16GB recommended)
✅ 50GB free disk space
✅ Internet connection (for template downloads)

## Installation in 3 Steps

### Step 1: Download (in a qube, NOT dom0)

Choose one method:

**Option A: Git Clone**
```bash
# In a qube (e.g., work or personal):
cd ~/Downloads
git clone https://github.com/yourusername/qubes-sdp.git
```

**Option B: Download ZIP**
```bash
# Download and extract
cd ~/Downloads
wget https://github.com/yourusername/qubes-sdp/archive/main.zip
unzip main.zip
mv qubes-sdp-main qubes-sdp
```

### Step 2: Transfer to dom0

```bash
# In dom0 terminal:
cd /tmp
qvm-run --pass-io <qube-name> 'tar -C /home/user/Downloads/qubes-sdp -c .' | tar -x
```

Replace `<qube-name>` with the qube where you downloaded (e.g., `work`).

### Step 3: Run Setup

```bash
# Still in dom0:
cd /tmp/qubes-sdp

# Option 1: Simple setup (recommended for first time)
./qubes-setup.sh

# Option 2: Test first with dry-run
./qubes-setup.sh --dry-run
# Then run for real:
./qubes-setup.sh
```

That's it! Setup creates 4 qubes:
- **work** - Your daily driver (2GB RAM, restricted network)
- **vault** - Air-gapped sensitive storage (1GB RAM, NO network)
- **anon** - Anonymous Tor qube (1GB RAM)
- **untrusted** - Disposable risky content handler (1GB RAM)

## Verification

Check everything was created:

```bash
# List SDP qubes
qvm-ls | grep -E "(work|vault|anon|untrusted)"

# Check vault has no network (should be empty)
qvm-prefs vault netvm

# Check work firewall rules
qvm-firewall work list

# Run status check
./qubes-status.sh
```

## First Use

### Start a Qube

```bash
qvm-start work
```

Or click "work" in Qubes menu.

### Transfer File to Vault

From work qube:
1. Right-click file
2. Select "Copy to other AppVM"
3. Choose "vault"

Or command line:
```bash
qvm-copy-to-vm vault /path/to/file
```

### Use Disposable VM

```bash
# Open file in disposable
qvm-open-in-dvm suspicious-file.pdf

# Run browser in disposable
qvm-run --dispvm untrusted firefox
```

## Next Steps

### Customize Your Setup

1. Copy example config:
```bash
cp examples/journalist-config.conf qubes-config.conf
```

2. Edit as needed:
```bash
vi qubes-config.conf
```

3. Run advanced setup:
```bash
./qubes-setup-advanced.sh
```

### Enable Advanced Features

**Split-GPG (for encrypted email)**:
```bash
# Edit config
ENABLE_SPLIT_GPG="true"

# Re-run setup
./qubes-setup-advanced.sh
```

**Split-SSH (for development)**:
```bash
ENABLE_SPLIT_SSH="true"
./qubes-setup-advanced.sh
```

**Automated Backups**:
```bash
AUTO_BACKUP="true"
BACKUP_SCHEDULE="0 2 * * *"  # Daily at 2 AM
./qubes-setup-advanced.sh
```

### Use Topology Presets

```bash
# Journalist workflow
make -f Makefile.qubes setup-preset-journalist

# Developer workflow
make -f Makefile.qubes setup-preset-developer

# Minimal (low RAM)
TOPOLOGY_PRESET="custom"
# Edit config for minimal resources
./qubes-setup-advanced.sh
```

## Common Tasks

### Status and Monitoring

```bash
# Quick status
./tools/qubes-status.sh

# Interactive dashboard
./tools/qubes-dashboard.sh

# Firewall analysis
./tools/qubes-firewall-analyzer.sh
```

### Template Management

```bash
# Update all templates
./tools/qubes-template-manager.sh update

# Clean package cache
./tools/qubes-template-manager.sh clean
```

### Backups

```bash
# Create backup
make -f Makefile.qubes backup

# Verify backup
./tools/qubes-backup-validator.sh

# Restore from backup
./tools/qubes-restore.sh /var/backups/qubes-sdp/backup-20240101
```

## Troubleshooting

### "Template not found"

```bash
# Install missing template
qubes-dom0-update --enablerepo=qubes-templates-itl fedora-40-minimal

# Or enable auto-install
# Edit qubes-config.conf:
AUTO_INSTALL_TEMPLATES="true"
```

### "Insufficient memory"

```bash
# Reduce memory allocations
# Edit qubes-config.conf:
WORK_MEMORY="1024"
VAULT_MEMORY="512"
ANON_MEMORY="512"
```

### "sys-whonix not found"

```bash
# Anon qube automatically falls back to sys-firewall
# To install Whonix:
qubes-dom0-update --enablerepo=qubes-templates-community whonix-gateway-17 whonix-workstation-17
```

### Can't access work qube

```bash
# Start it
qvm-start work

# Check if it exists
qvm-ls work

# Check logs
journalctl -u qubes-vm@work
```

## Tips

### Best Practices

1. **Always test with dry-run first**
   ```bash
   ./qubes-setup-advanced.sh --dry-run
   ```

2. **Backup vault regularly**
   ```bash
   make -f Makefile.qubes backup
   ```

3. **Keep templates updated**
   ```bash
   make -f Makefile.qubes template-update
   ```

4. **Never connect vault to network**
   ```bash
   # Verify it's air-gapped:
   qvm-prefs vault netvm
   # Should be empty
   ```

5. **Use untrusted for risky files**
   ```bash
   qvm-open-in-dvm suspicious.pdf
   ```

### Keyboard Shortcuts

- `Alt+F3` - Qubes menu
- `Ctrl+Alt+Del` - Lock screen
- Drag window border to move between qubes

### Memory Optimization

If you have limited RAM:

```bash
# Close unused qubes
qvm-shutdown work

# Reduce allocations
# In config: set all memory to 512 or 1024

# Disable auto-start
WORK_AUTOSTART="false"
```

## Getting Help

### Documentation

- **Full docs**: [README.md](README.md)
- **Wiki**: [wiki/](wiki/)
- **Configuration**: [wiki/pages/configuration.md](wiki/pages/configuration.md)
- **Troubleshooting**: [wiki/pages/troubleshooting.md](wiki/pages/troubleshooting.md)
- **FAQ**: [wiki/pages/faq.md](wiki/pages/faq.md)

### Commands Reference

```bash
# Setup
./qubes-setup.sh                    # Simple
./qubes-setup-advanced.sh           # Advanced
make -f Makefile.qubes setup        # Via make

# Status
./tools/qubes-status.sh             # Status
./tools/qubes-dashboard.sh          # Dashboard
qvm-ls                              # List all qubes

# Management
qvm-start work                      # Start qube
qvm-shutdown work                   # Stop qube
qvm-prefs work                      # Show settings
qvm-firewall work list              # Firewall rules

# Backup
make -f Makefile.qubes backup       # Create
./tools/qubes-backup-validator.sh   # Verify
./tools/qubes-restore.sh <path>     # Restore

# Templates
./tools/qubes-template-manager.sh update   # Update
make -f Makefile.qubes template-update     # Via make
```

## What's Next?

1. **Read the documentation**
   - [Security Guide](wiki/pages/security-guide.md)
   - [Configuration Guide](wiki/pages/configuration.md)

2. **Set up Split-GPG/SSH**
   - [Split-GPG Guide](wiki/pages/split-gpg.md)
   - [Split-SSH Guide](wiki/pages/split-ssh.md)

3. **Configure backups**
   - [Backup & Restore Guide](wiki/pages/backup-restore.md)

4. **Explore tools**
   - [Tools README](tools/README.md)

5. **Join community**
   - Report issues
   - Share configurations
   - Contribute improvements

## Quick Command Reference Card

Save this for easy reference:

```bash
# Status
./tools/qubes-status.sh

# Start qube
qvm-start <name>

# Copy to vault
qvm-copy-to-vm vault <file>

# Disposable VM
qvm-run --dispvm untrusted firefox

# Backup
make -f Makefile.qubes backup

# Update templates
make -f Makefile.qubes template-update

# Firewall rules
qvm-firewall work list

# Health check
./qubes-setup-advanced.sh --health-check
```

---

**Welcome to Qubes SDP!** 🎉

You now have a secure, isolated work environment. Explore the documentation to learn more about advanced features.

**Need help?** Check the [FAQ](wiki/pages/faq.md) or [Troubleshooting Guide](wiki/pages/troubleshooting.md).
