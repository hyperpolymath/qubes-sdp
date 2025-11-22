#!/bin/bash
# Integration Tests for Qubes SDP
# Tests interaction between components

set -e

TESTS_PASSED=0
TESTS_FAILED=0

test_assert() {
    local description=$1
    local condition=$2

    if eval "${condition}"; then
        echo "  ✓ ${description}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "  ✗ ${description}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

echo "Running integration tests..."
echo

# Test Makefile integration
echo "Testing Makefile integration:"

if [ -f "../Makefile.qubes" ]; then
    # Test that make targets exist
    TARGETS=$(make -f ../Makefile.qubes -qp 2>/dev/null | grep -E "^[a-z].*:" | cut -d: -f1 | head -20)

    test_assert "Makefile has help target" "echo \"${TARGETS}\" | grep -q help"
    test_assert "Makefile has setup target" "echo \"${TARGETS}\" | grep -q setup"
    test_assert "Makefile has backup target" "echo \"${TARGETS}\" | grep -q backup"
    test_assert "Makefile has validate target" "echo \"${TARGETS}\" | grep -q validate"
else
    echo "  ! Makefile not found"
fi

echo

# Test configuration and scripts compatibility
echo "Testing script compatibility:"

# Check if scripts can source the config
if [ -f "../qubes-config.conf" ]; then
    test_assert "Config file is sourceable" "source ../qubes-config.conf 2>/dev/null"
else
    echo "  ! Config not found"
fi

echo

# Test tool script integration
echo "Testing tool integration:"

# Check if tools directory exists and scripts can find each other
if [ -d "../tools" ]; then
    test_assert "Tools directory contains scripts" "[ $(ls -1 ../tools/*.sh 2>/dev/null | wc -l) -gt 0 ]"

    # Test if dashboard can call other tools
    if [ -f "../tools/qubes-dashboard.sh" ]; then
        # Check if dashboard references other tools
        test_assert "Dashboard references status script" "grep -q qubes-status.sh ../tools/qubes-dashboard.sh"
    fi
fi

echo

# Test wiki build process
echo "Testing wiki build:"

if [ -x "../wiki/build-wiki.sh" ]; then
    # Create temp directory for test build
    TEST_BUILD_DIR=$(mktemp -d)

    # Try to build (but don't actually execute, just test the process)
    test_assert "Wiki build script has main function" "grep -q 'main' ../wiki/build-wiki.sh"

    rm -rf "${TEST_BUILD_DIR}"
else
    echo "  ! Wiki build script not found"
fi

echo

# Test Salt Stack integration
echo "Testing Salt Stack configuration:"

if [ -d "../qubes-salt" ]; then
    test_assert "Salt directory contains .sls files" "[ $(ls -1 ../qubes-salt/*.sls 2>/dev/null | wc -l) -gt 0 ]"

    if [ -f "../qubes-salt/qubes-sdp.sls" ]; then
        test_assert "Main SLS file contains qvm.vm states" "grep -q 'qvm.vm' ../qubes-salt/qubes-sdp.sls"
    fi

    if [ -f "../qubes-salt/top.sls" ]; then
        test_assert "Top file references qubes-sdp" "grep -q 'qubes-sdp' ../qubes-salt/top.sls"
    fi
fi

echo

# Summary
echo "Integration test summary:"
echo "  Passed: ${TESTS_PASSED}"
echo "  Failed: ${TESTS_FAILED}"

if [ ${TESTS_FAILED} -eq 0 ]; then
    exit 0
else
    exit 1
fi
