#!/bin/bash
# Qubes SDP Backup Validator
# Validates and manages Qubes backups

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

BACKUP_DIR="${1:-/var/backups/qubes-sdp}"

usage() {
    cat << EOF
Qubes SDP Backup Validator

Usage: $(basename "$0") [BACKUP_DIRECTORY]

Default backup directory: /var/backups/qubes-sdp

Actions:
    - List all backups
    - Verify backup integrity
    - Show backup contents
    - Check backup age
    - Recommend cleanup

Examples:
    $(basename "$0")
    $(basename "$0") /mnt/usb/backups

EOF
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

# Check dom0
if [ "$(hostname)" != "dom0" ]; then
    echo -e "${RED}ERROR: Must run in dom0${NC}"
    exit 1
fi

# Header
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}           ${BLUE}Qubes SDP Backup Validator${NC}                      ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${BLUE}Backup Directory:${NC} ${BACKUP_DIR}"
echo

# Check if directory exists
if [ ! -d "${BACKUP_DIR}" ]; then
    echo -e "${RED}ERROR: Backup directory does not exist${NC}"
    echo -e "Create it with: mkdir -p ${BACKUP_DIR}"
    exit 1
fi

# Find backups
echo -e "${BLUE}Scanning for backups...${NC}"
echo

BACKUPS=($(find "${BACKUP_DIR}" -maxdepth 1 -type f -name "backup-*" 2>/dev/null | sort -r))

if [ ${#BACKUPS[@]} -eq 0 ]; then
    echo -e "${YELLOW}No backups found in ${BACKUP_DIR}${NC}"
    echo
    echo -e "${BLUE}To create a backup:${NC}"
    echo -e "  qvm-backup work vault ${BACKUP_DIR}/backup-\$(date +%Y%m%d)"
    echo -e "  make -f Makefile.qubes backup"
    echo
    exit 0
fi

echo -e "${GREEN}Found ${#BACKUPS[@]} backup(s)${NC}"
echo

# List backups
echo -e "${BLUE}Backups:${NC}"
echo -e "────────────────────────────────────────────────────────────────────────────────"
printf "%-4s %-30s %-12s %-15s %-10s\n" "NO." "FILENAME" "SIZE" "DATE" "AGE"
echo -e "────────────────────────────────────────────────────────────────────────────────"

INDEX=1
for backup in "${BACKUPS[@]}"; do
    FILENAME=$(basename "${backup}")
    SIZE=$(du -h "${backup}" 2>/dev/null | cut -f1 || echo "?")
    MTIME=$(stat -c %Y "${backup}" 2>/dev/null || echo "0")
    DATE=$(date -d "@${MTIME}" +"%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown")

    # Calculate age in days
    NOW=$(date +%s)
    AGE_SECONDS=$((NOW - MTIME))
    AGE_DAYS=$((AGE_SECONDS / 86400))

    # Color code age
    if [ ${AGE_DAYS} -lt 7 ]; then
        AGE_COLOR="${GREEN}"
    elif [ ${AGE_DAYS} -lt 30 ]; then
        AGE_COLOR="${YELLOW}"
    else
        AGE_COLOR="${RED}"
    fi

    printf "%-4s %-30s %-12s %-15s ${AGE_COLOR}%-10s${NC}\n" \
        "${INDEX}" "${FILENAME}" "${SIZE}" "${DATE}" "${AGE_DAYS}d"

    INDEX=$((INDEX + 1))
done

echo -e "────────────────────────────────────────────────────────────────────────────────"
echo

# Verify most recent backup
LATEST_BACKUP="${BACKUPS[0]}"
echo -e "${BLUE}Verifying latest backup:${NC} $(basename "${LATEST_BACKUP}")"
echo

# List contents
echo -e "${CYAN}Listing backup contents...${NC}"
if qvm-backup-restore --list "${LATEST_BACKUP}" 2>&1; then
    VERIFY_LIST="OK"
else
    VERIFY_LIST="FAIL"
    echo -e "${RED}✗${NC} Failed to list backup contents"
fi
echo

# Verify integrity
echo -e "${CYAN}Verifying backup integrity...${NC}"
if qvm-backup-restore --verify "${LATEST_BACKUP}" 2>&1 | grep -q "VERIFICATION OK"; then
    VERIFY_INTEGRITY="OK"
    echo -e "${GREEN}✓${NC} Backup integrity verified"
else
    VERIFY_INTEGRITY="FAIL"
    echo -e "${RED}✗${NC} Backup integrity check failed"
fi
echo

# Summary
echo -e "${BLUE}Validation Summary:${NC}"
echo -e "────────────────────────────────────────────────────────────────"

echo -e "Total backups:      ${#BACKUPS[@]}"
echo -e "Latest backup:      $(basename "${LATEST_BACKUP}")"

LATEST_SIZE=$(du -h "${LATEST_BACKUP}" | cut -f1)
echo -e "Latest size:        ${LATEST_SIZE}"

if [ "${VERIFY_LIST}" = "OK" ]; then
    echo -e "Content listing:    ${GREEN}✓ OK${NC}"
else
    echo -e "Content listing:    ${RED}✗ FAILED${NC}"
fi

if [ "${VERIFY_INTEGRITY}" = "OK" ]; then
    echo -e "Integrity check:    ${GREEN}✓ OK${NC}"
else
    echo -e "Integrity check:    ${RED}✗ FAILED${NC}"
fi

echo -e "────────────────────────────────────────────────────────────────"
echo

# Recommendations
echo -e "${BLUE}Recommendations:${NC}"
echo

# Check backup age
LATEST_MTIME=$(stat -c %Y "${LATEST_BACKUP}")
NOW=$(date +%s)
AGE_SECONDS=$((NOW - LATEST_MTIME))
AGE_DAYS=$((AGE_SECONDS / 86400))

if [ ${AGE_DAYS} -gt 7 ]; then
    echo -e "${YELLOW}!${NC} Latest backup is ${AGE_DAYS} days old"
    echo -e "  Consider creating a new backup"
fi

# Check for old backups
OLD_BACKUPS=0
for backup in "${BACKUPS[@]}"; do
    MTIME=$(stat -c %Y "${backup}")
    AGE_SECONDS=$((NOW - MTIME))
    AGE_DAYS=$((AGE_SECONDS / 86400))

    if [ ${AGE_DAYS} -gt 30 ]; then
        OLD_BACKUPS=$((OLD_BACKUPS + 1))
    fi
done

if [ ${OLD_BACKUPS} -gt 0 ]; then
    echo -e "${YELLOW}!${NC} ${OLD_BACKUPS} backup(s) older than 30 days"
    echo -e "  Consider cleanup to save space"
fi

# Check total size
TOTAL_SIZE=$(du -sh "${BACKUP_DIR}" 2>/dev/null | cut -f1 || echo "?")
echo -e "${BLUE}ℹ${NC} Total backup size: ${TOTAL_SIZE}"

# Check available space
AVAIL_SPACE=$(df -h "${BACKUP_DIR}" | tail -1 | awk '{print $4}')
echo -e "${BLUE}ℹ${NC} Available space: ${AVAIL_SPACE}"

echo

# Backup schedule recommendation
echo -e "${BLUE}Backup Best Practices:${NC}"
echo -e "  • Keep 7 daily backups"
echo -e "  • Keep 4 weekly backups (monthly recommended)"
echo -e "  • Store one backup offsite"
echo -e "  • Test restore quarterly"
echo -e "  • Verify backup integrity monthly"
echo

# Quick commands
echo -e "${BLUE}Quick Commands:${NC}"
echo -e "  Create backup:      make -f Makefile.qubes backup"
echo -e "  Restore backup:     qvm-backup-restore ${LATEST_BACKUP}"
echo -e "  Verify backup:      qvm-backup-restore --verify ${LATEST_BACKUP}"
echo -e "  List contents:      qvm-backup-restore --list ${LATEST_BACKUP}"
echo -e "  Clean old backups:  find ${BACKUP_DIR} -name 'backup-*' -mtime +30 -delete"
echo
