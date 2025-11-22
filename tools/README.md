# Qubes SDP Tools

Comprehensive utility tools for managing and monitoring Qubes SDP.

## Available Tools

### Status and Monitoring

#### qubes-status.sh
Complete status overview of all SDP qubes.

```bash
./qubes-status.sh
```

Shows:
- Qube state (running/halted)
- Memory allocation
- Network configuration
- Disk usage
- Security checks
- System resources

#### qubes-dashboard.sh
Interactive real-time dashboard with auto-refresh.

```bash
./qubes-dashboard.sh
```

Features:
- Live system resource monitoring
- Qube status with visual indicators
- Security status checks
- Recent activity log
- Interactive commands

### Firewall Management

#### qubes-firewall-analyzer.sh
Analyzes firewall rules across all SDP qubes.

```bash
./qubes-firewall-analyzer.sh
```

Provides:
- Rule visualization
- Security level assessment
- Recommendations
- Rule management commands

### Template Management

#### qubes-template-manager.sh
Manages templates used by SDP qubes.

```bash
# Show template status
./qubes-template-manager.sh status

# Update all templates
./qubes-template-manager.sh update

# Install missing templates
./qubes-template-manager.sh install

# Clean package cache
./qubes-template-manager.sh clean

# Detailed information
./qubes-template-manager.sh info
```

### Backup and Recovery

#### qubes-backup-validator.sh
Validates and manages backups.

```bash
# Default location
./qubes-backup-validator.sh

# Specific directory
./qubes-backup-validator.sh /path/to/backups
```

Shows:
- Backup inventory
- Integrity verification
- Age analysis
- Cleanup recommendations

#### qubes-restore.sh
Guided disaster recovery and restore.

```bash
./qubes-restore.sh /path/to/backup
```

Features:
- Backup verification
- Conflict detection
- Rename/replace/skip options
- Post-restore validation
- Recovery recommendations

### Policy Management

#### qubes-policy-generator.sh
Generates and manages qrexec policies.

```bash
# Show current policies
./qubes-policy-generator.sh show

# Generate recommended policies
./qubes-policy-generator.sh generate

# Apply policies
./qubes-policy-generator.sh apply

# Backup policies
./qubes-policy-generator.sh backup
```

## Usage Examples

### Daily Monitoring

```bash
# Quick status check
./qubes-status.sh

# Start dashboard for continuous monitoring
./qubes-dashboard.sh
```

### Weekly Maintenance

```bash
# Update templates
./qubes-template-manager.sh update

# Check firewall rules
./qubes-firewall-analyzer.sh

# Verify backups
./qubes-backup-validator.sh

# Clean template cache
./qubes-template-manager.sh clean
```

### After Setup

```bash
# Verify configuration
./qubes-status.sh

# Analyze firewall rules
./qubes-firewall-analyzer.sh

# Generate policies
./qubes-policy-generator.sh generate
./qubes-policy-generator.sh apply
```

### Disaster Recovery

```bash
# Verify backup exists
./qubes-backup-validator.sh

# Restore from backup
./qubes-restore.sh /var/backups/qubes-sdp/backup-20240101
```

## Integration with Makefile

All tools are integrated with Makefile.qubes:

```bash
# Status
make -f Makefile.qubes status

# Dashboard
make -f Makefile.qubes dashboard

# Firewall check
make -f Makefile.qubes firewall-check

# Template update
make -f Makefile.qubes template-update

# Backup validation
# (included in backup command)
```

## Tool Dependencies

All tools require:
- Running in dom0
- Qubes OS 4.1+
- Standard Qubes commands (qvm-*, xl)

Optional dependencies:
- python3 (for dashboard)
- specific qubes for their respective checks

## Output Formats

All tools use color-coded output:
- **Green (✓)**: Success, secure, optimal
- **Yellow (!)**: Warning, attention needed
- **Red (✗)**: Error, insecure, critical
- **Blue**: Informational
- **Cyan**: Headers

## Automation

### Cron Integration

```bash
# Daily status check (email on changes)
0 8 * * * /path/to/qubes-status.sh | mail -s "Qubes SDP Status" admin@example.com

# Weekly backup validation
0 9 * * 0 /path/to/qubes-backup-validator.sh

# Monthly template updates
0 2 1 * * /path/to/qubes-template-manager.sh update
```

### Systemd Timers

```ini
# /etc/systemd/system/qubes-status.timer
[Unit]
Description=Qubes SDP Status Check

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

## Troubleshooting

### Permission Denied

Ensure scripts are executable:
```bash
chmod +x tools/*.sh
```

### Command Not Found

Run from dom0, not an AppVM:
```bash
hostname  # Should output: dom0
```

### Missing Qubes

Tools gracefully handle missing qubes, showing "not created" status.

## Development

### Adding New Tools

1. Create script in tools/ directory
2. Make executable: `chmod +x tools/new-tool.sh`
3. Add to Makefile.qubes if appropriate
4. Update this README
5. Add help text with `-h` flag

### Testing Tools

All tools support dry-run or read-only modes by default. They won't make changes unless explicitly requested.

## Security Considerations

- All tools run in dom0 (full system access)
- Review scripts before running
- Backup policies before applying changes
- Test in dry-run mode when available

## Contributing

Improvements welcome:
- Bug fixes
- New features
- Better visualizations
- Performance improvements
- Documentation updates

## References

- [Qubes OS Documentation](https://www.qubes-os.org/doc/)
- [Qrexec Policy](https://www.qubes-os.org/doc/qrexec/)
- [Qubes Backup](https://www.qubes-os.org/doc/backup-restore/)
