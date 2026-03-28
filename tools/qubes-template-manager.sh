#!/bin/bash
# Qubes SDP Template Manager
# Manages templates used by SDP qubes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

COMMAND="${1:-status}"

usage() {
    cat << EOF
Qubes SDP Template Manager

Usage: $(basename "$0") [COMMAND]

Commands:
    status      Show template status (default)
    update      Update all templates
    install     Install missing templates
    clean       Clean package cache in templates
    list        List all installed templates
    info        Show detailed template information

Examples:
    $(basename "$0") status
    $(basename "$0") update
    $(basename "$0") install

EOF
}

# Check dom0
if [ "$(hostname)" != "dom0" ]; then
    echo -e "${RED}ERROR: Must run in dom0${NC}"
    exit 1
fi

# Header
show_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}           ${BLUE}Qubes SDP Template Manager${NC}                     ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Get template info
get_template_info() {
    local template=$1

    # Check if exists
    if ! qvm-ls "${template}" &>/dev/null; then
        echo "NOT_INSTALLED"
        return
    fi

    # Get size
    local size=$(qvm-ls "${template}" --raw-data --fields disk | tail -1 2>/dev/null || echo "0")

    # Convert to human readable
    if [ "${size}" -gt $((1024 * 1024 * 1024)) ]; then
        size="$((size / 1024 / 1024 / 1024))GB"
    elif [ "${size}" -gt $((1024 * 1024)) ]; then
        size="$((size / 1024 / 1024))MB"
    else
        size="$((size / 1024))KB"
    fi

    echo "INSTALLED:${size}"
}

# List templates
list_templates() {
    show_header
    echo -e "${BLUE}Installed Templates:${NC}"
    echo -e "────────────────────────────────────────────────────────────────"

    qvm-template list --installed | tail -n +2

    echo -e "────────────────────────────────────────────────────────────────"
    echo
}

# Show status
show_status() {
    show_header
    echo -e "${BLUE}Template Status:${NC}"
    echo -e "────────────────────────────────────────────────────────────────"

    # SDP templates
    local templates=("fedora-40-minimal" "debian-12-minimal" "whonix-gateway-17" "whonix-workstation-17")

    printf "%-30s %-15s %-10s\n" "TEMPLATE" "STATUS" "SIZE"
    echo -e "────────────────────────────────────────────────────────────────"

    for template in "${templates[@]}"; do
        local info=$(get_template_info "${template}")

        if [ "${info}" = "NOT_INSTALLED" ]; then
            printf "%-30s ${YELLOW}%-15s${NC} %-10s\n" "${template}" "Not Installed" "-"
        else
            local size=$(echo "${info}" | cut -d: -f2)
            printf "%-30s ${GREEN}%-15s${NC} %-10s\n" "${template}" "Installed" "${size}"
        fi
    done

    echo -e "────────────────────────────────────────────────────────────────"
    echo

    # Show which qubes use which templates
    echo -e "${BLUE}Template Usage:${NC}"
    echo -e "────────────────────────────────────────────────────────────────"

    local sdp_qubes=("work" "vault" "anon" "untrusted" "vpn")

    for qube in "${sdp_qubes[@]}"; do
        if qvm-ls "${qube}" &>/dev/null; then
            local template=$(qvm-prefs "${qube}" template 2>/dev/null || echo "N/A")
            printf "%-15s → %-30s\n" "${qube}" "${template}"
        fi
    done

    echo -e "────────────────────────────────────────────────────────────────"
    echo
}

# Update templates
update_templates() {
    show_header
    echo -e "${BLUE}Updating Templates:${NC}"
    echo

    local templates=($(qvm-ls --tags template --raw-list))

    for template in "${templates[@]}"; do
        echo -e "${CYAN}Updating ${template}...${NC}"

        # Determine package manager
        if qvm-run -p "${template}" 'command -v dnf' &>/dev/null; then
            # Fedora
            qvm-run -u root "${template}" 'dnf update -y' || \
                echo -e "${YELLOW}Warning: Update failed for ${template}${NC}"
        elif qvm-run -p "${template}" 'command -v apt-get' &>/dev/null; then
            # Debian
            qvm-run -u root "${template}" 'apt-get update && apt-get upgrade -y' || \
                echo -e "${YELLOW}Warning: Update failed for ${template}${NC}"
        else
            echo -e "${YELLOW}Unknown package manager for ${template}${NC}"
        fi

        echo -e "${GREEN}✓${NC} ${template} updated"
        echo
    done

    echo -e "${GREEN}All templates updated${NC}"
    echo
}

# Install missing templates
install_templates() {
    show_header
    echo -e "${BLUE}Installing Missing Templates:${NC}"
    echo

    local templates=("fedora-40-minimal" "debian-12-minimal")

    for template in "${templates[@]}"; do
        if ! qvm-ls "${template}" &>/dev/null; then
            echo -e "${CYAN}Installing ${template}...${NC}"

            if qubes-dom0-update --enablerepo=qubes-templates-itl -y "${template}"; then
                echo -e "${GREEN}✓${NC} ${template} installed"
            else
                echo -e "${RED}✗${NC} Failed to install ${template}"
            fi

            echo
        else
            echo -e "${GREEN}✓${NC} ${template} already installed"
        fi
    done

    echo -e "${GREEN}Installation complete${NC}"
    echo
}

# Clean package cache
clean_templates() {
    show_header
    echo -e "${BLUE}Cleaning Template Package Cache:${NC}"
    echo

    local templates=($(qvm-ls --tags template --raw-list))

    for template in "${templates[@]}"; do
        echo -e "${CYAN}Cleaning ${template}...${NC}"

        # Determine package manager and clean
        if qvm-run -p "${template}" 'command -v dnf' &>/dev/null; then
            qvm-run -u root "${template}" 'dnf clean all' || true
        elif qvm-run -p "${template}" 'command -v apt-get' &>/dev/null; then
            qvm-run -u root "${template}" 'apt-get clean && apt-get autoclean' || true
        fi

        echo -e "${GREEN}✓${NC} ${template} cleaned"
    done

    echo
    echo -e "${GREEN}Cache cleaning complete${NC}"
    echo
}

# Show detailed info
show_info() {
    show_header
    echo -e "${BLUE}Detailed Template Information:${NC}"
    echo

    local templates=($(qvm-ls --tags template --raw-list))

    for template in "${templates[@]}"; do
        echo -e "${CYAN}═══ ${template} ═══${NC}"
        echo

        # Size
        local size=$(qvm-ls "${template}" --raw-data --fields disk | tail -1 2>/dev/null || echo "0")
        size_gb=$((size / 1024 / 1024 / 1024))
        echo -e "Size:           ${size_gb}GB"

        # Template type
        if echo "${template}" | grep -q "minimal"; then
            echo -e "Type:           Minimal"
        else
            echo -e "Type:           Full"
        fi

        # Distro
        if echo "${template}" | grep -q "fedora"; then
            echo -e "Distribution:   Fedora"
        elif echo "${template}" | grep -q "debian"; then
            echo -e "Distribution:   Debian"
        elif echo "${template}" | grep -q "whonix"; then
            echo -e "Distribution:   Whonix (Debian-based)"
        else
            echo -e "Distribution:   Unknown"
        fi

        # Count qubes using this template
        local qube_count=$(qvm-ls --raw-data --fields template | grep -c "^${template}$" || echo "0")
        echo -e "Qubes using:    ${qube_count}"

        # Last update (approximate via volume modification time)
        echo

        echo -e "────────────────────────────────────────────────────────────────"
        echo
    done
}

# Main
case "${COMMAND}" in
    status)
        show_status
        ;;
    update)
        update_templates
        ;;
    install)
        install_templates
        ;;
    clean)
        clean_templates
        ;;
    list)
        list_templates
        ;;
    info)
        show_info
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        echo -e "${RED}Unknown command: ${COMMAND}${NC}"
        echo
        usage
        exit 1
        ;;
esac

# Recommendations
if [ "${COMMAND}" = "status" ]; then
    echo -e "${BLUE}Recommendations:${NC}"
    echo -e "  Update templates:   $(basename "$0") update"
    echo -e "  Clean cache:        $(basename "$0") clean"
    echo -e "  Install missing:    $(basename "$0") install"
    echo
fi
