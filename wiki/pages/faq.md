# Frequently Asked Questions

Common questions and answers about Qubes SDP.

## General Questions

### What is Qubes SDP?

Qubes SDP (Software Development Platform) is an automated setup system for Qubes OS that creates a secure, isolated work environment with one command. It implements Qubes best practices by default and provides multiple deployment methods.

### Why use Qubes SDP?

* **Save time** - Automated setup vs manual configuration
* **Best practices** - Security-focused defaults
* **Consistency** - Reproducible configurations
* **Flexibility** - Choose from presets or customize
* **Documentation** - Comprehensive guides

### Is Qubes SDP official?

No, Qubes SDP is a community project, not officially part of Qubes OS. However, it follows official Qubes documentation and best practices.

### Is it safe?

Yes, when used properly:
* All scripts are open source for review
* Dry-run mode lets you test before applying
* Follows Qubes security best practices
* Includes rollback capabilities

**Always review scripts before running in dom0!**

## Installation

### How do I install Qubes SDP?

See the **[Installation Guide](installation.html)**. Basic steps:

1. Download in a qube
2. Transfer to dom0 using qvm-run
3. Run the setup script

### Can I download directly to dom0?

Technically yes, but **not recommended**. Qubes philosophy is to keep dom0 isolated. Transfer from a qube instead.

### Which templates do I need?

By default, `fedora-40-minimal`. The script can auto-install missing templates, or you can specify alternatives in the config.

### How much RAM do I need?

Minimum 8GB, recommended 16GB+. You can reduce memory allocations for each qube in the configuration.

## Configuration

### How do I customize the setup?

Edit `qubes-config.conf` before running the advanced setup script. See **[Configuration Guide](configuration.html)**.

### Can I use different templates?

Yes! Set `DEFAULT_TEMPLATE` in the config:

```bash
DEFAULT_TEMPLATE="debian-12-minimal"
```

### What are topology presets?

Pre-configured setups optimized for specific use cases:
* journalist
* developer
* researcher
* teacher
* pentester

Set `TOPOLOGY_PRESET` in the config.

### How do I add custom packages?

Edit the `*_PACKAGES` variables in the config:

```bash
WORK_PACKAGES="vim git curl wget python3 nodejs"
```

## Usage

### How do I start a qube?

```bash
qvm-start work
```

Or click the app menu icon.

### How do I transfer files to vault?

Use qvm-copy:

```bash
# In source qube, right-click file → "Copy to other AppVM"
# Or command line:
qvm-copy-to-vm vault /path/to/file
```

**Never** connect vault to network!

### How do I use disposable VMs?

```bash
# Run application in disposable
qvm-run --dispvm untrusted firefox

# Open file in disposable
qvm-open-in-dvm suspicious.pdf
```

### Why can't vault access the network?

This is intentional! Vault is air-gapped for maximum security. Sensitive data should never touch the network.

## Troubleshooting

### "Template not found" error

Install the template:

```bash
qubes-dom0-update --enablerepo=qubes-templates-itl <template-name>
```

Or set `AUTO_INSTALL_TEMPLATES="true"` in config.

### "Insufficient memory" error

Reduce memory allocations in config:

```bash
WORK_MEMORY="1024"
VAULT_MEMORY="512"
```

### "Network qube not found" error

Ensure sys-firewall exists. If using sys-whonix, install Whonix or use the fallback:

```bash
ANON_NETVM_FALLBACK="sys-firewall"
```

### Firewall blocks needed ports

Add ports to allowed list:

```bash
WORK_ALLOWED_PORTS="tcp:80,tcp:443,udp:53,tcp:8080"
```

### Can't access work qube after setup

Start it:

```bash
qvm-start work
```

Check memory:

```bash
xl info | grep free_memory
```

## Advanced Features

### What is split-GPG?

A Qubes feature where GPG keys are stored in an air-gapped qube (vault) but can be used from other qubes (work) via qrexec. Keys never leave vault.

See **[Split-GPG Guide](split-gpg.html)**.

### What is split-SSH?

Similar to split-GPG, but for SSH keys. Keys stored in vault, used from work.

See **[Split-SSH Guide](split-ssh.html)**.

### Can I use a VPN?

Yes! Enable the VPN qube:

```bash
ENABLE_VPN="true"
```

See **[VPN Setup](vpn-setup.html)**.

### What about Whonix?

If sys-whonix is installed, the anon qube will use it automatically. Otherwise, it falls back to sys-firewall (less anonymous).

Install Whonix:

```bash
qubes-dom0-update --enablerepo=qubes-templates-community whonix-*
```

## Security

### Is the vault really air-gapped?

Yes, if configured correctly (netvm=""). Verify:

```bash
qvm-prefs vault netvm
# Should be empty

qvm-run vault 'ping -c 1 8.8.8.8'
# Should fail
```

### Can untrusted qube access my files?

No, qubes are isolated. Files can only be transferred via explicit user action (qvm-copy) or qrexec policies.

### What if a qube gets compromised?

* Other qubes remain protected (isolation)
* Shutdown compromised qube
* Remove and recreate from scratch
* Restore from backup if needed

### Should I use encrypted backups?

YES! Always encrypt backups:

```bash
BACKUP_COMPRESSION="true"
BACKUP_PASSPHRASE_FILE="/path/to/passphrase"
```

### How often should I update templates?

Weekly minimum, daily for critical systems:

```bash
make -f Makefile.qubes template-update
```

## Backups

### How do I backup my qubes?

Automatic backups can be configured:

```bash
AUTO_BACKUP="true"
BACKUP_SCHEDULE="0 2 * * *"  # Daily at 2 AM
```

Or manually:

```bash
make -f Makefile.qubes backup
```

### How do I restore from backup?

```bash
qvm-backup-restore /path/to/backup
```

See **[Backup & Restore](backup-restore.html)**.

### What should I backup?

At minimum:
* vault (sensitive data)
* work (important files)

Configure in:

```bash
BACKUP_QUBES="vault,work"
```

## Performance

### Qubes are slow, what can I do?

1. Reduce memory allocations
2. Close unused qubes
3. Use minimal templates
4. Add more RAM to physical machine
5. Reduce number of running qubes

### How much disk space do I need?

* Each qube: ~2-5GB
* Templates: ~2-4GB each
* Dom0: ~10GB
* Backups: Variable

Minimum 50GB free recommended.

### Can I run this on 4GB RAM?

Technically yes, but not recommended. Reduce allocations:

```bash
WORK_MEMORY="512"
VAULT_MEMORY="256"
ENABLE_ANON="false"
```

## Compatibility

### Which Qubes OS versions are supported?

Tested on:
* Qubes OS 4.1
* Qubes OS 4.2

Should work on 4.0+, but not tested.

### Can I use on Debian dom0?

Yes, scripts are shell-compatible. Some commands may need adjustment.

### Does it work with Whonix?

Yes! If sys-whonix is installed, anon qube will use it automatically.

### Can I mix Fedora and Debian qubes?

Yes! Set per-qube templates:

```bash
WORK_TEMPLATE="fedora-40-minimal"
VAULT_TEMPLATE="debian-12-minimal"
```

## Salt Stack

### What is Salt Stack mode?

An alternative deployment method using Qubes' Salt configuration management. More declarative than bash scripts.

See `qubes-salt/README.md`.

### Should I use Salt or bash scripts?

* **Salt**: Better for maintaining state, multiple systems
* **Bash**: Better for one-time setup, more flexible

Both work equally well.

### How do I use Salt mode?

```bash
sudo cp qubes-salt/*.sls /srv/salt/
sudo qubesctl state.apply qubes-sdp
```

## Maintenance

### How do I update Qubes SDP?

Download new version, transfer to dom0, run setup again. Existing qubes won't be affected.

### How do I add a new qube?

1. Edit config to enable new qube
2. Run setup again (idempotent)

Or create manually:

```bash
qvm-create --label green --template fedora-40-minimal myqube
```

### How do I remove a qube?

```bash
qvm-remove <qube-name>
```

Or remove all SDP qubes:

```bash
make -f Makefile.qubes clean-all
```

### Can I modify qubes after setup?

Yes! Qubes can be modified at any time:

```bash
qvm-prefs work memory 4096
qvm-firewall work add action=accept proto=tcp dstport=22
```

## Errors

### "Permission denied" when running script

Make executable:

```bash
chmod +x qubes-setup.sh
```

### "Command not found: qvm-create"

Not running in dom0, or Qubes not properly installed.

### "Qube already exists"

Expected behavior. Script skips existing qubes. Use clean-all to remove first, or ignore the warning.

### Dry-run mode hangs

Bug in progress indicator. Use `--quiet` flag:

```bash
./qubes-setup-advanced.sh --dry-run --quiet
```

## Contributing

### Can I contribute to Qubes SDP?

Yes! Contributions welcome:

* Bug reports
* Feature requests
* Documentation improvements
* Code contributions

See **[Contributing Guide](contributing.html)**.

### Where do I report bugs?

Open an issue on the project repository.

### Can I create my own presets?

Yes! Edit `qubes-setup-advanced.sh` and add a new `apply_preset_*` function.

## Getting Help

### Where can I get more help?

* **[Troubleshooting Guide](troubleshooting.html)**
* **[Qubes OS Documentation](https://www.qubes-os.org/doc/)**
* **[Qubes OS Forum](https://forum.qubes-os.org/)**
* Project issue tracker

### How do I enable debug mode?

```bash
VERBOSE=true ./qubes-setup-advanced.sh
```

Or edit config:

```bash
VERBOSE="true"
```

### Where are the logs?

```bash
less /var/log/qubes-sdp-setup.log
```

## Quick Reference

### Common Commands

```bash
# Setup
./qubes-setup.sh                    # Simple setup
./qubes-setup-advanced.sh           # Advanced setup
make -f Makefile.qubes setup        # Using make

# Management
qvm-start work                      # Start qube
qvm-shutdown work                   # Stop qube
qvm-ls                              # List qubes
qvm-prefs work                      # Show properties

# Files
qvm-copy-to-vm vault file.txt       # Copy to vault
qvm-run work 'ls ~'                 # Run command

# Firewall
qvm-firewall work list              # List rules
qvm-firewall work add ...           # Add rule

# Backup
make -f Makefile.qubes backup       # Create backup
qvm-backup-restore /path/to/backup  # Restore

# Troubleshooting
./qubes-setup-advanced.sh --validate    # Validate setup
./qubes-setup-advanced.sh --dry-run     # Test changes
less /var/log/qubes-sdp-setup.log       # View logs
```

### Config File Locations

* Setup scripts: `./qubes-setup*.sh`
* Configuration: `./qubes-config.conf`
* Salt states: `./qubes-salt/*.sls`
* Logs: `/var/log/qubes-sdp-setup.log`
* Installed: `/usr/local/bin/qubes-sdp/`

## Still Have Questions?

Check the full documentation:

* **[Getting Started](getting-started.html)**
* **[Installation](installation.html)**
* **[Configuration](configuration.html)**
* **[Security Guide](security-guide.html)**
* **[Troubleshooting](troubleshooting.html)**
