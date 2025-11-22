# Security Policy

## Supported Versions

Currently supported versions for security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Security Model

Qubes SDP operates within the Qubes OS security model and adds additional protections:

### Trust Boundaries

1. **dom0** - Most trusted (runs setup scripts)
2. **vault qube** - Air-gapped (NO network, stores secrets)
3. **work qube** - Moderate trust (restricted firewall)
4. **anon qube** - Low trust (Tor/Whonix)
5. **untrusted qube** - Minimal trust (DisposableVMs)

### Security Features

- ✅ Air-gapped vault (enforced no-network)
- ✅ Default-deny firewalls
- ✅ Split-GPG/SSH (keys isolated in vault)
- ✅ DisposableVMs for risky content
- ✅ Input validation on all user inputs
- ✅ No hardcoded credentials
- ✅ Minimal templates (reduced attack surface)
- ✅ Qrexec policy enforcement

## Threat Model

### In Scope

- Vulnerabilities in setup scripts
- Privilege escalation within dom0
- Policy bypass in qrexec configurations
- Firewall rule circumvention
- Vault network isolation bypass
- Input validation flaws
- Insecure defaults
- Information disclosure

### Out of Scope

- Qubes OS core vulnerabilities (report to Qubes Security Team)
- Template package vulnerabilities (report to distro maintainers)
- Hardware vulnerabilities (CPU, speculative execution)
- Physical access attacks
- Social engineering

## Reporting a Vulnerability

**DO NOT** create public GitHub issues for security vulnerabilities.

### Preferred Method: GitHub Security Advisories

1. Go to: https://github.com/hyperpolymath/qubes-sdp/security/advisories
2. Click "Report a vulnerability"
3. Fill in the details
4. Submit privately

### Alternative: Email

**Email:** security@qubes-sdp.org

**PGP Key:** [Available in .well-known/security.txt]

### What to Include

Please provide:

1. **Description** - Clear explanation of the vulnerability
2. **Impact** - Potential security impact and affected components
3. **Steps to Reproduce** - Detailed reproduction steps
4. **Proof of Concept** - Code, screenshots, or logs (if applicable)
5. **Suggested Fix** - Your recommendation (optional)
6. **Environment** - Qubes version, RAM, setup configuration

### Example Report

```
Subject: [SECURITY] Vault network isolation bypass

Description:
The vault qube can be created with network access if the user
modifies VAULT_NETVM before setup validation occurs.

Impact:
High - Compromises air-gap security model

Steps to Reproduce:
1. Edit qubes-config.conf
2. Set VAULT_NETVM="sys-firewall" (commented out)
3. Run setup without dry-run
4. Vault qube has network access

Suggested Fix:
Add explicit check: if vault netvm is set, abort setup
and warn user.

Environment:
Qubes OS 4.2, 16GB RAM, fedora-40-minimal templates
```

## Response Process

### Timeline

- **Acknowledgment:** Within 48 hours
- **Initial Assessment:** Within 7 days
- **Status Update:** Every 7 days until resolved
- **Fix Development:** Depends on severity (see below)
- **Public Disclosure:** After fix is released + 14 days

### Severity Levels

**Critical** (CVSS 9.0-10.0)
- Air-gap bypass
- dom0 compromise
- Immediate fix (24-48 hours)

**High** (CVSS 7.0-8.9)
- Policy bypass
- Privilege escalation
- Fix within 7 days

**Medium** (CVSS 4.0-6.9)
- Information disclosure
- Weak defaults
- Fix within 30 days

**Low** (CVSS 0.1-3.9)
- Minor security improvements
- Fix in next release

### Disclosure Policy

We follow **coordinated disclosure**:

1. Reporter notifies us privately
2. We acknowledge and assess
3. We develop and test fix
4. We release patched version
5. We publish security advisory
6. Reporter receives credit (if desired)

**Embargo period:** Minimum 14 days after fix release

## Security Best Practices

### For Users

1. **Always review scripts before running in dom0**
   ```bash
   # Read the code first
   less qubes-setup.sh

   # Test with dry-run
   ./qubes-setup.sh --dry-run
   ```

2. **Verify vault has no network**
   ```bash
   qvm-prefs vault netvm
   # Should be empty
   ```

3. **Keep templates updated**
   ```bash
   make -f Makefile.qubes template-update
   ```

4. **Run security tests**
   ```bash
   bash tests/security-tests.sh
   ```

5. **Use minimal templates**
   ```bash
   DEFAULT_TEMPLATE="fedora-40-minimal"
   ```

### For Developers

1. **Validate all inputs**
   ```bash
   # Bad
   qvm-create "${user_input}"

   # Good
   if [[ ! "${user_input}" =~ ^[a-z0-9-]+$ ]]; then
       error "Invalid qube name"
   fi
   ```

2. **Never hardcode secrets**
   ```bash
   # Bad
   PASSWORD="secret123"

   # Good
   read -s -p "Password: " PASSWORD
   ```

3. **Use set -e for error handling**
   ```bash
   #!/bin/bash
   set -e  # Exit on error
   set -u  # Error on undefined variables
   set -o pipefail  # Catch errors in pipes
   ```

4. **Avoid dangerous commands**
   ```bash
   # Never
   rm -rf /
   eval "${user_input}"
   curl https://url | bash
   ```

5. **Check for dom0**
   ```bash
   if [ "$(hostname)" != "dom0" ]; then
       error "Must run in dom0"
       exit 1
   fi
   ```

## Security Testing

### Automated Tests

```bash
# Run security test suite
bash tests/security-tests.sh

# Check for:
# - Hardcoded credentials
# - Unsafe eval usage
# - Missing input validation
# - World-writable files
# - Vault network access
```

### Manual Testing

1. **Air-gap verification**
   ```bash
   qvm-prefs vault netvm
   qvm-run vault 'ping -c 1 8.8.8.8'  # Should fail
   ```

2. **Firewall verification**
   ```bash
   qvm-firewall work list
   # Should have drop rule at end
   ```

3. **Policy verification**
   ```bash
   cat /etc/qubes-rpc/policy/qubes.Filecopy
   # Should have explicit rules, no wildcards
   ```

## Known Limitations

1. **dom0 Trust** - Scripts run in dom0 with full privileges
   - **Mitigation:** Dry-run mode, code review, testing

2. **Template Vulnerabilities** - Inherited from upstream
   - **Mitigation:** Use minimal templates, keep updated

3. **Qrexec Policies** - User can modify after setup
   - **Mitigation:** Validation tools, documentation

4. **Backup Encryption** - Depends on user-chosen passphrase
   - **Mitigation:** Passphrase strength checks, documentation

## Security Acknowledgments

We thank the following researchers for responsible disclosure:

*(List will be added as vulnerabilities are reported and fixed)*

## Security Contacts

- **Primary:** security@qubes-sdp.org
- **PGP Key:** See .well-known/security.txt
- **GitHub:** https://github.com/hyperpolymath/qubes-sdp/security

## Additional Resources

- [Qubes OS Security Guidelines](https://www.qubes-os.org/doc/security-guidelines/)
- [Qubes OS Security Advisories](https://www.qubes-os.org/security/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)

## Updates

This security policy is reviewed quarterly and updated as needed.

Last updated: 2024-11-22
Version: 1.0.0

---

**Note:** This policy applies to the Qubes SDP project itself. For Qubes OS security issues, see https://www.qubes-os.org/security/
