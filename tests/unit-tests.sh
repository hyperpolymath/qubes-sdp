#!/bin/bash
# Unit Tests for Qubes SDP
# Tests individual functions and components

set -e

TESTS_PASSED=0
TESTS_FAILED=0

# Test function
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

echo "Running unit tests..."
echo

# Test configuration file parsing
echo "Testing configuration file:"

if [ -f "../qubes-config.conf" ]; then
    source ../qubes-config.conf 2>/dev/null || true

    test_assert "DEFAULT_TEMPLATE is set" "[ -n \"${DEFAULT_TEMPLATE}\" ]"
    test_assert "ENABLE_WORK is boolean" "[ \"${ENABLE_WORK}\" = \"true\" ] || [ \"${ENABLE_WORK}\" = \"false\" ]"
    test_assert "WORK_MEMORY is numeric" "[[ \"${WORK_MEMORY}\" =~ ^[0-9]+$ ]]"
else
    echo "  ! Config file not found, skipping"
fi

echo

# Test script executability
echo "Testing script permissions:"

test_assert "Simple setup script is executable" "[ -x ../qubes-setup.sh ]"
test_assert "Advanced setup script is executable" "[ -x ../qubes-setup-advanced.sh ]"

echo

# Test required directories
echo "Testing directory structure:"

test_assert "Tools directory exists" "[ -d ../tools ]"
test_assert "Wiki directory exists" "[ -d ../wiki ]"
test_assert "Salt directory exists" "[ -d ../qubes-salt ]"
test_assert "Tests directory exists" "[ -d ../tests ]"

echo

# Test tool scripts
echo "Testing tool scripts:"

for tool in ../tools/*.sh; do
    if [ -f "${tool}" ]; then
        tool_name=$(basename "${tool}")
        test_assert "${tool_name} is executable" "[ -x \"${tool}\" ]"
    fi
done

echo

# Test wiki build
echo "Testing wiki system:"

test_assert "Wiki build script exists" "[ -f ../wiki/build-wiki.sh ]"
test_assert "Wiki build script is executable" "[ -x ../wiki/build-wiki.sh ]"
test_assert "Wiki template exists" "[ -f ../wiki/templates/page.html ]"
test_assert "Wiki CSS exists" "[ -f ../wiki/static/css/style.css ]"

echo

# Summary
echo "Unit test summary:"
echo "  Passed: ${TESTS_PASSED}"
echo "  Failed: ${TESTS_FAILED}"

if [ ${TESTS_FAILED} -eq 0 ]; then
    exit 0
else
    exit 1
fi
