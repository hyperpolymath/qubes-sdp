# Backup & Restore Guide

Complete guide to backing up and restoring your Qubes SDP environment.

## Why Backup?

* **Data loss prevention** - Hardware failure, accidental deletion
* **Disaster recovery** - System corruption, ransomware
* **Migration** - Move to new hardware
* **Testing** - Restore known-good state
* **Compliance** - Data retention requirements

## What to Backup

### Critical (Must backup)

* **vault qube** - Contains sensitive data and keys
* **work qube** - Your daily files and configuration
* **Dom0 configuration** - Qube settings and policies

### Optional (Recommended)

* **Other qubes** - anon, untrusted (if customized)
* **Templates** - If customized (otherwise reinstall)

### Not Necessary

* **Disposable VMs** - By design, nothing persistent
* **Standard templates** - Can be reinstalled

## Backup Methods

### Method 1: Automatic via Qubes SDP

```bash
# Configure in qubes-config.conf
AUTO_BACKUP="true"
BACKUP_DEST="dom0:/var/backups/qubes-sdp"
BACKUP_SCHEDULE="0 2 * * *"  # Daily at 2 AM
BACKUP_QUBES="vault,work"
BACKUP_COMPRESSION="true"

# Run setup to enable
./qubes-setup-advanced.sh
```

### Method 2: Manual via Make

```bash
# One-time backup
make -f Makefile.qubes backup

# Set up automated backups
make -f Makefile.qubes backup-cron
```

### Method 3: Qubes Backup Tool (GUI)

1. Open Qubes Manager
2. Click "Backup"
3. Select qubes to backup
4. Choose destination
5. Set passphrase
6. Start backup

### Method 4: Command Line

```bash
# Backup specific qubes
qvm-backup work vault /var/backups/qubes-sdp/manual-backup

# Backup all qubes
qvm-backup --all /var/backups/qubes-sdp/full-backup
```

## Backup Configuration

### Backup Destination

**Local (dom0)**:
```bash
BACKUP_DEST="dom0:/var/backups/qubes-sdp"
```

**External USB** (via sys-usb):
```bash
BACKUP_DEST="sys-usb:/mnt/backup/qubes-sdp"
```

**Network share** (NOT recommended - security risk):
```bash
# Only if absolutely necessary
BACKUP_DEST="backup-qube:/mnt/nas/qubes-sdp"
```

### Backup Schedule (Cron)

```bash
# Daily at 2 AM
BACKUP_SCHEDULE="0 2 * * *"

# Every Sunday at 3 AM
BACKUP_SCHEDULE="0 3 * * 0"

# Every 6 hours
BACKUP_SCHEDULE="0 */6 * * *"
```

**Cron format**: minute hour day month weekday

### Compression

```bash
# Enable compression (smaller, slower)
BACKUP_COMPRESSION="true"

# Disable compression (larger, faster)
BACKUP_COMPRESSION="false"
```

Typical compression: 40-60% size reduction

### Encryption

**Always encrypt backups!**

```bash
# Via passphrase file
BACKUP_PASSPHRASE_FILE="/path/to/passphrase"

# Via prompt (manual backup)
qvm-backup --passphrase-file - work vault /backup/location
# Enter passphrase when prompted
```

**Passphrase best practices**:
* Use 20+ characters
* Mix letters, numbers, symbols
* Store securely (password manager in vault)
* Don't reuse for other purposes

## Backup Process

### Step-by-Step Manual Backup

```bash
# 1. Ensure qubes are running (or shutdown, both work)
qvm-start vault
qvm-start work

# 2. Create backup directory
mkdir -p /var/backups/qubes-sdp

# 3. Run backup
qvm-backup work vault /var/backups/qubes-sdp/backup-$(date +%Y%m%d)

# 4. Enter passphrase when prompted

# 5. Wait for completion
# Shows progress for each qube

# 6. Verify backup created
ls -lh /var/backups/qubes-sdp/
```

### Automated Backup Workflow

Once configured:

1. Cron triggers backup at scheduled time
2. Qubes are backed up automatically
3. Backup saved to configured location
4. Log entry created
5. Email notification (if configured)

### Incremental Backups

Qubes backups are full backups by default. For incremental:

```bash
# Use rsync to backup qube data
qvm-run vault 'tar -czf - /home/user' | \
    cat > /var/backups/vault-data-$(date +%Y%m%d).tar.gz
```

## Backup Verification

### List Backup Contents

```bash
qvm-backup-restore --list /var/backups/qubes-sdp/backup-20240101
```

### Verify Backup Integrity

```bash
qvm-backup-restore --verify /var/backups/qubes-sdp/backup-20240101
```

### Test Restore (Dry Run)

```bash
qvm-backup-restore --dry-run /var/backups/qubes-sdp/backup-20240101
```

## Restore Process

### Full Restore

```bash
# 1. Boot Qubes OS
# 2. Open dom0 terminal
# 3. List backup contents
qvm-backup-restore --list /var/backups/qubes-sdp/backup-20240101

# 4. Restore all qubes
qvm-backup-restore /var/backups/qubes-sdp/backup-20240101

# 5. Enter passphrase

# 6. Confirm qube restoration
# Shows each qube being restored

# 7. Start restored qubes
qvm-start vault
qvm-start work
```

### Selective Restore

```bash
# Restore only specific qubes
qvm-backup-restore --include vault /var/backups/qubes-sdp/backup-20240101

# Exclude certain qubes
qvm-backup-restore --exclude untrusted /var/backups/qubes-sdp/backup-20240101
```

### Restore to Different Name

```bash
# Restore vault as vault-old
qvm-backup-restore --rename vault:vault-old /var/backups/qubes-sdp/backup-20240101
```

### Restore from USB

```bash
# 1. Attach USB to sys-usb
# 2. Mount in dom0
qvm-block attach dom0 sys-usb:sda1
mount /dev/xvdi /mnt/usb

# 3. Restore
qvm-backup-restore /mnt/usb/qubes-sdp/backup-20240101

# 4. Unmount
umount /mnt/usb
qvm-block detach dom0 sys-usb:sda1
```

## Backup Storage

### Local Storage

**Pros**:
* Fast
* Always available
* No network dependency

**Cons**:
* Lost if hardware fails
* Not protected from physical damage/theft

**Best for**: Daily/frequent backups

### External USB

**Pros**:
* Offline storage
* Portable
* Protected from system failures

**Cons**:
* Requires manual connection
* Can be lost/stolen
* Limited by USB capacity

**Best for**: Weekly/monthly backups, archival

### Remote Storage

**Pros**:
* Offsite protection
* Large capacity
* Accessible from anywhere

**Cons**:
* Security risk (network exposure)
* Requires trust in provider
* Slower transfer

**Best for**: Long-term archival (if properly encrypted)

**Security**: Use encrypted cloud storage (Tresorit, SpiderOak) or encrypt locally first.

## Backup Strategy

### 3-2-1 Rule

* **3** copies of data (original + 2 backups)
* **2** different media types (disk + USB)
* **1** offsite copy (cloud/other location)

### Recommended Schedule

**Daily**:
* Automated backup to local disk
* Vault and work qubes only

**Weekly**:
* Manual backup to USB drive
* All customized qubes

**Monthly**:
* Full system backup
* Store USB offsite

**Before major changes**:
* Manual backup
* Test restore

### Retention Policy

```bash
# Keep daily backups for 7 days
find /var/backups/qubes-sdp -name "backup-*" -mtime +7 -delete

# Keep weekly backups for 30 days
# Keep monthly backups for 365 days
```

## Disaster Recovery

### Scenario 1: Single Qube Corruption

```bash
# 1. Identify corrupted qube
qvm-ls | grep work

# 2. Shutdown corrupted qube
qvm-shutdown --force work

# 3. Remove corrupted qube
qvm-remove work

# 4. Restore from backup
qvm-backup-restore --include work /var/backups/qubes-sdp/backup-latest

# 5. Verify restoration
qvm-start work
```

### Scenario 2: Multiple Qubes Lost

```bash
# 1. Determine extent of damage
qvm-ls

# 2. Restore all affected qubes
qvm-backup-restore --include vault,work,anon /var/backups/qubes-sdp/backup-latest

# 3. Verify each qube
qvm-start vault
qvm-start work
```

### Scenario 3: Complete System Failure

```bash
# 1. Reinstall Qubes OS
# 2. Boot to dom0
# 3. Copy backup from USB/network
# 4. Restore all qubes
qvm-backup-restore /path/to/backup

# 5. Recreate any non-backed-up qubes
./qubes-setup-advanced.sh

# 6. Verify all systems
```

### Scenario 4: Ransomware

```bash
# 1. Immediately disconnect network
qvm-shutdown --all

# 2. Assess damage (which qubes encrypted)
# 3. Remove affected qubes
qvm-remove <infected-qube>

# 4. Restore from LAST KNOWN GOOD backup
# (not most recent, might be encrypted too)
qvm-backup-restore /var/backups/qubes-sdp/backup-<date-before-infection>

# 5. Audit all qubes for infection
# 6. Update all templates
```

## Backup Best Practices

1. **Test restores regularly** - Verify backups actually work
2. **Encrypt everything** - Never store unencrypted backups
3. **Strong passphrases** - 20+ characters
4. **Multiple copies** - Local + USB + offsite
5. **Automated backups** - Don't rely on manual process
6. **Document procedure** - Keep recovery instructions
7. **Verify integrity** - Check backups aren't corrupted
8. **Offsite storage** - Protect from physical disasters
9. **Versioning** - Keep multiple backup generations
10. **Secure passphrase storage** - Use password manager in vault

## Troubleshooting

### Backup Fails

**Insufficient disk space**:
```bash
df -h /var/backups
# Free up space or use different destination
```

**Qube not running**:
```bash
qvm-start <qube>
# Or backup will start it automatically
```

**Permission denied**:
```bash
# Check backup destination permissions
ls -ld /var/backups/qubes-sdp
sudo chown user:user /var/backups/qubes-sdp
```

### Restore Fails

**Wrong passphrase**:
* Double-check passphrase
* Try backup from different date
* Check caps lock

**Corrupted backup**:
```bash
# Verify integrity
qvm-backup-restore --verify /path/to/backup

# Try older backup if corrupted
```

**Qube already exists**:
```bash
# Remove existing qube first
qvm-remove <qube>

# Or restore with different name
qvm-backup-restore --rename work:work-restored /path/to/backup
```

## Advanced Topics

### Backup Compression Levels

```bash
# Maximum compression (slow, small)
qvm-backup --compress-level=9 work /backup/location

# Fast compression (faster, larger)
qvm-backup --compress-level=1 work /backup/location
```

### Selective File Backup

```bash
# Backup only specific directories
qvm-run vault 'tar -czf - /home/user/Documents' > vault-docs-backup.tar.gz

# Restore
cat vault-docs-backup.tar.gz | qvm-run vault 'tar -xzf - -C /'
```

### Scripted Backups

```bash
#!/bin/bash
# custom-backup.sh

DATE=$(date +%Y%m%d)
DEST="/var/backups/qubes-sdp/backup-${DATE}"

# Backup critical qubes
qvm-backup --passphrase-file /etc/qubes-backup-passphrase \
    work vault "${DEST}"

# Remove old backups (keep 7 days)
find /var/backups/qubes-sdp -name "backup-*" -mtime +7 -delete

# Log result
echo "Backup completed: ${DEST}" >> /var/log/qubes-backup.log
```

### Cloud Backup (Encrypted)

```bash
# 1. Create encrypted backup locally
qvm-backup work vault /tmp/backup-encrypted

# 2. Upload via dedicated backup qube
qvm-run backup-qube 'rclone copy /tmp/backup-encrypted remote:qubes-backups/'

# 3. Clean up local copy
rm -rf /tmp/backup-encrypted
```

## Backup Checklist

### Daily

* [ ] Automated backup ran successfully
* [ ] Check log for errors
* [ ] Verify disk space available

### Weekly

* [ ] Manual backup to USB
* [ ] Test restore of one qube
* [ ] Verify backup integrity
* [ ] Update passphrase rotation

### Monthly

* [ ] Full system backup
* [ ] Test complete restore procedure
* [ ] Store backup offsite
* [ ] Review and update backup strategy
* [ ] Clean up old backups

### Annually

* [ ] Full disaster recovery test
* [ ] Review and update documentation
* [ ] Audit backup security
* [ ] Update backup passphrases

## Tools and Utilities

```bash
# Backup validator
make -f Makefile.qubes backup-validator

# Backup status dashboard
bash tools/qubes-backup-monitor.sh

# Automated testing
bash tests/backup-restore-test.sh
```

## References

* [Qubes Backup Documentation](https://www.qubes-os.org/doc/backup-restore/)
* [Qubes Emergency Backup Recovery](https://www.qubes-os.org/doc/backup-emergency-restore/)
* [Dom0 Backup](https://www.qubes-os.org/doc/backup-dom0/)

## Next Steps

* **[Security Guide](security-guide.html)** - Protect your backups
* **[Configuration](configuration.html)** - Set up automated backups
* **[Troubleshooting](troubleshooting.html)** - Backup issues
