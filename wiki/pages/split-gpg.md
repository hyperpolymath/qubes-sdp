# Split-GPG Guide

Complete guide to using Split-GPG in Qubes SDP for secure email encryption and signing.

## What is Split-GPG?

Split-GPG is a Qubes OS security feature that stores GPG keys in an air-gapped qube (vault) while allowing other qubes (work) to use them for encryption, decryption, and signing operations. The private keys never leave the vault.

## Benefits

* **Security**: Keys protected even if work qube compromised
* **Air-gap**: Keys stored in network-isolated vault
* **User Control**: Every operation requires user confirmation
* **Separation**: Crypto operations isolated from daily tasks
* **Backup**: Keys easily backed up with vault qube

## Architecture

```
┌──────────────┐                    ┌──────────────┐
│  work qube   │                    │  vault qube  │
│              │                    │              │
│ Thunderbird  │  ─qrexec request→  │  GPG keys    │
│ mutt/git     │  ←encrypted data─  │  (air-gap)   │
│              │                    │              │
└──────────────┘                    └──────────────┘
    (network)                          (NO network)
```

## Setup

### Automatic Setup (via Qubes SDP)

```bash
# Edit qubes-config.conf
ENABLE_SPLIT_GPG="true"
SPLIT_GPG_BACKEND="vault"
SPLIT_GPG_CLIENTS="work"

# Run setup
./qubes-setup-advanced.sh
```

### Manual Setup

```bash
# 1. Install split-gpg packages
qvm-run -u root vault 'dnf install qubes-gpg-split'
qvm-run -u root work 'dnf install qubes-gpg-split'

# 2. Configure work qube
qvm-run work 'echo "export QUBES_GPG_DOMAIN=vault" >> ~/.bashrc'

# 3. Add qrexec policy
echo "work vault ask" | sudo tee -a /etc/qubes-rpc/policy/qubes.Gpg
```

## Generating Keys

### In Vault Qube

```bash
# Start vault
qvm-start vault

# Generate key
qvm-run vault 'gpg --full-gen-key'

# Follow prompts:
# - Choose RSA and RSA
# - Key size: 4096
# - Expiration: 1 year recommended
# - Name and email
# - Passphrase (important!)
```

### Best Practices for Key Generation

* **Use strong passphrase** - Protects keys if vault compromised
* **Set expiration** - 1-2 years recommended
* **Use real identity** - For verification
* **Backup immediately** - Export and store securely

## Using Split-GPG

### List Keys

```bash
# From work qube
qubes-gpg-client --list-keys
qubes-gpg-client --list-secret-keys
```

### Encrypt File

```bash
# Encrypt for recipient
qubes-gpg-client --encrypt --recipient user@example.com file.txt

# Creates file.txt.gpg
```

### Decrypt File

```bash
# Decrypt file
qubes-gpg-client --decrypt file.txt.gpg > file.txt

# User will see confirmation dialog in vault
```

### Sign File

```bash
# Detached signature
qubes-gpg-client --detach-sign document.pdf

# Creates document.pdf.sig

# Clearsign
qubes-gpg-client --clearsign message.txt
```

### Verify Signature

```bash
# Verify detached signature
qubes-gpg-client --verify document.pdf.sig document.pdf

# Verify clearsigned message
qubes-gpg-client --verify message.txt.asc
```

### Sign and Encrypt

```bash
# Sign and encrypt
qubes-gpg-client --sign --encrypt --recipient user@example.com file.txt
```

## Email Integration

### Thunderbird with Enigmail

1. Install Thunderbird in work qube:
```bash
qvm-run -u root work 'dnf install thunderbird'
```

2. Install Enigmail extension

3. Configure Enigmail:
   - Set GPG binary to: `/usr/bin/qubes-gpg-client-wrapper`
   - Or use standard `/usr/bin/gpg` (wrapper auto-configured)

4. Import keys:
```bash
# Enigmail will use qubes-gpg-client automatically
```

5. Send encrypted email - Enigmail handles it automatically

### Mutt

```bash
# In ~/.muttrc
set pgp_decode_command="qubes-gpg-client --decrypt %f"
set pgp_verify_command="qubes-gpg-client --verify %s %f"
set pgp_decrypt_command="qubes-gpg-client --decrypt %f"
set pgp_sign_command="qubes-gpg-client --armor --detach-sign %f"
set pgp_encrypt_command="qubes-gpg-client --armor --encrypt --recipient %r %f"
```

### NeoMutt

Similar to Mutt - replace `gpg` commands with `qubes-gpg-client`.

## Git Signing

### Configure Git

```bash
# In work qube
git config --global user.signingkey <KEY-ID>
git config --global gpg.program qubes-gpg-client

# Enable commit signing
git config --global commit.gpgsign true
```

### Get Key ID

```bash
qubes-gpg-client --list-secret-keys --keyid-format LONG

# Output:
# sec   rsa4096/ABCDEF1234567890 2024-01-01
#       ^^^^^^^^^^^^^^^^^^^^
#       This is your KEY-ID
```

### Sign Commits

```bash
# Commits now auto-signed
git commit -m "My commit"

# Explicit signing
git commit -S -m "Signed commit"

# Sign tags
git tag -s v1.0 -m "Version 1.0"
```

### Verify Signatures

```bash
# Verify commit
git verify-commit HEAD

# Verify tag
git verify-tag v1.0

# Show signature in log
git log --show-signature
```

## Key Management

### Export Public Key

```bash
# From work qube (vault must be running)
qubes-gpg-client --armor --export user@example.com > public-key.asc

# Share public-key.asc with others
```

### Import Public Keys

```bash
# Import someone else's public key
qvm-run vault 'gpg --import' < their-public-key.asc

# Or copy file to vault first
qvm-copy-to-vm vault their-public-key.asc
qvm-run vault 'gpg --import ~/QubesIncoming/work/their-public-key.asc'
```

### Export Private Key (for backup)

```bash
# CAREFUL - this exports your private key!
# Only do this for backup purposes

qvm-run vault 'gpg --armor --export-secret-keys user@example.com' > private-key-backup.asc

# Store private-key-backup.asc in secure offline location
# Delete from work qube immediately!
shred -u private-key-backup.asc
```

### Import Private Key

```bash
# In vault qube
qvm-run vault 'gpg --import' < private-key-backup.asc
```

### Revoke Key

```bash
# If key compromised, generate revocation certificate
qvm-run vault 'gpg --gen-revoke user@example.com' > revoke.asc

# Publish to keyservers
qvm-run vault 'gpg --import revoke.asc'
qvm-run work 'qubes-gpg-client --keyserver keyserver.ubuntu.com --send-keys <KEY-ID>'
```

## Keyserver Operations

### Upload to Keyserver

```bash
# From work qube
qubes-gpg-client --keyserver keyserver.ubuntu.com --send-keys <KEY-ID>
```

### Search Keyserver

```bash
qubes-gpg-client --keyserver keyserver.ubuntu.com --search-keys user@example.com
```

### Receive from Keyserver

```bash
qubes-gpg-client --keyserver keyserver.ubuntu.com --recv-keys <KEY-ID>
```

## Security Considerations

### User Confirmation

Every operation shows a confirmation dialog in vault:

```
Request from 'work':
- Decrypt file.txt.gpg
Allow? [Y/n]
```

**Always verify requests are legitimate!**

### Passphrase Protection

* Set strong passphrase on keys
* Passphrase only entered in vault (never exposed to work)
* Consider using passphrase manager in vault

### Key Backup

Backup vault qube regularly:

```bash
make -f Makefile.qubes backup
```

Or export keys:

```bash
qvm-run vault 'gpg --export-secret-keys --armor' > keys-backup.asc
# Store securely offline
```

### Key Expiration

Set expiration dates:

```bash
# Edit key
qvm-run vault 'gpg --edit-key user@example.com'
# gpg> expire
# Set new expiration
# gpg> save
```

Update public key on keyservers after extending expiration.

## Troubleshooting

### "No secret key" error

**Problem**: work qube can't access keys

**Solutions**:

1. Verify vault is running:
```bash
qvm-start vault
```

2. Check QUBES_GPG_DOMAIN:
```bash
echo $QUBES_GPG_DOMAIN
# Should output: vault
```

3. Set it if missing:
```bash
export QUBES_GPG_DOMAIN=vault
echo 'export QUBES_GPG_DOMAIN=vault' >> ~/.bashrc
```

4. Verify qrexec policy:
```bash
sudo cat /etc/qubes-rpc/policy/qubes.Gpg | grep work
```

### Operation hangs

**Problem**: GPG operation never completes

**Solutions**:

1. Check if confirmation dialog appeared in vault
2. Restart vault qube:
```bash
qvm-shutdown vault
qvm-start vault
```

3. Check qrexec:
```bash
journalctl -u qubes-qrexec-policy-daemon
```

### "Permission denied" errors

**Solution**: Check qrexec policy allows work → vault:

```bash
sudo cat /etc/qubes-rpc/policy/qubes.Gpg
# Should contain:
work vault ask
```

### Keys not found after import

**Solution**: Import keys in vault, not work:

```bash
qvm-copy-to-vm vault key.asc
qvm-run vault 'gpg --import ~/QubesIncoming/work/key.asc'
```

## Advanced Usage

### Multiple Backend Qubes

Different keys in different qubes:

```bash
# Personal keys in vault
export QUBES_GPG_DOMAIN=vault

# Work keys in work-vault
export QUBES_GPG_DOMAIN=work-vault
```

### Subkeys

Use subkeys for different purposes:

```bash
# In vault
qvm-run vault 'gpg --edit-key user@example.com'
# gpg> addkey
# Choose capabilities (sign, encrypt, authenticate)
```

### Hardware Tokens

Combine with hardware tokens (YubiKey, etc.):

1. Configure hardware token in vault
2. Use split-GPG as normal
3. Token provides additional security layer

## Best Practices

1. **Strong passphrases** - Protect keys
2. **Regular backups** - Backup vault qube
3. **Set expiration** - Renew keys periodically
4. **Verify requests** - Check confirmation dialogs
5. **Use subkeys** - Separate signing/encryption
6. **Keep vault offline** - Never connect to network
7. **Test regularly** - Verify split-GPG works
8. **Document key IDs** - Keep record of keys
9. **Publish public keys** - Upload to keyservers
10. **Revoke if compromised** - Have revocation cert ready

## Real-World Workflows

### Encrypted Email

1. Write email in Thunderbird (work qube)
2. Click "Encrypt" in Enigmail
3. Confirm in vault dialog
4. Send email

### Signing Git Commits

1. Make changes in work qube
2. Commit: `git commit -m "message"`
3. Confirm signing in vault
4. Push to remote

### Decrypting Documents

1. Receive encrypted file
2. Save to work qube
3. Run: `qubes-gpg-client --decrypt file.gpg`
4. Confirm in vault
5. Read decrypted content

## References

* [Qubes Split-GPG Documentation](https://www.qubes-os.org/doc/split-gpg/)
* [GnuPG Manual](https://gnupg.org/documentation/)
* [Email Self-Defense (GNU)](https://emailselfdefense.fsf.org/)

## Next Steps

* **[Split-SSH Guide](split-ssh.html)** - Secure SSH keys
* **[Security Guide](security-guide.html)** - Best practices
* **[Backup & Restore](backup-restore.html)** - Protect your keys
