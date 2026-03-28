# Qubes SDP Salt State File
# This file defines the qube topology using Salt Stack

# ==============================================================================
# WORK QUBE
# ==============================================================================

work:
  qvm.vm:
    - present:
      - label: green
      - template: fedora-40-minimal
      - mem: 2048
      - netvm: sys-firewall
    - prefs:
      - autostart: False
      - include_in_backups: True
    - features:
      - service.cups: False
      - service.network-manager: False

  qvm.firewall:
    - present:
      - rules:
        - action: accept
          proto: tcp
          dstport: 80
          comment: "HTTP"
        - action: accept
          proto: tcp
          dstport: 443
          comment: "HTTPS"
        - action: accept
          proto: udp
          dstport: 53
          comment: "DNS"
        - action: drop
          comment: "Default deny"

# Install packages in work qube
work-packages:
  qvm.run:
    - name: |
        if command -v dnf &>/dev/null; then
          dnf install -y vim git curl wget
        elif command -v apt-get &>/dev/null; then
          apt-get update && apt-get install -y vim git curl wget
        fi
    - vm: work
    - user: root
    - require:
      - qvm: work

# ==============================================================================
# VAULT QUBE (Air-gapped)
# ==============================================================================

vault:
  qvm.vm:
    - present:
      - label: black
      - template: fedora-40-minimal
      - mem: 1024
      - netvm: ""  # NO NETWORK - air-gapped
    - prefs:
      - autostart: False
      - include_in_backups: True
    - features:
      - service.network-manager: False

vault-packages:
  qvm.run:
    - name: |
        if command -v dnf &>/dev/null; then
          dnf install -y vim keepassxc
        elif command -v apt-get &>/dev/null; then
          apt-get update && apt-get install -y vim keepassxc
        fi
    - vm: vault
    - user: root
    - require:
      - qvm: vault

# ==============================================================================
# ANON QUBE (Tor/Whonix)
# ==============================================================================

anon:
  qvm.vm:
    - present:
      - label: purple
      - template: fedora-40-minimal
      - mem: 1024
      - netvm: sys-whonix  # Will fallback if not available
    - prefs:
      - autostart: False
      - include_in_backups: True

anon-packages:
  qvm.run:
    - name: |
        if command -v dnf &>/dev/null; then
          dnf install -y vim
        elif command -v apt-get &>/dev/null; then
          apt-get update && apt-get install -y vim
        fi
    - vm: anon
    - user: root
    - require:
      - qvm: anon

# ==============================================================================
# UNTRUSTED QUBE (DispVM template)
# ==============================================================================

untrusted:
  qvm.vm:
    - present:
      - label: red
      - template: fedora-40-minimal
      - mem: 1024
      - netvm: sys-firewall
    - prefs:
      - autostart: False
      - include_in_backups: False
      - template_for_dispvms: True
    - features:
      - appmenus-dispvm: 1

untrusted-packages:
  qvm.run:
    - name: |
        if command -v dnf &>/dev/null; then
          dnf install -y vim
        elif command -v apt-get &>/dev/null; then
          apt-get update && apt-get install -y vim
        fi
    - vm: untrusted
    - user: root
    - require:
      - qvm: untrusted

# ==============================================================================
# QREXEC POLICIES
# ==============================================================================

# Allow file copy from work to vault
/etc/qubes-rpc/policy/qubes.Filecopy:
  file.append:
    - text: "work vault allow"

# Allow file copy from untrusted to work (with user confirmation)
/etc/qubes-rpc/policy/qubes.Filecopy-untrusted:
  file.append:
    - text: "untrusted work ask"

# Clipboard policy between work and vault (ask user)
/etc/qubes-rpc/policy/qubes.ClipboardPaste:
  file.append:
    - text: "work vault ask"
