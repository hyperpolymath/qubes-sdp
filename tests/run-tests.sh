#!/bin/bash
# Qubes SDP Test Runner
# Runs all tests for the SDP system

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

# Test results
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Header
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}           ${BLUE}Qubes SDP Test Suite${NC}                            ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo

# Test function
run_test() {
    local test_name=$1
    local test_script=$2

    TESTS_RUN=$((TESTS_RUN + 1))

    echo -n "Running ${test_name}... "

    if bash "${test_script}"; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Syntax Tests
echo -e "${BLUE}=== Syntax Tests ===${NC}"
echo

for script in "${PROJECT_DIR}"/*.sh "${PROJECT_DIR}"/tools/*.sh; do
    if [ -f "${script}" ]; then
        script_name=$(basename "${script}")
        run_test "Syntax check: ${script_name}" "${SCRIPT_DIR}/syntax-test.sh ${script}"
    fi
done

echo

# Unit Tests
if [ -f "${SCRIPT_DIR}/unit-tests.sh" ]; then
    echo -e "${BLUE}=== Unit Tests ===${NC}"
    echo

    run_test "Unit tests" "${SCRIPT_DIR}/unit-tests.sh"

    echo
fi

# Integration Tests
if [ -f "${SCRIPT_DIR}/integration-tests.sh" ]; then
    echo -e "${BLUE}=== Integration Tests ===${NC}"
    echo

    run_test "Integration tests" "${SCRIPT_DIR}/integration-tests.sh"

    echo
fi

# Security Tests
if [ -f "${SCRIPT_DIR}/security-tests.sh" ]; then
    echo -e "${BLUE}=== Security Tests ===${NC}"
    echo

    run_test "Security tests" "${SCRIPT_DIR}/security-tests.sh"

    echo
fi

# Summary
echo -e "${BLUE}=== Test Summary ===${NC}"
echo -e "────────────────────────────────────────────────────────────────"
echo -e "Tests run:      ${TESTS_RUN}"
echo -e "Tests passed:   ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests failed:   ${RED}${TESTS_FAILED}${NC}"
echo -e "────────────────────────────────────────────────────────────────"
echo

# Exit code
if [ ${TESTS_FAILED} -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed${NC}"
    exit 1
fi
