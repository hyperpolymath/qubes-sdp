#!/bin/bash
# Security Tests for Qubes SDP
# Checks for security issues and best practices

set -e

TESTS_PASSED=0
TESTS_FAILED=0
WARNINGS=0

test_assert() {
    local description=$1
    local condition=$2
    local severity=${3:-error}  # error or warning

    if eval "${condition}"; then
        echo "  ✓ ${description}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        if [ "${severity}" = "warning" ]; then
            echo "  ⚠ ${description}"
            WARNINGS=$((WARNINGS + 1))
            return 0
        else
            echo "  ✗ ${description}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    fi
}

echo "Running security tests..."
echo

# Test configuration security
echo "Testing configuration security:"

if [ -f "../qubes-config.conf" ]; then
    source ../qubes-config.conf 2>/dev/null || true

    # Check vault has no network
    test_assert "Vault has no network configured" "[ -z \"${VAULT_NETVM}\" ] || [ \"${VAULT_NETVM}\" = \"\" ]"

    # Check firewall policy
    test_assert "Work uses custom firewall policy" "[ \"${WORK_FIREWALL_POLICY}\" = \"custom\" ] || [ \"${WORK_FIREWALL_POLICY}\" = \"deny-all\" ]"

    # Check untrusted is DispVM
    test_assert "Untrusted configured as DispVM template" "[ \"${UNTRUSTED_IS_DISPVM_TEMPLATE}\" = \"true\" ]" "warning"

    # Check backups are enabled
    test_assert "Auto backup is enabled" "[ \"${AUTO_BACKUP}\" = \"true\" ]" "warning"

    # Check backup compression
    test_assert "Backup compression enabled" "[ \"${BACKUP_COMPRESSION}\" = \"true\" ]" "warning"
fi

echo

# Test script security
echo "Testing script security:"

# Check for dangerous commands in scripts
for script in ../qubes-setup*.sh; do
    if [ -f "${script}" ]; then
        script_name=$(basename "${script}")

        # Should not have rm -rf / or similar
        test_assert "${script_name} doesn't contain 'rm -rf /'" "! grep -q 'rm -rf /' \"${script}\""

        # Should not have eval of user input without validation
        test_assert "${script_name} doesn't have unsafe eval" "! grep -E 'eval .*\\$[{]?[a-zA-Z_]+' \"${script}\" | grep -qv '#'"

        # Should check for dom0
        test_assert "${script_name} checks for dom0" "grep -q 'hostname.*dom0' \"${script}\""
    fi
done

echo

# Test file permissions
echo "Testing file permissions:"

# Scripts should be executable but not world-writable
for script in ../*.sh ../tools/*.sh; do
    if [ -f "${script}" ]; then
        script_name=$(basename "${script}")

        test_assert "${script_name} is executable" "[ -x \"${script}\" ]"
        test_assert "${script_name} not world-writable" "[ ! -w \"${script}\" ] || ! stat -c '%A' \"${script}\" | grep -q 'w$'"
    fi
done

echo

# Test for hardcoded credentials
echo "Testing for hardcoded credentials:"

for file in ../*.sh ../*.conf; do
    if [ -f "${file}" ]; then
        filename=$(basename "${file}")

        # Check for passwords
        test_assert "${filename} doesn't contain hardcoded passwords" "! grep -iE '(password|passwd|pwd)[[:space:]]*=[[:space:]]*['\\''\"]?[^'\\''\"]' \"${file}\" | grep -qv '^[[:space:]]*#'"

        # Check for API keys
        test_assert "${filename} doesn't contain API keys" "! grep -iE '(api[_-]?key|apikey|secret)[[:space:]]*=' \"${file}\" | grep -qv '^[[:space:]]*#'" "warning"
    fi
done

echo

# Test Salt Stack security
echo "Testing Salt Stack security:"

if [ -f "../qubes-salt/qubes-sdp.sls" ]; then
    # Vault should have no network
    test_assert "Salt: vault has no network" "grep -A 5 '^vault:' ../qubes-salt/qubes-sdp.sls | grep -q 'netvm: \"\"'"

    # Check for firewall rules
    test_assert "Salt: work has firewall rules" "grep -A 10 '^work:' ../qubes-salt/qubes-sdp.sls | grep -q 'qvm.firewall'" "warning"
fi

echo

# Test for unsafe practices
echo "Testing for unsafe practices:"

for script in ../*.sh ../tools/*.sh; do
    if [ -f "${script}" ]; then
        script_name=$(basename "${script}")

        # Should not use curl without verification
        test_assert "${script_name} doesn't use curl without verification" "! grep 'curl.*-k' \"${script}\"" "warning"

        # Should not download and execute directly
        test_assert "${script_name} doesn't pipe curl to shell" "! grep -E 'curl.*\\|.*sh' \"${script}\""
    fi
done

echo

# Summary
echo "Security test summary:"
echo "  Passed: ${TESTS_PASSED}"
echo "  Failed: ${TESTS_FAILED}"
echo "  Warnings: ${WARNINGS}"

if [ ${TESTS_FAILED} -eq 0 ]; then
    echo ""
    echo "All critical security tests passed!"
    if [ ${WARNINGS} -gt 0 ]; then
        echo "Review warnings above for potential improvements."
    fi
    exit 0
else
    echo ""
    echo "Critical security issues found!"
    exit 1
fi
