#!/bin/bash
# Qubes SDP Firewall Analyzer
# Analyzes and displays firewall rules for all SDP qubes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}           ${BLUE}Qubes SDP Firewall Analyzer${NC}                     ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo

# Check dom0
if [ "$(hostname)" != "dom0" ]; then
    echo -e "${RED}ERROR: Must run in dom0${NC}"
    exit 1
fi

# Qubes to analyze
QUBES=("work" "anon" "untrusted" "vpn")

# Analyze qube firewall
analyze_qube() {
    local qube=$1

    if ! qvm-ls "${qube}" &>/dev/null; then
        echo -e "${YELLOW}Qube ${qube} not found, skipping${NC}"
        return
    fi

    echo -e "${BLUE}═══ ${qube} ═══${NC}"
    echo

    # Get network VM
    local netvm=$(qvm-prefs "${qube}" netvm 2>/dev/null || echo "")

    if [ -z "${netvm}" ]; then
        echo -e "${GREEN}Status: Air-gapped (NO NETWORK)${NC}"
        echo -e "Security Level: ${GREEN}MAXIMUM${NC}"
        echo
        return
    fi

    echo -e "Network VM: ${netvm}"
    echo

    # Get firewall rules
    local rules=$(qvm-firewall "${qube}" list 2>/dev/null || echo "ERROR")

    if [ "${rules}" = "ERROR" ]; then
        echo -e "${RED}ERROR: Cannot read firewall rules${NC}"
        echo
        return
    fi

    # Count rules
    local rule_count=$(echo "${rules}" | tail -n +2 | wc -l)

    echo -e "Rules: ${rule_count}"
    echo

    # Display rules
    echo "${rules}" | while IFS= read -r line; do
        if echo "${line}" | grep -q "^NO."; then
            # Header
            echo -e "${CYAN}${line}${NC}"
        elif echo "${line}" | grep -q "accept"; then
            # Accept rules in green
            echo -e "${GREEN}${line}${NC}"
        elif echo "${line}" | grep -q "drop"; then
            # Drop rules in yellow
            echo -e "${YELLOW}${line}${NC}"
        else
            echo "${line}"
        fi
    done

    echo

    # Security analysis
    echo -e "${BLUE}Security Analysis:${NC}"

    local has_accept=$(echo "${rules}" | grep -c "accept" || echo "0")
    local has_drop=$(echo "${rules}" | grep -c "drop" || echo "0")
    local has_dns=$(echo "${rules}" | grep -c "dstport=53" || echo "0")
    local has_http=$(echo "${rules}" | grep -c "dstport=80" || echo "0")
    local has_https=$(echo "${rules}" | grep -c "dstport=443" || echo "0")

    # Check for default deny
    if [ "${has_drop}" -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} Default deny policy (secure)"
    else
        echo -e "  ${YELLOW}!${NC} No explicit deny rule (may allow all)"
    fi

    # Check for DNS
    if [ "${has_dns}" -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} DNS allowed (port 53)"
    else
        echo -e "  ${YELLOW}!${NC} DNS not explicitly allowed"
    fi

    # Check for HTTP/HTTPS
    if [ "${has_http}" -gt 0 ] || [ "${has_https}" -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} Web access allowed"
    fi

    # Overall security level
    if [ "${has_drop}" -gt 0 ] && [ "${has_accept}" -le 5 ]; then
        echo -e "  Security Level: ${GREEN}HIGH${NC}"
    elif [ "${has_drop}" -gt 0 ]; then
        echo -e "  Security Level: ${YELLOW}MEDIUM${NC}"
    else
        echo -e "  Security Level: ${RED}LOW${NC}"
    fi

    echo
    echo -e "────────────────────────────────────────────────────────────────"
    echo
}

# Analyze all qubes
for qube in "${QUBES[@]}"; do
    analyze_qube "${qube}"
done

# Summary
echo -e "${BLUE}Summary:${NC}"
echo -e "────────────────────────────────────────────────────────────────"

QUBES_CHECKED=0
QUBES_SECURED=0
QUBES_AIRGAPPED=0

for qube in "${QUBES[@]}"; do
    if qvm-ls "${qube}" &>/dev/null; then
        QUBES_CHECKED=$((QUBES_CHECKED + 1))

        netvm=$(qvm-prefs "${qube}" netvm 2>/dev/null || echo "")

        if [ -z "${netvm}" ]; then
            QUBES_AIRGAPPED=$((QUBES_AIRGAPPED + 1))
        else
            rules=$(qvm-firewall "${qube}" list 2>/dev/null || echo "")
            has_drop=$(echo "${rules}" | grep -c "drop" || echo "0")

            if [ "${has_drop}" -gt 0 ]; then
                QUBES_SECURED=$((QUBES_SECURED + 1))
            fi
        fi
    fi
done

echo -e "Qubes checked:     ${QUBES_CHECKED}"
echo -e "Air-gapped qubes:  ${GREEN}${QUBES_AIRGAPPED}${NC}"
echo -e "Firewalled qubes:  ${GREEN}${QUBES_SECURED}${NC}"

echo -e "────────────────────────────────────────────────────────────────"
echo

# Recommendations
echo -e "${BLUE}Recommendations:${NC}"
echo

if [ "${QUBES_AIRGAPPED}" -eq 0 ]; then
    echo -e "${YELLOW}!${NC} Consider creating an air-gapped vault qube"
fi

# Check vault specifically
if qvm-ls vault &>/dev/null; then
    vault_netvm=$(qvm-prefs vault netvm 2>/dev/null || echo "ERROR")
    if [ -n "${vault_netvm}" ]; then
        echo -e "${RED}✗${NC} WARNING: vault has network access! Should be air-gapped"
        echo -e "  Fix: qvm-prefs vault netvm ''"
    fi
fi

# Check work firewall
if qvm-ls work &>/dev/null; then
    work_rules=$(qvm-firewall work list 2>/dev/null | tail -n +2 | wc -l)
    if [ "${work_rules}" -le 1 ]; then
        echo -e "${YELLOW}!${NC} work qube has minimal firewall rules"
        echo -e "  Consider restricting to HTTP/HTTPS/DNS only"
    fi
fi

echo

# Quick commands
echo -e "${BLUE}Quick Commands:${NC}"
echo -e "  Add HTTP rule:     qvm-firewall work add action=accept proto=tcp dstport=80"
echo -e "  Add HTTPS rule:    qvm-firewall work add action=accept proto=tcp dstport=443"
echo -e "  Add DNS rule:      qvm-firewall work add action=accept proto=udp dstport=53"
echo -e "  Add deny rule:     qvm-firewall work add action=drop"
echo -e "  Reset firewall:    qvm-firewall work reset"
echo -e "  Remove rule:       qvm-firewall work del --rule-no <number>"
echo
