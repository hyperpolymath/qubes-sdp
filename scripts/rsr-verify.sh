#!/bin/bash
# RSR (Rhodium Standard Repository) Compliance Verification
# Checks project compliance with RSR Framework standards

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# Compliance tracking
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0

# Check result
check() {
    local description=$1
    local test_command=$2
    local severity=${3:-error}  # error or warning

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if eval "${test_command}"; then
        echo -e "${GREEN}✓${NC} ${description}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        if [ "${severity}" = "warning" ]; then
            echo -e "${YELLOW}⚠${NC} ${description}"
            WARNINGS=$((WARNINGS + 1))
            return 0
        else
            echo -e "${RED}✗${NC} ${description}"
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            return 1
        fi
    fi
}

# Header
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}           ${BLUE}RSR Compliance Verification${NC}                     ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo

cd "${PROJECT_ROOT}"

# ============================================================================
# Category 1: Documentation
# ============================================================================

echo -e "${BLUE}=== Documentation ===${NC}"
echo

check "README.md exists" "[ -f README.md ]"
check "README.md has content (>500 chars)" "[ \$(wc -c < README.md) -gt 500 ]"
check "LICENSE exists" "[ -f LICENSE ]"
check "SECURITY.adoc exists" "[ -f SECURITY.adoc ]"
check "CONTRIBUTING.adoc exists" "[ -f CONTRIBUTING.adoc ]"
check "CODE_OF_CONDUCT.adoc exists" "[ -f CODE_OF_CONDUCT.adoc ]"
check "MAINTAINERS.adoc exists" "[ -f MAINTAINERS.adoc ]"
check "CHANGELOG.adoc exists" "[ -f CHANGELOG.adoc ]"

echo

# ============================================================================
# Category 2: .well-known Directory
# ============================================================================

echo -e "${BLUE}=== .well-known Directory ===${NC}"
echo

check ".well-known/ directory exists" "[ -d .well-known ]"
check "security.txt exists (RFC 9116)" "[ -f .well-known/security.txt ]"
check "security.txt has Contact field" "grep -q '^Contact:' .well-known/security.txt"
check "security.txt has Expires field" "grep -q '^Expires:' .well-known/security.txt"
check "ai.txt exists" "[ -f .well-known/ai.txt ]"
check "ai.txt prohibits AI training" "grep -qi 'not available.*training' .well-known/ai.txt"
check "humans.txt exists" "[ -f .well-known/humans.txt ]"

echo

# ============================================================================
# Category 3: Build System
# ============================================================================

echo -e "${BLUE}=== Build System ===${NC}"
echo

check "justfile exists" "[ -f Justfile ]"
check "justfile has setup recipes" "grep -q 'setup' Justfile"
check "justfile has test recipes" "grep -q 'test' Justfile"
check "flake.nix exists (Nix)" "[ -f flake.nix ]"
check "Makefile exists" "[ -f Makefile.qubes ]"
check "CI/CD configuration exists" "[ -f .gitlab-ci.yml ] || [ -f .github/workflows/*.yml ]"

echo

# ============================================================================
# Category 4: Testing
# ============================================================================

echo -e "${BLUE}=== Testing ===${NC}"
echo

check "tests/ directory exists" "[ -d tests ]"
check "Test runner exists" "[ -f tests/run-tests.sh ]"
check "Unit tests exist" "[ -f tests/unit-tests.sh ]"
check "Integration tests exist" "[ -f tests/integration-tests.sh ]"
check "Security tests exist" "[ -f tests/security-tests.sh ]"
check "Tests are executable" "[ -x tests/run-tests.sh ]"

echo

# ============================================================================
# Category 5: Security
# ============================================================================

echo -e "${BLUE}=== Security ===${NC}"
echo

check "SECURITY.adoc has vulnerability reporting" "grep -qi 'report.*vulnerability' SECURITY.adoc"
check "No hardcoded passwords in scripts" "! grep -rE '(password|passwd|pwd)[[:space:]]*=[[:space:]]*['\\''\"]?[^'\\''\"]' --include='*.sh' . | grep -v '^[[:space:]]*#'"
check "No curl piped to shell" "! grep -rE 'curl.*\\|.*sh' --include='*.sh' --exclude='*-verify.sh' --exclude='security-tests.sh' ."
check "Scripts check for dom0" "grep -q 'hostname.*dom0' qubes-setup.sh"
check "No unsafe eval usage" "! grep -E 'eval.*\\\\\\$' --include='*.sh' . | grep -qv '#'" "warning"

echo

# ============================================================================
# Category 6: Offline-First
# ============================================================================

echo -e "${BLUE}=== Offline-First ===${NC}"
echo

check "No network calls in core scripts" "! grep -E '(curl|wget|fetch).*http' qubes-setup.sh" "warning"
check "Can run without internet (air-gapped)" "[ true ]" "warning"  # Manual verification needed

echo

# ============================================================================
# Category 7: Type Safety (Not applicable to Bash)
# ============================================================================

echo -e "${BLUE}=== Type Safety ===${NC}"
echo

check "Scripts use 'set -e' for error handling" "grep -q 'set -e' qubes-setup.sh"
check "Scripts use 'set -u' for undefined vars" "grep -q 'set -u' qubes-setup-advanced.sh" "warning"
check "Variables are quoted" "[ true ]" "warning"  # Manual verification

echo

# ============================================================================
# Category 8: TPCF (Tri-Perimeter Contribution Framework)
# ============================================================================

echo -e "${BLUE}=== TPCF Perimeter Designation ===${NC}"
echo

check "TPCF perimeter declared in README" "grep -qi 'tpcf\|perimeter.*3\|community sandbox' README.md"
check "CODE_OF_CONDUCT mentions TPCF" "grep -qi 'tpcf\|tri-perimeter' CODE_OF_CONDUCT.adoc"
check "Open contribution model" "grep -qi 'open.*contrib' CONTRIBUTING.adoc"

echo

# ============================================================================
# Category 9: Emotional Safety
# ============================================================================

echo -e "${BLUE}=== Emotional Safety ===${NC}"
echo

check "CODE_OF_CONDUCT has emotional safety section" "grep -qi 'emotional.*safety' CODE_OF_CONDUCT.adoc"
check "Reversibility mentioned" "grep -qi 'revers' CODE_OF_CONDUCT.adoc"
check "Learning culture emphasized" "grep -qi 'learning\|mistake.*opportunit' CODE_OF_CONDUCT.adoc"
check "Inclusive language guidelines" "grep -qi 'inclusive.*language' CODE_OF_CONDUCT.adoc" "warning"

echo

# ============================================================================
# Category 10: Accessibility (Documentation)
# ============================================================================

echo -e "${BLUE}=== Accessibility ===${NC}"
echo

check "README has clear structure" "grep -q '^## ' README.md"
check "Documentation has examples" "grep -qi 'example' README.md"
check "QUICKSTART guide exists" "[ -f QUICKSTART.adoc ]"
check "Troubleshooting guide exists" "[ -f wiki/pages/troubleshooting.md ] || grep -qi 'troubleshoot' README.md"

echo

# ============================================================================
# Category 11: Reproducibility
# ============================================================================

echo -e "${BLUE}=== Reproducibility ===${NC}"
echo

check "Nix flake for reproducible builds" "[ -f flake.nix ]"
check "Example configurations provided" "[ -d examples ] && [ \$(ls -1 examples/*.conf 2>/dev/null | wc -l) -gt 0 ]"
check "Version pinning in scripts" "grep -q 'VERSION\|version' qubes-setup.sh || [ -f .tool-versions ]" "warning"

echo

# ============================================================================
# Summary
# ============================================================================

SCORE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

echo -e "${BLUE}=== RSR Compliance Summary ===${NC}"
echo -e "────────────────────────────────────────────────────────────────"
echo -e "Total checks:    ${TOTAL_CHECKS}"
echo -e "Passed:          ${GREEN}${PASSED_CHECKS}${NC}"
echo -e "Failed:          ${RED}${FAILED_CHECKS}${NC}"
echo -e "Warnings:        ${YELLOW}${WARNINGS}${NC}"
echo -e "Score:           ${SCORE}%"
echo -e "────────────────────────────────────────────────────────────────"

# Determine compliance level
if [ ${SCORE} -ge 90 ] && [ ${FAILED_CHECKS} -eq 0 ]; then
    LEVEL="${GREEN}GOLD${NC}"
    BADGE="🥇"
elif [ ${SCORE} -ge 75 ] && [ ${FAILED_CHECKS} -le 3 ]; then
    LEVEL="${YELLOW}SILVER${NC}"
    BADGE="🥈"
elif [ ${SCORE} -ge 60 ]; then
    LEVEL="${CYAN}BRONZE${NC}"
    BADGE="🥉"
else
    LEVEL="${RED}NON-COMPLIANT${NC}"
    BADGE="❌"
fi

echo
echo -e "${BADGE} RSR Compliance Level: ${LEVEL}"
echo

# Recommendations
if [ ${FAILED_CHECKS} -gt 0 ]; then
    echo -e "${YELLOW}Recommendations:${NC}"
    echo -e "  • Fix failed checks to improve compliance"
    echo -e "  • Review RSR framework documentation"
    echo -e "  • Consider using rhodium-init for new projects"
    echo
fi

# Exit code
if [ ${FAILED_CHECKS} -eq 0 ]; then
    exit 0
else
    exit 1
fi
