# Getting Started with Qubes SDP

Welcome to the Qubes Software Development Platform! This guide will help you get started with automated qube setup and management.

## What is Qubes SDP?

Qubes SDP is an automated configuration system for Qubes OS that creates secure, isolated work environments with minimal effort. It provides:

* **One-command setup** - Deploy your entire qube topology instantly
* **Security-focused** - Implements Qubes best practices by default
* **Flexible configuration** - Choose from presets or customize everything
* **Multiple deployment methods** - Bash scripts or Salt Stack

## Quick Start

### Method 1: Simple Setup (Recommended for beginners)

```bash
# Copy the script to dom0 (from a qube)
qvm-run --pass-io <source-qube> 'cat /path/to/qubes-setup.sh' > qubes-setup.sh

# Make it executable
chmod +x qubes-setup.sh

# Run the setup
./qubes-setup.sh
```

This creates four qubes:
* **work** - General work environment (2GB RAM, firewall-restricted)
* **vault** - Air-gapped sensitive data storage (NO NETWORK)
* **anon** - Anonymous communications via Tor
* **untrusted** - Disposable environment for risky activities

### Method 2: Advanced Setup (Full customization)

```bash
# Copy both the script and config file to dom0
qvm-run --pass-io <source-qube> 'cat /path/to/qubes-setup-advanced.sh' > qubes-setup-advanced.sh
qvm-run --pass-io <source-qube> 'cat /path/to/qubes-config.conf' > qubes-config.conf

# Make executable
chmod +x qubes-setup-advanced.sh

# Edit configuration
vi qubes-config.conf

# Run setup
./qubes-setup-advanced.sh
```

### Method 3: Using Make

```bash
# Copy entire repository to dom0
qvm-run --pass-io <source-qube> 'tar -C /path/to/qubes-sdp -c .' | tar -x

# Run setup
make -f Makefile.qubes setup

# Or use a preset
make -f Makefile.qubes setup-preset-journalist
```

## Topology Presets

Choose a preset based on your use case:

### Journalist
* work + vault + anon + untrusted qubes
* Split-GPG enabled for secure communications
* File transfer policies configured
* Emphasis on anonymity and source protection

### Developer
* work (4GB RAM) + vault + untrusted qubes
* Split-SSH enabled for secure key management
* Additional development tools installed
* Emphasis on code security

### Researcher
* work + vault + anon + untrusted + VPN qubes
* VPN qube for institutional access
* Tools for secure data collection
* Emphasis on data protection

### Teacher
* work + vault + untrusted + USB qubes
* USB qube for device management
* Emphasis on usability

### Pentester
* All qubes enabled
* 4GB RAM for work qube
* Split-GPG and split-SSH
* Security testing tools
* Emphasis on isolation

## Verifying Your Setup

After installation, verify your qubes:

```bash
# List all qubes
qvm-ls

# Check specific qube properties
qvm-prefs work
qvm-prefs vault

# Verify firewall rules
qvm-firewall work list

# Run health check
./qubes-setup-advanced.sh --health-check
```

## Next Steps

1. **[Configuration](configuration.html)** - Customize your setup
2. **[Security Guide](security-guide.html)** - Best practices
3. **[Split-GPG](split-gpg.html)** - Secure email and signing
4. **[Backup & Restore](backup-restore.html)** - Protect your data

## Common First Tasks

### Start a qube
```bash
qvm-start work
```

### Copy files to vault
```bash
# From work qube, right-click file and select "Copy to vault"
# Or use command line:
qvm-copy-to-vm vault /path/to/file
```

### Create a disposable VM
```bash
qvm-run --dispvm untrusted firefox
```

### Check system status
```bash
make -f Makefile.qubes status
```

## Getting Help

* **[FAQ](faq.html)** - Frequently asked questions
* **[Troubleshooting](troubleshooting.html)** - Common issues
* **[Qubes OS Documentation](https://www.qubes-os.org/doc/)** - Official docs

## Understanding the Architecture

Qubes SDP creates a secure topology based on domain isolation:

* **work**: Your daily driver with controlled internet access
* **vault**: Air-gapped storage, no network access ever
* **anon**: Routes through Tor for anonymous communications
* **untrusted**: Disposable, assume everything is malicious

Each qube runs on a minimal template to reduce attack surface.

## Safety Features

* **Dry-run mode** - Test before applying changes
* **Rollback system** - Undo failed setups automatically
* **Validation checks** - Verify setup integrity
* **Health monitoring** - Track qube status
* **Comprehensive logging** - Audit all actions

Ready to dive deeper? Check out the **[Configuration Guide](configuration.html)**!
