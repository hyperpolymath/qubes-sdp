#!/bin/bash
# Qubes SDP Disaster Recovery and Restore Tool
# Comprehensive restore from backup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

BACKUP_PATH="${1}"

usage() {
    cat << EOF
Qubes SDP Disaster Recovery & Restore Tool

Usage: $(basename "$0") [BACKUP_PATH]

This tool provides guided restoration from backups.

Examples:
    $(basename "$0") /var/backups/qubes-sdp/backup-20240101
    $(basename "$0") /mnt/usb/backup-latest

EOF
}

if [ -z "${BACKUP_PATH}" ]; then
    usage
    exit 1
fi

# Check dom0
if [ "$(hostname)" != "dom0" ]; then
    echo -e "${RED}ERROR: Must run in dom0${NC}"
    exit 1
fi

# Header
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}      ${BLUE}Qubes SDP Disaster Recovery & Restore Tool${NC}           ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo

# Check if backup exists
if [ ! -f "${BACKUP_PATH}" ]; then
    echo -e "${RED}ERROR: Backup file not found: ${BACKUP_PATH}${NC}"
    exit 1
fi

echo -e "${BLUE}Backup file:${NC} ${BACKUP_PATH}"
echo

# Step 1: Verify backup
echo -e "${BLUE}Step 1: Verifying backup integrity...${NC}"
echo

if qvm-backup-restore --verify "${BACKUP_PATH}"; then
    echo -e "${GREEN}✓${NC} Backup integrity verified"
else
    echo -e "${RED}✗${NC} Backup verification failed"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo

# Step 2: List backup contents
echo -e "${BLUE}Step 2: Backup contents:${NC}"
echo

QUBES_IN_BACKUP=$(qvm-backup-restore --list "${BACKUP_PATH}" 2>&1 | grep -v "^Checking" | grep -v "^VERIFICATION" | tail -n +2 || true)

echo "${QUBES_IN_BACKUP}"
echo

# Step 3: Check for conflicts
echo -e "${BLUE}Step 3: Checking for conflicts...${NC}"
echo

CONFLICTS=()

while IFS= read -r qube; do
    # Skip empty lines
    [ -z "${qube}" ] && continue

    # Extract qube name (first column)
    qube_name=$(echo "${qube}" | awk '{print $1}')

    # Check if qube exists
    if qvm-ls "${qube_name}" &>/dev/null; then
        CONFLICTS+=("${qube_name}")
        echo -e "${YELLOW}!${NC} Qube already exists: ${qube_name}"
    fi
done <<< "${QUBES_IN_BACKUP}"

if [ ${#CONFLICTS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓${NC} No conflicts found"
else
    echo
    echo -e "${YELLOW}Conflicting qubes found: ${#CONFLICTS[@]}${NC}"
    echo
    echo "Options:"
    echo "  1. Restore with rename (recommended)"
    echo "  2. Remove existing qubes (DESTRUCTIVE)"
    echo "  3. Skip conflicting qubes"
    echo "  4. Abort"
    echo
    read -p "Choose option [1-4]: " -n 1 -r option
    echo

    case "${option}" in
        1)
            RESTORE_MODE="rename"
            ;;
        2)
            echo -e "${RED}WARNING: This will remove existing qubes!${NC}"
            read -p "Are you sure? Type 'yes' to confirm: " confirm
            if [ "${confirm}" != "yes" ]; then
                echo "Aborted"
                exit 1
            fi

            # Remove conflicting qubes
            for qube in "${CONFLICTS[@]}"; do
                echo -e "${YELLOW}Removing ${qube}...${NC}"
                qvm-remove -f "${qube}"
            done

            RESTORE_MODE="replace"
            ;;
        3)
            RESTORE_MODE="skip"
            ;;
        4|*)
            echo "Aborted"
            exit 0
            ;;
    esac
fi

echo

# Step 4: Perform restore
echo -e "${BLUE}Step 4: Performing restore...${NC}"
echo

RESTORE_CMD="qvm-backup-restore"

if [ "${RESTORE_MODE}" = "rename" ]; then
    # Build rename arguments
    RENAME_ARGS=""
    for qube in "${CONFLICTS[@]}"; do
        RENAME_ARGS="${RENAME_ARGS} --rename ${qube}:${qube}-restored"
    done

    RESTORE_CMD="${RESTORE_CMD} ${RENAME_ARGS}"
    echo -e "${CYAN}Conflicting qubes will be restored with '-restored' suffix${NC}"
    echo
elif [ "${RESTORE_MODE}" = "skip" ]; then
    # Build exclude arguments
    EXCLUDE_ARGS=""
    for qube in "${CONFLICTS[@]}"; do
        EXCLUDE_ARGS="${EXCLUDE_ARGS} --exclude ${qube}"
    done

    RESTORE_CMD="${RESTORE_CMD} ${EXCLUDE_ARGS}"
    echo -e "${CYAN}Conflicting qubes will be skipped${NC}"
    echo
fi

RESTORE_CMD="${RESTORE_CMD} ${BACKUP_PATH}"

echo -e "${CYAN}Restore command:${NC} ${RESTORE_CMD}"
echo

read -p "Proceed with restore? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled"
    exit 0
fi

# Execute restore
if ${RESTORE_CMD}; then
    echo
    echo -e "${GREEN}✓${NC} Restore completed successfully"
else
    echo
    echo -e "${RED}✗${NC} Restore failed"
    exit 1
fi

echo

# Step 5: Verify restored qubes
echo -e "${BLUE}Step 5: Verifying restored qubes...${NC}"
echo

while IFS= read -r qube; do
    [ -z "${qube}" ] && continue

    qube_name=$(echo "${qube}" | awk '{print $1}')

    # Check if renamed
    if [ "${RESTORE_MODE}" = "rename" ] && [[ " ${CONFLICTS[@]} " =~ " ${qube_name} " ]]; then
        qube_name="${qube_name}-restored"
    fi

    # Skip if excluded
    if [ "${RESTORE_MODE}" = "skip" ] && [[ " ${CONFLICTS[@]} " =~ " ${qube_name} " ]]; then
        continue
    fi

    if qvm-ls "${qube_name}" &>/dev/null; then
        echo -e "${GREEN}✓${NC} ${qube_name} restored"
    else
        echo -e "${RED}✗${NC} ${qube_name} not found"
    fi
done <<< "${QUBES_IN_BACKUP}"

echo

# Step 6: Post-restore recommendations
echo -e "${BLUE}Step 6: Post-Restore Recommendations:${NC}"
echo -e "────────────────────────────────────────────────────────────────"

echo -e "1. ${YELLOW}Verify qube configurations${NC}"
echo -e "   qvm-prefs <qube>"

echo -e "2. ${YELLOW}Check firewall rules${NC}"
echo -e "   qvm-firewall work list"

echo -e "3. ${YELLOW}Verify vault has no network${NC}"
echo -e "   qvm-prefs vault netvm"

echo -e "4. ${YELLOW}Test qube functionality${NC}"
echo -e "   qvm-start <qube>"

echo -e "5. ${YELLOW}Update templates${NC}"
echo -e "   make -f Makefile.qubes template-update"

echo -e "6. ${YELLOW}Run health check${NC}"
echo -e "   bash tools/qubes-status.sh"

echo -e "────────────────────────────────────────────────────────────────"
echo

echo -e "${GREEN}Disaster recovery completed!${NC}"
echo
