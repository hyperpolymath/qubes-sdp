# Topology Presets

Pre-configured qube topologies optimized for specific use cases.

## Overview

Topology presets provide instant setup for common security scenarios. Each preset creates a specific combination of qubes with appropriate settings, policies, and tools.

## Using Presets

### Via Configuration File

```bash
# Edit qubes-config.conf
TOPOLOGY_PRESET="journalist"  # Or developer, researcher, etc.

# Run setup
./qubes-setup-advanced.sh
```

### Via Make

```bash
make -f Makefile.qubes setup-preset-journalist
make -f Makefile.qubes setup-preset-developer
make -f Makefile.qubes setup-preset-researcher
make -f Makefile.qubes setup-preset-teacher
make -f Makefile.qubes setup-preset-pentester
```

### Via Interactive Mode

```bash
./qubes-setup-advanced.sh --interactive
# Select preset when prompted
```

## Available Presets

### Journalist

**Purpose**: Investigative journalism, source protection, secure communications

**Qubes Created**:
* **work** - Research and writing (2GB RAM)
* **vault** - Air-gapped source materials and keys
* **anon** - Anonymous communications via Tor
* **untrusted** - Disposable for risky links/files

**Security Features**:
* Split-GPG enabled (keys in vault)
* File transfer policies (work → vault allowed)
* Clipboard policies (ask for paste)
* Strict firewall rules

**Use Cases**:
* Encrypted communication with sources
* Secure document storage
* Anonymous research
* Risky file handling

**Example Workflow**:
1. Research in **work** qube
2. Receive encrypted files, decrypt via split-GPG in **vault**
3. Use **anon** for anonymous communications
4. Open suspicious attachments in **untrusted** disposables

**Configuration**:
```bash
ENABLE_WORK="true"
ENABLE_VAULT="true"
ENABLE_ANON="true"
ENABLE_UNTRUSTED="true"

ENABLE_SPLIT_GPG="true"
SPLIT_GPG_BACKEND="vault"
SPLIT_GPG_CLIENTS="work"

ALLOW_WORK_TO_VAULT_COPY="true"
ALLOW_UNTRUSTED_TO_WORK_COPY="ask"
ALLOW_WORK_VAULT_CLIPBOARD="ask"
```

---

### Developer

**Purpose**: Software development with secure key management

**Qubes Created**:
* **work** - Development environment (4GB RAM)
* **vault** - Air-gapped SSH keys and credentials
* **untrusted** - Testing untrusted code

**Security Features**:
* Split-SSH enabled (keys in vault)
* Higher memory for work qube
* Development tools pre-installed
* Git, build tools, languages

**Use Cases**:
* Software development
* Secure git commits
* SSH to servers
* Testing untrusted code

**Example Workflow**:
1. Code in **work** qube
2. SSH to servers using split-SSH (keys in **vault**)
3. Test untrusted libraries in **untrusted**
4. Commit and push securely

**Configuration**:
```bash
ENABLE_WORK="true"
ENABLE_VAULT="true"
ENABLE_ANON="false"
ENABLE_UNTRUSTED="true"

WORK_MEMORY="4096"
WORK_PACKAGES="vim git curl wget build-essential python3 nodejs"

ENABLE_SPLIT_SSH="true"
SPLIT_SSH_BACKEND="vault"
SPLIT_SSH_CLIENTS="work"
```

---

### Researcher

**Purpose**: Academic/scientific research with institutional access

**Qubes Created**:
* **work** - Research and writing (3GB RAM)
* **vault** - Air-gapped research data
* **anon** - Anonymous data collection via Tor
* **untrusted** - Handling untrusted datasets
* **vpn** - Institutional VPN access

**Security Features**:
* VPN qube for university/institution access
* Split-GPG for encrypted communications
* Anonymous data collection capability
* Secure data storage

**Use Cases**:
* Academic research
* Accessing institutional resources
* Anonymous surveys
* Secure data analysis

**Example Workflow**:
1. Collect data anonymously via **anon** qube
2. Access university resources through **vpn** qube
3. Analyze data in **work** qube
4. Store sensitive data in **vault**
5. Open untrusted datasets in **untrusted**

**Configuration**:
```bash
ENABLE_WORK="true"
ENABLE_VAULT="true"
ENABLE_ANON="true"
ENABLE_UNTRUSTED="true"
ENABLE_VPN="true"

WORK_MEMORY="3072"
VPN_PROVIDES_NETWORK="true"
```

---

### Teacher

**Purpose**: Educational use, classroom management

**Qubes Created**:
* **work** - Lesson planning and grading (2GB RAM)
* **vault** - Student data and grade storage (air-gapped)
* **untrusted** - Opening student submissions
* **sys-usb** - USB device management

**Security Features**:
* USB qube for safe device handling
* Air-gapped student data storage
* Disposable for student files
* File transfer policies

**Use Cases**:
* Grading assignments
* Managing student data
* Handling USB devices
* Opening untrusted student files

**Example Workflow**:
1. Plan lessons in **work** qube
2. Store grades in **vault** (protected by privacy laws)
3. Open student submissions in **untrusted**
4. Handle USB devices via **sys-usb**

**Configuration**:
```bash
ENABLE_WORK="true"
ENABLE_VAULT="true"
ENABLE_ANON="false"
ENABLE_UNTRUSTED="true"
ENABLE_USB="true"

USB_NAME="sys-usb"
```

---

### Pentester

**Purpose**: Penetration testing and security research

**Qubes Created**:
* **work** - Main testing environment (4GB RAM)
* **vault** - Air-gapped tools and credentials
* **anon** - Anonymous reconnaissance via Tor
* **untrusted** - Malware analysis
* **vpn** - Client VPN access
* **sys-usb** - Hardware hacking tools

**Security Features**:
* Split-GPG and split-SSH
* All qubes enabled
* High memory allocations
* Security tools pre-installed
* VPN for client networks

**Use Cases**:
* Penetration testing
* Security research
* Malware analysis
* Hardware security testing

**Example Workflow**:
1. Reconnaissance via **anon** qube
2. Connect to client network via **vpn**
3. Run tools from **work** qube
4. Analyze malware in **untrusted**
5. Store findings in **vault**
6. Use **sys-usb** for hardware tools

**Configuration**:
```bash
ENABLE_WORK="true"
ENABLE_VAULT="true"
ENABLE_ANON="true"
ENABLE_UNTRUSTED="true"
ENABLE_VPN="true"
ENABLE_USB="true"

WORK_MEMORY="4096"
WORK_PACKAGES="vim git curl wget nmap wireshark metasploit-framework"

VPN_PROVIDES_NETWORK="true"

ENABLE_SPLIT_GPG="true"
ENABLE_SPLIT_SSH="true"
```

---

## Custom Preset

**Purpose**: Create your own configuration

**Configuration**:
```bash
TOPOLOGY_PRESET="custom"

# Then configure individual qubes
ENABLE_WORK="true"
ENABLE_VAULT="true"
# etc.
```

## Comparison Matrix

| Feature | Journalist | Developer | Researcher | Teacher | Pentester |
|---------|-----------|-----------|------------|---------|-----------|
| work qube | ✓ (2GB) | ✓ (4GB) | ✓ (3GB) | ✓ (2GB) | ✓ (4GB) |
| vault qube | ✓ | ✓ | ✓ | ✓ | ✓ |
| anon qube | ✓ | ✗ | ✓ | ✗ | ✓ |
| untrusted qube | ✓ | ✓ | ✓ | ✓ | ✓ |
| vpn qube | ✗ | ✗ | ✓ | ✗ | ✓ |
| usb qube | ✗ | ✗ | ✗ | ✓ | ✓ |
| Split-GPG | ✓ | ✗ | ✓ | ✗ | ✓ |
| Split-SSH | ✗ | ✓ | ✗ | ✗ | ✓ |
| Dev Tools | ✗ | ✓ | ✗ | ✗ | ✗ |
| Security Tools | ✗ | ✗ | ✗ | ✗ | ✓ |

## Modifying Presets

### Override Individual Settings

You can use a preset as a base and override specific settings:

```bash
# In qubes-config.conf
TOPOLOGY_PRESET="journalist"

# But override memory
WORK_MEMORY="4096"
```

**Note**: This works for some settings but not all. For full control, use `TOPOLOGY_PRESET="custom"`.

### Create Your Own Preset

Edit `qubes-setup-advanced.sh` and add a new function:

```bash
apply_preset_mypreset() {
    log INFO "Applying 'mypreset' topology preset"

    ENABLE_WORK="true"
    ENABLE_VAULT="true"
    # ... configure as needed

    log SUCCESS "My preset applied"
}
```

Then call it:

```bash
TOPOLOGY_PRESET="mypreset"
```

## Memory Requirements

Minimum RAM for each preset:

* **Journalist**: 8GB (comfortable with 12GB)
* **Developer**: 12GB (comfortable with 16GB)
* **Researcher**: 12GB (comfortable with 16GB)
* **Teacher**: 8GB (comfortable with 12GB)
* **Pentester**: 16GB (comfortable with 24GB+)

These assume running all qubes simultaneously. Running qubes on-demand reduces requirements.

## Choosing a Preset

Ask yourself:

1. **What's my primary use case?**
   - Journalism/activism → journalist
   - Software development → developer
   - Research → researcher
   - Teaching → teacher
   - Security testing → pentester

2. **Do I need anonymity?**
   - Yes → journalist, researcher, or pentester
   - No → developer or teacher

3. **Do I need VPN access?**
   - Yes → researcher or pentester
   - No → journalist, developer, or teacher

4. **Do I need USB device handling?**
   - Yes → teacher or pentester
   - No → journalist, developer, or researcher

5. **How much RAM do I have?**
   - 8GB → journalist or teacher (minimal)
   - 12-16GB → developer or researcher
   - 16GB+ → pentester

6. **Do I need split-SSH?**
   - Yes → developer or pentester
   - No → journalist, researcher, or teacher

## Preset Best Practices

1. **Start with a preset** - Easier than configuring from scratch
2. **Understand what it does** - Read the configuration
3. **Test in dry-run mode** - See what will be created
4. **Customize if needed** - Adjust memory, packages, etc.
5. **Document changes** - Note any modifications you make

## After Setup

### Journalist Next Steps

1. Set up Thunderbird with Enigmail in **work**
2. Generate GPG key in **vault**
3. Configure Tor Browser in **anon**
4. Test split-GPG: `qubes-gpg-client --list-keys`

### Developer Next Steps

1. Install your preferred IDE in **work**
2. Generate SSH key in **vault**
3. Configure git in **work**
4. Test split-SSH: `ssh -T git@github.com`

### Researcher Next Steps

1. Configure VPN credentials in **vpn** qube
2. Install analysis tools in **work**
3. Set up Tor Browser in **anon**
4. Create data directory in **vault**

### Teacher Next Steps

1. Configure USB devices in **sys-usb**
2. Set up grading software in **work**
3. Create student data folders in **vault**
4. Test file handling workflow

### Pentester Next Steps

1. Install additional security tools
2. Configure VPN for client networks
3. Set up malware analysis environment
4. Test tool functionality

## References

* [Qubes OS Workflow Examples](https://www.qubes-os.org/doc/)
* [Split-GPG Documentation](split-gpg.html)
* [Split-SSH Documentation](split-ssh.html)
* [VPN Setup Guide](vpn-setup.html)

## Next Steps

* **[Configuration Guide](configuration.html)** - Fine-tune your preset
* **[Security Guide](security-guide.html)** - Best practices
* **[Getting Started](getting-started.html)** - Run your setup
