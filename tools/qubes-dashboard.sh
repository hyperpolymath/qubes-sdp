#!/bin/bash
# Qubes SDP Interactive Dashboard
# Real-time monitoring of SDP qubes

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check dom0
if [ "$(hostname)" != "dom0" ]; then
    echo -e "${RED}ERROR: Must run in dom0${NC}"
    exit 1
fi

# Refresh function
refresh_dashboard() {
    clear

    # Header
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${BLUE}Qubes SDP Live Dashboard${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                    $(date '+%Y-%m-%d %H:%M:%S')                                ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo

    # System Resources
    TOTAL_MEM=$(xl info | grep total_memory | awk '{print $3}')
    FREE_MEM=$(xl info | grep free_memory | awk '{print $3}')
    USED_MEM=$((TOTAL_MEM - FREE_MEM))
    MEM_PERCENT=$((USED_MEM * 100 / TOTAL_MEM))

    echo -e "${BLUE}System Resources:${NC}"
    echo -e "────────────────────────────────────────────────────────────────────────────────"

    # Memory bar
    printf "Memory:  "
    FILLED=$((MEM_PERCENT / 2))
    EMPTY=$((50 - FILLED))

    if [ ${MEM_PERCENT} -lt 60 ]; then
        COLOR="${GREEN}"
    elif [ ${MEM_PERCENT} -lt 80 ]; then
        COLOR="${YELLOW}"
    else
        COLOR="${RED}"
    fi

    printf "${COLOR}"
    printf "%${FILLED}s" | tr ' ' '█'
    printf "${NC}"
    printf "%${EMPTY}s" | tr ' ' '░'
    printf " %3d%% (%dMB / %dMB)\n" "${MEM_PERCENT}" "${USED_MEM}" "${TOTAL_MEM}"

    # Disk usage
    DISK_INFO=$(df -h / | tail -1)
    DISK_USED=$(echo "${DISK_INFO}" | awk '{print $3}')
    DISK_TOTAL=$(echo "${DISK_INFO}" | awk '{print $2}')
    DISK_PERCENT=$(echo "${DISK_INFO}" | awk '{print $5}' | tr -d '%')

    printf "Disk:    "
    FILLED=$((DISK_PERCENT / 2))
    EMPTY=$((50 - FILLED))

    if [ ${DISK_PERCENT} -lt 60 ]; then
        COLOR="${GREEN}"
    elif [ ${DISK_PERCENT} -lt 80 ]; then
        COLOR="${YELLOW}"
    else
        COLOR="${RED}"
    fi

    printf "${COLOR}"
    printf "%${FILLED}s" | tr ' ' '█'
    printf "${NC}"
    printf "%${EMPTY}s" | tr ' ' '░'
    printf " %3d%% (%s / %s)\n" "${DISK_PERCENT}" "${DISK_USED}" "${DISK_TOTAL}"

    echo -e "────────────────────────────────────────────────────────────────────────────────"
    echo

    # Qube Status
    echo -e "${BLUE}Qube Status:${NC}"
    echo -e "────────────────────────────────────────────────────────────────────────────────"

    SDP_QUBES=("work" "vault" "anon" "untrusted" "vpn" "sys-usb")

    for qube in "${SDP_QUBES[@]}"; do
        if ! qvm-ls "${qube}" &>/dev/null; then
            continue
        fi

        # Get qube info
        STATE=$(qvm-ls "${qube}" --raw-data --fields state | tail -1)
        LABEL=$(qvm-prefs "${qube}" label 2>/dev/null || echo "")
        MEM=$(qvm-prefs "${qube}" memory 2>/dev/null || echo "0")
        NETVM=$(qvm-prefs "${qube}" netvm 2>/dev/null || echo "")

        # Status symbol and color
        case "${STATE}" in
            Running)
                STATUS="${GREEN}●${NC}"
                STATE_TEXT="${GREEN}Running${NC}"
                ;;
            Halted)
                STATUS="${YELLOW}○${NC}"
                STATE_TEXT="${YELLOW}Halted${NC}"
                ;;
            *)
                STATUS="${RED}?${NC}"
                STATE_TEXT="${RED}${STATE}${NC}"
                ;;
        esac

        # Network indicator
        if [ -z "${NETVM}" ]; then
            NET_INDICATOR="${GREEN}[AIR-GAP]${NC}"
        else
            NET_INDICATOR="[${NETVM}]"
        fi

        printf "%s %-15s %-20s %4dMB  %s\n" \
            "${STATUS}" "${qube}" "${STATE_TEXT}" "${MEM}" "${NET_INDICATOR}"
    done

    echo -e "────────────────────────────────────────────────────────────────────────────────"
    echo

    # Security Status
    echo -e "${BLUE}Security Status:${NC}"
    echo -e "────────────────────────────────────────────────────────────────────────────────"

    # Vault air-gap check
    if qvm-ls vault &>/dev/null; then
        VAULT_NETVM=$(qvm-prefs vault netvm 2>/dev/null || echo "ERROR")
        if [ -z "${VAULT_NETVM}" ]; then
            echo -e "${GREEN}✓${NC} Vault is air-gapped (secure)"
        else
            echo -e "${RED}✗${NC} WARNING: Vault has network access!"
        fi
    fi

    # Firewall check
    if qvm-ls work &>/dev/null; then
        WORK_RUNNING=$(qvm-ls work --raw-data --fields state | tail -1)
        FIREWALL_RULES=$(qvm-firewall work list 2>/dev/null | tail -n +2 | wc -l)
        if [ "${FIREWALL_RULES}" -gt 0 ]; then
            echo -e "${GREEN}✓${NC} Work qube has ${FIREWALL_RULES} firewall rules"
        else
            echo -e "${YELLOW}!${NC} Work qube has no firewall rules"
        fi
    fi

    # DispVM check
    if qvm-ls untrusted &>/dev/null; then
        IS_DISPVM=$(qvm-prefs untrusted template_for_dispvms 2>/dev/null || echo "False")
        if [ "${IS_DISPVM}" = "True" ]; then
            echo -e "${GREEN}✓${NC} Untrusted configured as DispVM template"
        else
            echo -e "${YELLOW}!${NC} Untrusted not configured as DispVM"
        fi
    fi

    echo -e "────────────────────────────────────────────────────────────────────────────────"
    echo

    # Recent Activity
    echo -e "${BLUE}Recent Activity (last 5 log entries):${NC}"
    echo -e "────────────────────────────────────────────────────────────────────────────────"

    if [ -f /var/log/qubes-sdp-setup.log ]; then
        tail -5 /var/log/qubes-sdp-setup.log | while IFS= read -r line; do
            echo "  ${line}"
        done
    else
        echo "  No recent activity"
    fi

    echo -e "────────────────────────────────────────────────────────────────────────────────"
    echo

    # Commands
    echo -e "${BLUE}Commands:${NC} [r]efresh  [s]tatus  [f]irewall  [b]ackup  [q]uit"
    echo -n "> "
}

# Main loop
while true; do
    refresh_dashboard

    # Read command with timeout
    read -t 5 -n 1 cmd || cmd="r"

    case "${cmd}" in
        r|R)
            # Refresh (default)
            continue
            ;;
        s|S)
            # Run status script
            clear
            bash "$(dirname "$0")/qubes-status.sh" || true
            read -p "Press Enter to return to dashboard..."
            ;;
        f|F)
            # Run firewall analyzer
            clear
            bash "$(dirname "$0")/qubes-firewall-analyzer.sh" || true
            read -p "Press Enter to return to dashboard..."
            ;;
        b|B)
            # Show backup info
            clear
            bash "$(dirname "$0")/qubes-backup-validator.sh" || true
            read -p "Press Enter to return to dashboard..."
            ;;
        q|Q)
            # Quit
            echo
            echo "Goodbye!"
            exit 0
            ;;
        *)
            # Refresh on any other key
            continue
            ;;
    esac
done
