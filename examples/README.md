# Example Configurations

Pre-configured examples for common use cases.

## Available Examples

### journalist-config.conf

Optimized for investigative journalism:
- work + vault + anon + untrusted qubes
- Split-GPG for encrypted communications
- Daily automated backups
- Strict firewall rules
- Anonymous qube via Tor

**Memory Required**: 8GB minimum

**Usage**:
```bash
cp examples/journalist-config.conf qubes-config.conf
./qubes-setup-advanced.sh
```

### developer-config.conf

Optimized for software development:
- work (4GB RAM) + vault + untrusted qubes
- Split-SSH for secure key management
- Development tools pre-installed
- Ports for SSH and Git
- Weekly backups

**Memory Required**: 12GB minimum

**Usage**:
```bash
cp examples/developer-config.conf qubes-config.conf
./qubes-setup-advanced.sh
```

### minimal-config.conf

For systems with limited RAM:
- work (1GB) + vault (512MB) only
- Minimal packages
- No optional qubes
- Reduced features

**Memory Required**: 4GB minimum

**Usage**:
```bash
cp examples/minimal-config.conf qubes-config.conf
./qubes-setup-advanced.sh
```

## Customizing Examples

1. Copy example to main config:
```bash
cp examples/journalist-config.conf qubes-config.conf
```

2. Edit as needed:
```bash
vi qubes-config.conf
```

3. Test with dry-run:
```bash
./qubes-setup-advanced.sh --dry-run
```

4. Apply:
```bash
./qubes-setup-advanced.sh
```

## Creating Your Own

Start with the closest example and modify:

1. Copy base example
2. Adjust memory allocations
3. Enable/disable qubes
4. Configure packages
5. Set firewall rules
6. Configure backups

See `qubes-config.conf` for all available options.

## Common Customizations

### Add More Memory

```bash
WORK_MEMORY="4096"
VAULT_MEMORY="2048"
```

### Enable VPN

```bash
ENABLE_VPN="true"
VPN_NAME="vpn"
VPN_NETVM="sys-firewall"
```

### Change Template

```bash
DEFAULT_TEMPLATE="debian-12-minimal"
```

### Add Packages

```bash
WORK_PACKAGES="vim git curl wget python3 nodejs docker"
```

### Custom Firewall

```bash
WORK_ALLOWED_PORTS="tcp:80,tcp:443,udp:53,tcp:22,tcp:8080"
```

## Testing Examples

Before applying, always test:

```bash
./qubes-setup-advanced.sh --dry-run --config examples/journalist-config.conf
```

## Support

For issues with examples:
1. Review configuration syntax
2. Check memory requirements
3. Verify template availability
4. See troubleshooting guide
