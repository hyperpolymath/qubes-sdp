#!/bin/bash
# Qubes SDP Status Dashboard
# Shows comprehensive status of all SDP qubes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Header
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}           ${BLUE}Qubes SDP Status Dashboard${NC}                      ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo

# Check if running in dom0
if [ "$(hostname)" != "dom0" ]; then
    echo -e "${RED}ERROR: This script must be run in dom0${NC}"
    exit 1
fi

# SDP Qubes to check
SDP_QUBES=("work" "vault" "anon" "untrusted" "vpn" "sys-usb")

# Status symbols
RUNNING="${GREEN}●${NC}"
HALTED="${YELLOW}○${NC}"
MISSING="${RED}✗${NC}"

# Get qube status
get_qube_status() {
    local qube=$1

    if ! qvm-ls "${qube}" &>/dev/null; then
        echo "missing"
        return
    fi

    local state=$(qvm-ls "${qube}" --raw-data --fields state | tail -1)

    case "${state}" in
        Running)
            echo "running"
            ;;
        Halted)
            echo "halted"
            ;;
        Paused)
            echo "paused"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Get qube memory
get_qube_memory() {
    local qube=$1

    if ! qvm-ls "${qube}" &>/dev/null; then
        echo "N/A"
        return
    fi

    local mem=$(qvm-prefs "${qube}" memory 2>/dev/null || echo "N/A")
    local maxmem=$(qvm-prefs "${qube}" maxmem 2>/dev/null || echo "N/A")

    echo "${mem}MB / ${maxmem}MB"
}

# Get qube network
get_qube_network() {
    local qube=$1

    if ! qvm-ls "${qube}" &>/dev/null; then
        echo "N/A"
        return
    fi

    local netvm=$(qvm-prefs "${qube}" netvm 2>/dev/null || echo "none")

    if [ -z "${netvm}" ]; then
        echo "none (air-gapped)"
    else
        echo "${netvm}"
    fi
}

# Get qube label
get_qube_label() {
    local qube=$1

    if ! qvm-ls "${qube}" &>/dev/null; then
        echo "N/A"
        return
    fi

    qvm-prefs "${qube}" label 2>/dev/null || echo "N/A"
}

# Get qube disk usage
get_qube_disk() {
    local qube=$1

    if ! qvm-ls "${qube}" &>/dev/null; then
        echo "N/A"
        return
    fi

    local disk=$(qvm-ls "${qube}" --raw-data --fields disk | tail -1 || echo "0")

    # Convert to human readable
    if [ "${disk}" -gt $((1024 * 1024 * 1024)) ]; then
        echo "$((disk / 1024 / 1024 / 1024))GB"
    elif [ "${disk}" -gt $((1024 * 1024)) ]; then
        echo "$((disk / 1024 / 1024))MB"
    else
        echo "$((disk / 1024))KB"
    fi
}

# Print qube status row
print_qube_status() {
    local qube=$1
    local status=$(get_qube_status "${qube}")
    local memory=$(get_qube_memory "${qube}")
    local network=$(get_qube_network "${qube}")
    local label=$(get_qube_label "${qube}")
    local disk=$(get_qube_disk "${qube}")

    # Status symbol
    local symbol
    case "${status}" in
        running)
            symbol="${RUNNING}"
            ;;
        halted)
            symbol="${HALTED}"
            ;;
        missing)
            symbol="${MISSING}"
            ;;
        *)
            symbol="${YELLOW}?${NC}"
            ;;
    esac

    # Print row
    printf "%-4s %-15s %-12s %-20s %-25s %-10s\n" \
        "${symbol}" \
        "${qube}" \
        "${label}" \
        "${memory}" \
        "${network}" \
        "${disk}"
}

# Main display
echo -e "${BLUE}Qube Status:${NC}"
echo -e "────────────────────────────────────────────────────────────────────────────────"
printf "%-4s %-15s %-12s %-20s %-25s %-10s\n" \
    "" "QUBE" "LABEL" "MEMORY" "NETWORK" "DISK"
echo -e "────────────────────────────────────────────────────────────────────────────────"

for qube in "${SDP_QUBES[@]}"; do
    print_qube_status "${qube}"
done

echo -e "────────────────────────────────────────────────────────────────────────────────"
echo

# Legend
echo -e "${BLUE}Legend:${NC}"
echo -e "  ${RUNNING} Running   ${HALTED} Halted   ${MISSING} Not Created"
echo

# System Resources
echo -e "${BLUE}System Resources:${NC}"
echo -e "────────────────────────────────────────────────────────────────────────────────"

# Total memory
TOTAL_MEM=$(xl info | grep total_memory | awk '{print $3}')
FREE_MEM=$(xl info | grep free_memory | awk '{print $3}')
USED_MEM=$((TOTAL_MEM - FREE_MEM))
MEM_PERCENT=$((USED_MEM * 100 / TOTAL_MEM))

echo -e "Memory:      ${USED_MEM}MB / ${TOTAL_MEM}MB (${MEM_PERCENT}% used)"

# Disk space
DISK_INFO=$(df -h / | tail -1)
DISK_TOTAL=$(echo "${DISK_INFO}" | awk '{print $2}')
DISK_USED=$(echo "${DISK_INFO}" | awk '{print $3}')
DISK_AVAIL=$(echo "${DISK_INFO}" | awk '{print $4}')
DISK_PERCENT=$(echo "${DISK_INFO}" | awk '{print $5}')

echo -e "Disk:        ${DISK_USED} / ${DISK_TOTAL} (${DISK_PERCENT} used, ${DISK_AVAIL} available)"

# Running VMs
RUNNING_VMS=$(qvm-ls --running --raw-list | wc -l)
TOTAL_VMS=$(qvm-ls --raw-list | wc -l)

echo -e "VMs:         ${RUNNING_VMS} running / ${TOTAL_VMS} total"

echo -e "────────────────────────────────────────────────────────────────────────────────"
echo

# Security Checks
echo -e "${BLUE}Security Checks:${NC}"
echo -e "────────────────────────────────────────────────────────────────────────────────"

# Check vault network
if qvm-ls vault &>/dev/null; then
    VAULT_NETVM=$(qvm-prefs vault netvm 2>/dev/null || echo "error")
    if [ -z "${VAULT_NETVM}" ]; then
        echo -e "Vault air-gap:      ${GREEN}✓${NC} SECURE (no network)"
    else
        echo -e "Vault air-gap:      ${RED}✗${NC} WARNING: vault has network access!"
    fi
else
    echo -e "Vault air-gap:      ${YELLOW}?${NC} (vault not created)"
fi

# Check firewall on work
if qvm-ls work &>/dev/null; then
    FIREWALL_RULES=$(qvm-firewall work list 2>/dev/null | wc -l)
    if [ "${FIREWALL_RULES}" -gt 1 ]; then
        echo -e "Work firewall:      ${GREEN}✓${NC} ACTIVE (${FIREWALL_RULES} rules)"
    else
        echo -e "Work firewall:      ${YELLOW}!${NC} No custom rules"
    fi
else
    echo -e "Work firewall:      ${YELLOW}?${NC} (work not created)"
fi

# Check untrusted is DispVM template
if qvm-ls untrusted &>/dev/null; then
    IS_DISPVM=$(qvm-prefs untrusted template_for_dispvms 2>/dev/null || echo "False")
    if [ "${IS_DISPVM}" = "True" ]; then
        echo -e "Untrusted DispVM:   ${GREEN}✓${NC} CONFIGURED"
    else
        echo -e "Untrusted DispVM:   ${YELLOW}!${NC} Not configured as DispVM template"
    fi
else
    echo -e "Untrusted DispVM:   ${YELLOW}?${NC} (untrusted not created)"
fi

echo -e "────────────────────────────────────────────────────────────────────────────────"
echo

# Quick Actions
echo -e "${BLUE}Quick Actions:${NC}"
echo -e "  Start all:    qvm-start work vault anon"
echo -e "  Stop all:     qvm-shutdown work vault anon untrusted"
echo -e "  View logs:    less /var/log/qubes-sdp-setup.log"
echo -e "  Firewall:     qvm-firewall work list"
echo -e "  Backup:       make -f Makefile.qubes backup"
echo
