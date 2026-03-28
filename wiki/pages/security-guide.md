# Security Guide

Best practices for maintaining a secure Qubes SDP environment.

## Security Principles

Qubes SDP implements several core security principles:

1. **Isolation** - Separate qubes for different trust levels
2. **Least Privilege** - Minimal permissions and network access
3. **Defense in Depth** - Multiple security layers
4. **Fail Secure** - Default deny policies
5. **Auditability** - Comprehensive logging

## Qube Trust Levels

### Vault (Highest Trust)
* **Network**: None (air-gapped)
* **Purpose**: Sensitive data storage
* **Threats**: Physical access, side channels
* **Mitigations**: No network, encrypted storage

### Work (Medium Trust)
* **Network**: Restricted (HTTP/HTTPS/DNS only)
* **Purpose**: Daily activities
* **Threats**: Network attacks, malicious websites
* **Mitigations**: Firewall rules, minimal template

### Anon (Low Trust)
* **Network**: Tor only (via sys-whonix)
* **Purpose**: Anonymous communications
* **Threats**: Traffic analysis, Tor vulnerabilities
* **Mitigations**: Whonix isolation, no persistent data

### Untrusted (Lowest Trust)
* **Network**: Full internet (sys-firewall)
* **Purpose**: Risky downloads, testing
* **Threats**: Malware, exploits
* **Mitigations**: Disposable VMs, no valuable data

## Firewall Configuration

### Default Deny

All qubes start with deny-all, then allow specific services:

```bash
# Work qube firewall (restrictive)
qvm-firewall work reset
qvm-firewall work add action=accept proto=tcp dstport=80
qvm-firewall work add action=accept proto=tcp dstport=443
qvm-firewall work add action=accept proto=udp dstport=53
qvm-firewall work add action=drop
```

### Verify Rules

```bash
# List all rules
qvm-firewall work list

# Test connectivity
qvm-run work 'curl -I https://www.example.com'
qvm-run work 'ping -c 1 8.8.8.8'  # Should fail (ICMP blocked)
```

### Custom Rules

```bash
# Allow SSH
qvm-firewall work add action=accept proto=tcp dstport=22

# Allow specific IP
qvm-firewall work add action=accept dsthost=192.168.1.100

# Allow DNS only to specific server
qvm-firewall work add action=accept proto=udp dstport=53 dsthost=8.8.8.8
```

## Network Isolation

### Air-Gapped Vault

The vault qube MUST have no network access:

```bash
# Verify no network
qvm-prefs vault netvm
# Should output: (empty) or -

# Test (should fail)
qvm-run vault 'ping -c 1 8.8.8.8'
```

**Never** connect vault to network, even temporarily.

### File Transfer to Vault

Use qvm-copy or qvm-move:

```bash
# From work to vault
qvm-copy-to-vm vault /path/to/file

# Move (deletes original)
qvm-move-to-vm vault /path/to/file
```

### Clipboard Policy

Configure clipboard policies in config:

```bash
# Require confirmation for clipboard paste to vault
ALLOW_WORK_VAULT_CLIPBOARD="ask"
```

## Template Security

### Minimal Templates

Use minimal templates to reduce attack surface:

```bash
# Fedora minimal
DEFAULT_TEMPLATE="fedora-40-minimal"

# Debian minimal
DEFAULT_TEMPLATE="debian-12-minimal"
```

### Template Updates

Keep templates updated:

```bash
# Update all templates
make -f Makefile.qubes template-update

# Or manually
qvm-run -u root fedora-40-minimal 'dnf update -y'
```

### Package Installation

Only install necessary packages:

```bash
# Minimal set
WORK_PACKAGES="vim git curl wget"

# Avoid installing in template when possible
# Instead, install in qube itself for isolation
```

### Template Verification

```bash
# List installed packages
qvm-run -u root <template> 'rpm -qa'  # Fedora
qvm-run -u root <template> 'dpkg -l'  # Debian

# Check for suspicious packages
```

## Split-GPG Security

### Setup

```bash
ENABLE_SPLIT_GPG="true"
SPLIT_GPG_BACKEND="vault"
SPLIT_GPG_CLIENTS="work"
```

### Usage

```bash
# In work qube
export QUBES_GPG_DOMAIN=vault
qubes-gpg-client --list-keys

# Sign file (prompts in vault)
qubes-gpg-client --detach-sign document.txt

# Encrypt
qubes-gpg-client --encrypt --recipient user@example.com file.txt
```

### Security Notes

* GPG keys never leave vault
* Each operation requires user confirmation
* Keys protected even if work qube compromised

## Split-SSH Security

### Setup

```bash
ENABLE_SPLIT_SSH="true"
SPLIT_SSH_BACKEND="vault"
SPLIT_SSH_CLIENTS="work"
```

### Usage

```bash
# Generate key in vault
qvm-run vault 'ssh-keygen -t ed25519'

# In work qube
export SSH_AUTH_SOCK=~/.SSH_AGENT_vault
ssh user@example.com
```

### Security Notes

* SSH keys stored in air-gapped vault
* Agent forwarding via qrexec
* User confirmation required

## Qrexec Policies

### File Copy Policies

```bash
# /etc/qubes-rpc/policy/qubes.Filecopy
work vault allow
untrusted work ask
untrusted vault deny
anon vault deny
```

### Service Policies

```bash
# Allow only specific services
# /etc/qubes-rpc/policy/qubes.Gpg
work vault ask

# /etc/qubes-rpc/policy/qubes.SshAgent
work vault ask
```

### Policy Principles

1. **Default deny** - Block unless explicitly allowed
2. **Ask when unsure** - Require user confirmation
3. **Document policies** - Comment all rules
4. **Regular review** - Audit policies periodically

## Backup Security

### Encrypted Backups

```bash
# Configure encrypted backups
BACKUP_COMPRESSION="true"
BACKUP_PASSPHRASE_FILE="/path/to/secure/passphrase"
```

### Backup Location

```bash
# Store in secure location
BACKUP_DEST="dom0:/var/backups/qubes-sdp"

# Or external device (when attached to sys-usb)
BACKUP_DEST="sys-usb:/mnt/backup/qubes-sdp"
```

### Backup Verification

```bash
# Test restore
qvm-backup-restore --verify /path/to/backup

# List backup contents
qvm-backup-restore --list /path/to/backup
```

## Disposable VMs

### Using DisposableVMs

```bash
# Run application in disposable
qvm-run --dispvm untrusted firefox

# Open file in disposable
qvm-open-in-dvm suspicious-file.pdf
```

### DisposableVM Security

* Fresh VM for each use
* No persistent storage
* Destroyed after use
* Isolated from other qubes

## Monitoring and Auditing

### Log Review

```bash
# Check setup log
less /var/log/qubes-sdp-setup.log

# Check qrexec denials
journalctl -u qubes-qrexec-policy-daemon

# Check dom0 logs
journalctl -b
```

### Resource Monitoring

```bash
# Check qube resource usage
qvm-ls --fields name,state,memory,disk

# Monitor running processes
qvm-run work 'ps aux'
```

### Network Monitoring

```bash
# Check network connections in qube
qvm-run work 'netstat -tuln'

# Monitor traffic (from sys-firewall)
qvm-run sys-firewall 'tcpdump -i any host <work-ip>'
```

## Security Hardening

### Dom0 Hardening

```bash
# Disable unnecessary services in dom0
systemctl list-unit-files | grep enabled

# Review installed packages in dom0
rpm -qa | less
```

### Qube Hardening

```bash
# Disable unnecessary services
qvm-service work cups off
qvm-service work network-manager off

# Enable additional security features
qvm-features work service.qubes-firewall 1
```

### Template Hardening

```bash
# Remove unnecessary packages
qvm-run -u root <template> 'dnf remove <package>'

# Disable unnecessary services
qvm-run -u root <template> 'systemctl disable <service>'
```

## Threat Mitigation

### Malware

* **Prevention**: Untrusted qube for risky files
* **Detection**: Scan in untrusted before opening in work
* **Containment**: Disposable VMs prevent persistence

### Network Attacks

* **Prevention**: Firewall rules, minimal exposure
* **Detection**: Monitor logs for anomalies
* **Containment**: Qube isolation limits scope

### Physical Access

* **Prevention**: Full disk encryption
* **Detection**: Boot intrusion detection
* **Containment**: Vault air-gap protects sensitive data

### Side Channels

* **Prevention**: Separate qubes for different tasks
* **Detection**: Difficult, rely on isolation
* **Containment**: Air-gap for most sensitive data

## Incident Response

### Compromised Qube

```bash
# 1. Shutdown immediately
qvm-shutdown --force <compromised-qube>

# 2. Analyze (optional)
qvm-clone <compromised-qube> <analysis-qube>

# 3. Restore from backup or recreate
qvm-remove <compromised-qube>
./qubes-setup-advanced.sh

# 4. Review logs
less /var/log/qubes-sdp-setup.log
```

### Data Breach

1. Identify affected qubes
2. Shutdown affected qubes
3. Assess data exposure
4. Rotate credentials (split-GPG/SSH)
5. Recreate affected qubes

### System Intrusion

1. Disconnect from network
2. Review dom0 logs
3. Check for unauthorized changes
4. Consider full Qubes reinstall
5. Restore from known-good backup

## Security Checklist

### Daily

* [ ] Check qube states (nothing unexpected running)
* [ ] Review qrexec policy prompts
* [ ] Verify vault has no network

### Weekly

* [ ] Update templates
* [ ] Review logs for anomalies
* [ ] Test backups
* [ ] Check firewall rules

### Monthly

* [ ] Full security audit
* [ ] Review and update policies
* [ ] Test disaster recovery
* [ ] Update Qubes OS

### Quarterly

* [ ] Review threat model
* [ ] Update documentation
* [ ] Security training
* [ ] Penetration testing (if applicable)

## Best Practices

1. **Never trust untrusted** - Always use untrusted qube for risky files
2. **Verify vault isolation** - Regular checks for network access
3. **Update regularly** - Templates and Qubes OS
4. **Use disposables** - For one-time tasks
5. **Review policies** - Regularly audit qrexec policies
6. **Strong passphrases** - For backups and encryption
7. **Physical security** - Protect dom0 access
8. **Monitor logs** - Regular log review
9. **Test backups** - Verify restore capability
10. **Stay informed** - Follow Qubes security advisories

## References

* [Qubes OS Security](https://www.qubes-os.org/doc/security/)
* [Qubes Security Guidelines](https://www.qubes-os.org/doc/security-guidelines/)
* [Qubes Split-GPG](https://www.qubes-os.org/doc/split-gpg/)
* [Qubes Firewall](https://www.qubes-os.org/doc/firewall/)

## Next Steps

* **[Split-GPG Guide](split-gpg.html)** - Secure email signing
* **[Backup & Restore](backup-restore.html)** - Data protection
* **[Troubleshooting](troubleshooting.html)** - Common security issues
