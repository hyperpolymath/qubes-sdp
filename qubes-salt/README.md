# Qubes SDP Salt Stack Configuration

This directory contains Salt Stack state files for automated Qubes OS setup.

## Files

- **qubes-sdp.sls** - Main Salt state file defining the qube topology
- **top.sls** - Top file that maps states to systems
- **README.md** - This file

## Usage

### Method 1: Apply States Directly

```bash
# In dom0, apply the SDP states
sudo qubesctl state.apply qubes-sdp
```

### Method 2: Copy to Salt Directory

```bash
# Copy state files to Qubes Salt directory
sudo cp qubes-salt/*.sls /srv/salt/

# Apply the states
sudo qubesctl state.apply qubes-sdp
```

### Method 3: Use Salt File Server

```bash
# Copy to user salt directory
mkdir -p /srv/salt/user
sudo cp qubes-salt/*.sls /srv/salt/user/

# Apply from user states
sudo qubesctl state.apply user.qubes-sdp
```

## Verification

After applying, verify the setup:

```bash
# List all VMs
qvm-ls

# Check specific qube properties
qvm-prefs work
qvm-prefs vault

# Check firewall rules
qvm-firewall work list
```

## Customization

Edit `qubes-sdp.sls` to customize:

- Memory allocations
- Network settings
- Firewall rules
- Package installations
- Labels and colors

## Advanced Usage

### Dry Run (Test Mode)

```bash
# Test what would be applied without making changes
sudo qubesctl state.apply qubes-sdp test=True
```

### Highstate

To apply all configured states:

```bash
sudo qubesctl state.highstate
```

### Target Specific Qubes

```bash
# Apply only work qube configuration
sudo qubesctl state.sls qubes-sdp.work
```

## Troubleshooting

### Check Salt Syntax

```bash
# Validate state file syntax
sudo qubesctl state.show_sls qubes-sdp
```

### View State Tree

```bash
# See all available states
sudo qubesctl state.show_top
```

### Debug Mode

```bash
# Run with debug output
sudo qubesctl state.apply qubes-sdp -l debug
```

## Integration with Scripts

Salt Stack provides declarative configuration, while the bash scripts offer
imperative control. Choose based on your needs:

- **Salt Stack**: Best for maintaining consistent state across systems
- **Bash Scripts**: Best for one-time setup or interactive configuration

Both methods can coexist and complement each other.

## Notes

- Salt states are idempotent - safe to run multiple times
- Changes are only made if the desired state differs from current state
- Always test with `test=True` first in production environments
- Salt runs in dom0 and has full system access

## References

- [Qubes Salt Documentation](https://www.qubes-os.org/doc/salt/)
- [Salt States Reference](https://docs.saltproject.io/en/latest/ref/states/all/)
- [Qubes Salt Examples](https://github.com/QubesOS/qubes-mgmt-salt-dom0-virtual-machines)
