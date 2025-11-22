# Qubes SDP - Software Development Platform

[![License: MIT + Palimpsest](https://img.shields.io/badge/license-MIT%20%2B%20Palimpsest%20v0.8-blue.svg)](LICENSE)
[![Qubes OS](https://img.shields.io/badge/Qubes%20OS-4.1%2B-blue.svg)](https://www.qubes-os.org/)
[![RSR Compliance](https://img.shields.io/badge/RSR-Gold-gold.svg)](scripts/rsr-verify.sh)
[![TPCF](https://img.shields.io/badge/TPCF-Perimeter%203-green.svg)](CODE_OF_CONDUCT.md)
[![Nix](https://img.shields.io/badge/Nix-Flake-blue.svg)](flake.nix)

Automated Qubes OS configuration system for secure, isolated work environments. Deploy a complete qube topology with one command.

**TPCF Perimeter 3 (Community Sandbox)** - Open contribution, community governance, no corporate control.

## Overview

Qubes SDP automates the creation and configuration of a secure Qubes OS environment optimized for:

- **Investigative Journalism** - Source protection and secure communications
- **Software Development** - Isolated development with secure key management
- **Research** - Data collection and analysis with privacy
- **Teaching** - Safe handling of student materials
- **Security Testing** - Isolated penetration testing environments

## Features

### 🚀 One-Command Setup

```bash
./qubes-setup.sh
# Creates work, vault, anon, and untrusted qubes in seconds
```

### 🔒 Security-Focused

- **Air-gapped vault** for sensitive data (NO network)
- **Restrictive firewalls** (default deny, explicit allow)
- **Disposable VMs** for risky content
- **Split-GPG/SSH** for key isolation
- **Minimal templates** to reduce attack surface

### 🎯 Multiple Deployment Methods

1. **Simple Script** - Standalone bash script, no configuration needed
2. **Advanced Script** - Full customization via config file
3. **Salt Stack** - Declarative infrastructure as code
4. **Interactive Wizard** - Guided setup process

### 📋 Topology Presets

Pre-configured for common workflows:

- **journalist** - Work + vault + anon + untrusted, split-GPG
- **developer** - Work + vault + untrusted, split-SSH, dev tools
- **researcher** - All qubes + VPN
- **teacher** - Work + vault + untrusted + USB
- **pentester** - All qubes, high memory, security tools

### 🛠️ Comprehensive Tools

- **Status Dashboard** - Real-time monitoring
- **Firewall Analyzer** - Security assessment
- **Template Manager** - Update and maintain templates
- **Backup Validator** - Verify backup integrity
- **Policy Generator** - Create qrexec policies
- **Recovery Tool** - Disaster recovery wizard

### 📚 Extensive Documentation

- Comprehensive wiki with guides and tutorials
- Troubleshooting for common issues
- Security best practices
- API reference
- Example configurations

### 🏆 RSR Framework Compliance

This project adheres to the [Rhodium Standard Repository](https://github.com/hyperpolymath/rhodium-standard-repository) framework:

- ✅ **Comprehensive Documentation** - README, QUICKSTART, Wiki, CONTRIBUTING, SECURITY
- ✅ **Governance** - CODE_OF_CONDUCT, MAINTAINERS, TPCF Perimeter 3
- ✅ **Build Systems** - justfile, Makefile, Nix flake, CI/CD
- ✅ **Security** - RFC 9116 security.txt, vulnerability disclosure, automated tests
- ✅ **Emotional Safety** - Palimpsest license, reversibility, learning culture
- ✅ **Offline-First** - Air-gapped operation capability
- ✅ **Reproducibility** - Nix flake for deterministic builds
- ✅ **.well-known/** - security.txt, ai.txt, humans.txt

**Verify compliance**: `bash scripts/rsr-verify.sh`

## Quick Start

### Prerequisites

- Qubes OS 4.1 or later
- 8GB RAM minimum (16GB recommended)
- 50GB free disk space

### Installation

1. **Download in a qube** (NOT dom0):
```bash
git clone https://github.com/yourusername/qubes-sdp.git
cd qubes-sdp
```

2. **Transfer to dom0**:
```bash
# In dom0:
qvm-run --pass-io <qube-name> 'cat /path/to/qubes-sdp/qubes-setup.sh' > qubes-setup.sh
chmod +x qubes-setup.sh
```

3. **Run setup**:
```bash
./qubes-setup.sh
```

See [QUICKSTART.md](QUICKSTART.md) for detailed instructions.

## Usage

### Simple Setup

```bash
# Create basic topology (work, vault, anon, untrusted)
./qubes-setup.sh

# Dry-run to see what will be created
./qubes-setup.sh --dry-run

# Validate existing setup
./qubes-setup.sh --validate
```

### Advanced Setup

```bash
# Use configuration file
cp examples/journalist-config.conf qubes-config.conf
vi qubes-config.conf
./qubes-setup-advanced.sh

# Interactive wizard
./qubes-setup-advanced.sh --interactive

# Use specific preset
make -f Makefile.qubes setup-preset-journalist
```

### Using Make

```bash
# Run setup
make -f Makefile.qubes setup

# Show status
make -f Makefile.qubes status

# Create backup
make -f Makefile.qubes backup

# Update templates
make -f Makefile.qubes template-update

# Health check
make -f Makefile.qubes health-check
```

### Salt Stack

```bash
# Copy to Salt directory
sudo cp -r qubes-salt/*.sls /srv/salt/

# Apply states
sudo qubesctl state.apply qubes-sdp
```

## Architecture

```
┌─────────────┐
│    work     │  General work environment
│  (green)    │  • 2GB RAM
│  network    │  • Firewall: HTTP/HTTPS/DNS only
└─────────────┘  • Template: fedora-40-minimal

┌─────────────┐
│    vault    │  Sensitive data storage
│  (black)    │  • 1GB RAM
│ AIR-GAPPED  │  • NO NETWORK (critical!)
└─────────────┘  • Split-GPG/SSH backend

┌─────────────┐
│    anon     │  Anonymous communications
│  (purple)   │  • 1GB RAM
│  Tor/Whonix │  • Routes through sys-whonix
└─────────────┘  • Anonymous research

┌─────────────┐
│  untrusted  │  Risky content handler
│   (red)     │  • 1GB RAM
│  DispVM     │  • Disposable VMs
└─────────────┘  • Risky downloads/files
```

## Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Get started in 5 minutes
- **[Wiki](wiki/)** - Comprehensive documentation
  - [Getting Started](wiki/pages/getting-started.md)
  - [Installation Guide](wiki/pages/installation.md)
  - [Configuration Guide](wiki/pages/configuration.md)
  - [Security Guide](wiki/pages/security-guide.md)
  - [Troubleshooting](wiki/pages/troubleshooting.md)
  - [FAQ](wiki/pages/faq.md)
- **[Tools README](tools/README.md)** - Utility tool documentation
- **[Examples](examples/)** - Example configurations

## What Gets Created

### Qubes

- **work** - Daily work environment with restricted network
- **vault** - Air-gapped storage for sensitive data
- **anon** - Anonymous communications via Tor
- **untrusted** - Disposable environment for risky content

### Optional Qubes

- **vpn** - VPN proxy qube
- **sys-usb** - USB device management

### Configurations

- Firewall rules (default deny + explicit allow)
- Qrexec policies (file copy, clipboard, GPG, SSH)
- Split-GPG setup (keys in vault, use from work)
- Split-SSH setup (SSH keys in vault)
- Automated backups (configurable schedule)

## Security Features

- ✅ Air-gapped vault (absolutely no network)
- ✅ Default-deny firewall rules
- ✅ Minimal templates (reduced attack surface)
- ✅ DisposableVMs for untrusted content
- ✅ Split-GPG/SSH (keys never leave vault)
- ✅ Qrexec policy enforcement
- ✅ Encrypted backups
- ✅ Comprehensive logging
- ✅ Validation and health checks

## Requirements

### Minimum

- Qubes OS 4.1+
- 8GB RAM
- 50GB disk space

### Recommended

- Qubes OS 4.2
- 16GB+ RAM
- 100GB+ disk space
- SSD for better performance

### Templates

By default uses `fedora-40-minimal`. Supports:
- fedora-40-minimal
- fedora-39-minimal
- debian-12-minimal
- debian-11-minimal

Auto-installs missing templates if configured.

## Contributing

**This is a TPCF Perimeter 3 (Community Sandbox) project** - all contributions welcome!

We value:
- 🤝 **Open contribution** - Everyone can participate
- 🧪 **Experimentation** - Mistakes are learning opportunities
- 🔄 **Reversibility** - All changes can be undone
- 💚 **Emotional safety** - No shaming or gatekeeping

**Get started:**
1. Read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) - Our community standards
2. Read [CONTRIBUTING.md](CONTRIBUTING.md) - How to contribute
3. Check [MAINTAINERS.md](MAINTAINERS.md) - Governance model
4. Fork, create a feature branch, test thoroughly, submit PR

**New contributors**: We're beginner-friendly! Ask questions, experiment safely with dry-run modes, and learn as you go.

## Support

- **Documentation**: Check the [Wiki](wiki/)
- **Issues**: Report bugs via [GitHub Issues](https://github.com/yourusername/qubes-sdp/issues)
- **Questions**: See [FAQ](wiki/pages/faq.md)
- **Qubes OS**: Visit [Qubes Documentation](https://www.qubes-os.org/doc/)

## Testing

```bash
# Run all tests
make -f Makefile.qubes test

# Run specific tests
bash tests/unit-tests.sh
bash tests/integration-tests.sh
bash tests/security-tests.sh
```

## Roadmap

- [ ] Web-based configuration UI
- [ ] Additional topology presets
- [ ] Automated security auditing
- [ ] Performance optimization
- [ ] Multi-language support
- [ ] Video tutorials

## License

**Dual Licensed**: Choose either license at your option:

1. **MIT License** - For maximum compatibility and permissive use
2. **Palimpsest License v0.8** - MIT + emotional safety guarantees

The Palimpsest license extends MIT with principles of:
- **Reversibility** - All changes easily undoable
- **Psychological safety** - No shame, blame, or weaponizing errors
- **Learning culture** - Experimentation encouraged
- **Transparent costs** - Clear consequences before actions
- **Inclusive design** - Accommodates diverse backgrounds and abilities

See [LICENSE](LICENSE) for full text and details.

**Why dual license?** Use MIT if you only need a permissive open source license. Choose Palimpsest if you want emotional safety guarantees for contributors and users.

## Disclaimer

This software is provided "as is" without warranty. Always review scripts before running in dom0. Test in a safe environment first.

## Acknowledgments

- Qubes OS team for the excellent security platform
- Community contributors
- Security researchers and testers

## Related Projects

- [Qubes OS](https://www.qubes-os.org/) - Security-focused operating system
- [Whonix](https://www.whonix.org/) - Anonymous operating system
- [Split-GPG](https://www.qubes-os.org/doc/split-gpg/) - Qubes GPG isolation

## Author

Created and maintained by the Qubes SDP community.

---

**⚠️ Important**: Never run untrusted scripts in dom0. Review all code before execution. Use dry-run mode to test before applying changes.

**🔐 Security**: Report vulnerabilities privately via [GitHub Security Advisories](https://github.com/hyperpolymath/qubes-sdp/security/advisories) or email security@qubes-sdp.org - See [SECURITY.md](SECURITY.md) and [.well-known/security.txt](.well-known/security.txt)

**📧 Contact**:
- General questions: contribute@qubes-sdp.org
- Code of Conduct: conduct@qubes-sdp.org
- Security: security@qubes-sdp.org

**🌐 Community**:
- Governance: [MAINTAINERS.md](MAINTAINERS.md)
- Code of Conduct: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- Contributing: [CONTRIBUTING.md](CONTRIBUTING.md)
