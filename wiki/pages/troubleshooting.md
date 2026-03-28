# Troubleshooting Guide

Solutions to common issues with Qubes SDP.

## Installation Issues

### Script Permission Denied

**Problem**: `bash: ./qubes-setup.sh: Permission denied`

**Solution**:
```bash
chmod +x qubes-setup.sh
chmod +x qubes-setup-advanced.sh
```

### Template Not Found

**Problem**: `ERROR: Template fedora-40-minimal not found`

**Solutions**:

1. Install template manually:
```bash
qubes-dom0-update --enablerepo=qubes-templates-itl fedora-40-minimal
```

2. Enable auto-install in config:
```bash
AUTO_INSTALL_TEMPLATES="true"
```

3. Use different template:
```bash
DEFAULT_TEMPLATE="debian-12-minimal"
```

### Insufficient Memory

**Problem**: `ERROR: Not enough memory to create qube`

**Solutions**:

1. Reduce memory allocations in config:
```bash
WORK_MEMORY="1024"
VAULT_MEMORY="512"
ANON_MEMORY="512"
```

2. Close running qubes:
```bash
qvm-shutdown --all
```

3. Check available memory:
```bash
xl info | grep free_memory
```

### Network Qube Not Found

**Problem**: `ERROR: Network qube sys-firewall not found`

**Solution**:

1. Verify sys-firewall exists:
```bash
qvm-ls sys-firewall
```

2. If missing, create it via Qubes Manager or:
```bash
qvm-create --label red --property netvm=sys-net sys-firewall
qvm-prefs sys-firewall provides_network true
```

### Whonix Not Available

**Problem**: Anon qube fails because sys-whonix doesn't exist

**Solution**:

Script automatically falls back to sys-firewall. To install Whonix:

```bash
qubes-dom0-update --enablerepo=qubes-templates-community whonix-gateway-17 whonix-workstation-17
```

## Configuration Issues

### Config File Not Loading

**Problem**: Changes to config file not taking effect

**Solutions**:

1. Verify config file path:
```bash
ls -l qubes-config.conf
```

2. Check syntax:
```bash
bash -n qubes-config.conf
source qubes-config.conf
```

3. Specify config explicitly:
```bash
./qubes-setup-advanced.sh --config ./qubes-config.conf
```

### Invalid Configuration Values

**Problem**: Script fails with "invalid value" error

**Solutions**:

1. Check for typos:
```bash
# Correct
ENABLE_WORK="true"

# Wrong
ENABLE_WORK=true  # Missing quotes
ENABLE_WORK="True"  # Wrong case
```

2. Validate boolean values:
```bash
# Valid: "true" or "false"
# Invalid: "yes", "no", "1", "0"
```

3. Check memory values are numbers:
```bash
WORK_MEMORY="2048"  # Correct
WORK_MEMORY="2GB"   # Wrong
```

## Runtime Issues

### Qube Won't Start

**Problem**: `qvm-start work` fails or hangs

**Solutions**:

1. Check qube state:
```bash
qvm-ls work
```

2. Check memory:
```bash
qvm-prefs work memory
xl info | grep free_memory
```

3. Check logs:
```bash
journalctl -u qubes-vm@work
```

4. Force shutdown and restart:
```bash
qvm-kill work
qvm-start work
```

5. Check template:
```bash
qvm-prefs work template
qvm-ls <template>
```

### Firewall Blocks Everything

**Problem**: No network access in work qube

**Solutions**:

1. Check firewall rules:
```bash
qvm-firewall work list
```

2. Verify DNS is allowed:
```bash
qvm-firewall work add action=accept proto=udp dstport=53
```

3. Test connectivity:
```bash
qvm-run work 'ping -c 1 8.8.8.8'
qvm-run work 'curl -I https://www.example.com'
```

4. Temporarily allow all (for testing):
```bash
qvm-firewall work reset
# Then add back rules one by one
```

### Can't Copy Files to Vault

**Problem**: File copy to vault fails

**Solutions**:

1. Verify vault exists:
```bash
qvm-ls vault
```

2. Check qrexec policy:
```bash
cat /etc/qubes-rpc/policy/qubes.Filecopy | grep vault
```

3. Use correct command:
```bash
# From work qube GUI: Right-click → "Copy to other AppVM" → vault
# Or command line:
qvm-copy-to-vm vault /path/to/file
```

4. Check vault has space:
```bash
qvm-run vault 'df -h'
```

### Vault Has Network Access

**Problem**: Vault can ping internet (security issue!)

**Solution**:

1. Immediately disconnect:
```bash
qvm-prefs vault netvm ''
```

2. Verify:
```bash
qvm-prefs vault netvm
# Should show: (empty)

qvm-run vault 'ping -c 1 8.8.8.8'
# Should fail
```

3. Check config:
```bash
grep VAULT_NETVM qubes-config.conf
# Should be: VAULT_NETVM=""
```

## Backup/Restore Issues

### Backup Fails

**Problem**: Backup command fails or produces error

**Solutions**:

1. Check disk space:
```bash
df -h /var/backups
```

2. Verify backup destination exists:
```bash
mkdir -p /var/backups/qubes-sdp
```

3. Check qube state (must be running):
```bash
qvm-start work
qvm-start vault
```

4. Use manual backup:
```bash
qvm-backup work vault /var/backups/qubes-sdp/manual-backup
```

### Restore Fails

**Problem**: Cannot restore from backup

**Solutions**:

1. Verify backup file exists:
```bash
ls -l /var/backups/qubes-sdp/
```

2. Check backup integrity:
```bash
qvm-backup-restore --verify /var/backups/qubes-sdp/backup-*
```

3. List backup contents:
```bash
qvm-backup-restore --list /var/backups/qubes-sdp/backup-*
```

4. Restore specific qube:
```bash
qvm-backup-restore /var/backups/qubes-sdp/backup-* --include vault
```

## Split-GPG Issues

### GPG Operations Fail

**Problem**: `qubes-gpg-client` fails or hangs

**Solutions**:

1. Verify split-GPG is configured:
```bash
grep SPLIT_GPG qubes-config.conf
```

2. Check qrexec policy:
```bash
cat /etc/qubes-rpc/policy/qubes.Gpg
```

3. Verify vault is running:
```bash
qvm-start vault
```

4. Set GPG domain in work qube:
```bash
export QUBES_GPG_DOMAIN=vault
echo 'export QUBES_GPG_DOMAIN=vault' >> ~/.bashrc
```

5. Test:
```bash
qubes-gpg-client --list-keys
```

### GPG Keys Not Found

**Problem**: No keys available in split-GPG

**Solution**:

Keys must be in vault. Generate or import:

```bash
# In vault qube
gpg --gen-key
# OR
gpg --import /path/to/private-key.asc
```

Then use from work:
```bash
qubes-gpg-client --list-keys
```

## Split-SSH Issues

### SSH Keys Not Available

**Problem**: Split-SSH not working

**Solutions**:

1. Verify configuration:
```bash
grep SPLIT_SSH qubes-config.conf
```

2. Check keys exist in vault:
```bash
qvm-run vault 'ls ~/.ssh/'
```

3. Set SSH_AUTH_SOCK in work:
```bash
export SSH_AUTH_SOCK=~/.SSH_AGENT_vault
echo 'export SSH_AUTH_SOCK=~/.SSH_AGENT_vault' >> ~/.bashrc
```

4. Start vault:
```bash
qvm-start vault
```

## Performance Issues

### Qubes Are Slow

**Solutions**:

1. Reduce running qubes:
```bash
qvm-shutdown <unused-qubes>
```

2. Increase memory allocation:
```bash
qvm-prefs work memory 4096
```

3. Use minimal templates:
```bash
# Switch to minimal template
qvm-prefs work template fedora-40-minimal
```

4. Check dom0 resources:
```bash
free -h
top
```

5. Disable unnecessary services:
```bash
qvm-service work cups off
qvm-service work network-manager off
```

### High Disk Usage

**Solutions**:

1. Remove old templates:
```bash
qvm-template list --installed
qvm-template remove <old-template>
```

2. Clean package cache in templates:
```bash
qvm-run -u root <template> 'dnf clean all'  # Fedora
qvm-run -u root <template> 'apt-get clean'  # Debian
```

3. Remove old backups:
```bash
ls -lh /var/backups/qubes-sdp/
rm /var/backups/qubes-sdp/old-backup-*
```

4. Trim disk:
```bash
qvm-trim-template <template>
qvm-volume revert <qube>:private
```

## Update Issues

### Template Update Fails

**Problem**: Cannot update template

**Solutions**:

1. Check template is running:
```bash
qvm-start <template>
```

2. Update manually:
```bash
# Fedora
qvm-run -u root <template> 'dnf update -y'

# Debian
qvm-run -u root <template> 'apt-get update && apt-get upgrade -y'
```

3. Check network in template:
```bash
qvm-run <template> 'ping -c 1 8.8.8.8'
```

4. Set netvm if missing:
```bash
qvm-prefs <template> netvm sys-firewall
```

### Dom0 Update Fails

**Problem**: dom0 updates fail

**Solutions**:

1. Check network:
```bash
ping -c 1 8.8.8.8
```

2. Clear cache:
```bash
sudo qubes-dom0-update --clean
```

3. Try different mirror:
```bash
sudo qubes-dom0-update --enablerepo=qubes-dom0-current-testing
```

## Rollback Issues

### Rollback Script Not Found

**Problem**: Cannot rollback failed setup

**Solution**:

Rollback script is auto-generated. If missing, manually remove created qubes:

```bash
qvm-remove work
qvm-remove vault
qvm-remove anon
qvm-remove untrusted
```

### Rollback Fails

**Problem**: Rollback script fails to remove qubes

**Solution**:

Force remove:
```bash
qvm-remove --force <qube-name>
```

Or use make:
```bash
make -f Makefile.qubes clean-all
```

## Diagnostic Commands

### Check System Status

```bash
# List all qubes
qvm-ls

# Check specific qube
qvm-prefs work

# Check memory
xl info | grep memory

# Check disk
df -h

# Check templates
qvm-template list --installed
```

### Check Network

```bash
# Test connectivity
qvm-run work 'ping -c 1 8.8.8.8'
qvm-run work 'curl -I https://www.example.com'

# Check firewall
qvm-firewall work list

# Check DNS
qvm-run work 'nslookup google.com'
```

### Check Logs

```bash
# Setup log
less /var/log/qubes-sdp-setup.log

# Qube log
journalctl -u qubes-vm@work

# Dom0 log
journalctl -b

# Qrexec log
journalctl -u qubes-qrexec-policy-daemon
```

## Getting More Help

### Enable Debug Mode

```bash
# Verbose output
VERBOSE=true ./qubes-setup-advanced.sh

# Or in config
VERBOSE="true"
```

### Collect Diagnostic Info

```bash
# System info
qvm-ls --fields ALL > qvm-info.txt
xl info > xl-info.txt
df -h > disk-info.txt
free -h > memory-info.txt

# Logs
cat /var/log/qubes-sdp-setup.log > setup-log.txt
journalctl -b > journal.txt
```

### Report a Bug

When reporting issues, include:

1. Qubes OS version
2. Hardware specs (RAM, CPU)
3. Error message (exact text)
4. Steps to reproduce
5. Log files
6. Configuration used

### Community Support

* [Qubes OS Forum](https://forum.qubes-os.org/)
* [Qubes OS Mailing Lists](https://www.qubes-os.org/support/)
* Project issue tracker

## Common Error Messages

### "Command not found: qvm-create"

Not running in dom0 or Qubes not installed properly.

### "Qube already exists"

Normal - script is idempotent. Existing qubes are skipped.

### "netvm loopback detected"

Trying to create circular network dependency. Check netvm settings.

### "Not enough memory"

Reduce memory allocations or close running qubes.

### "Template has updates available"

Update template before creating qubes:
```bash
make -f Makefile.qubes template-update
```

## Prevention Tips

1. **Always dry-run first**
```bash
./qubes-setup-advanced.sh --dry-run
```

2. **Validate before applying**
```bash
./qubes-setup-advanced.sh --validate
```

3. **Keep backups current**
```bash
make -f Makefile.qubes backup
```

4. **Review logs regularly**
```bash
less /var/log/qubes-sdp-setup.log
```

5. **Update regularly**
```bash
make -f Makefile.qubes template-update
```

## Still Stuck?

* Review the **[FAQ](faq.html)**
* Check the **[Configuration Guide](configuration.html)**
* Read the **[Security Guide](security-guide.html)**
* Consult [Qubes OS Documentation](https://www.qubes-os.org/doc/)
