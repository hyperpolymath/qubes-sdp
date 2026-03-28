#!/bin/bash
# Qubes OS Simple Setup Script
# This is a standalone script for basic qube topology setup
# For advanced features, use qubes-setup-advanced.sh with qubes-config.conf

set -e  # Exit on error

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Qube configurations (name:label:memory:netvm:template)
QUBES_CONFIG=(
    "work:green:2048:sys-firewall:fedora-40-minimal"
    "vault:black:1024::fedora-40-minimal"
    "anon:purple:1024:sys-whonix:fedora-40-minimal"
    "untrusted:red:1024:sys-firewall:fedora-40-minimal"
)

# Firewall rules for work qube (protocol:port)
WORK_FIREWALL_RULES=(
    "tcp:80"    # HTTP
    "tcp:443"   # HTTPS
    "udp:53"    # DNS
)

# Script settings
VERBOSE=true
DRY_RUN=false
LOG_FILE="/var/log/qubes-sdp-setup.log"

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Write to log file
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"

    # Print to console if verbose
    if [ "${VERBOSE}" = true ]; then
        case "${level}" in
            INFO)
                echo -e "${BLUE}[INFO]${NC} ${message}"
                ;;
            SUCCESS)
                echo -e "${GREEN}[SUCCESS]${NC} ${message}"
                ;;
            WARNING)
                echo -e "${YELLOW}[WARNING]${NC} ${message}"
                ;;
            ERROR)
                echo -e "${RED}[ERROR]${NC} ${message}"
                ;;
            *)
                echo "[${level}] ${message}"
                ;;
        esac
    fi
}

# Error handler
error_exit() {
    log ERROR "$1"
    exit 1
}

# Check if running in dom0
check_dom0() {
    if [ "$(hostname)" != "dom0" ]; then
        error_exit "This script must be run in dom0"
    fi
    log INFO "Running in dom0 - OK"
}

# Check if qube exists
qube_exists() {
    local qube_name=$1
    qvm-ls "${qube_name}" &>/dev/null
}

# Check if template exists
template_exists() {
    local template=$1
    qvm-ls --raw-list | grep -q "^${template}$"
}

# Execute or dry-run
execute() {
    local cmd="$*"
    if [ "${DRY_RUN}" = true ]; then
        log INFO "[DRY-RUN] Would execute: ${cmd}"
    else
        log INFO "Executing: ${cmd}"
        eval "${cmd}" || error_exit "Command failed: ${cmd}"
    fi
}

# ==============================================================================
# PRE-FLIGHT CHECKS
# ==============================================================================

preflight_checks() {
    log INFO "Starting pre-flight checks..."

    # Check if in dom0
    check_dom0

    # Check if qvm-* commands available
    if ! command -v qvm-create &>/dev/null; then
        error_exit "qvm-create not found. Are you running Qubes OS?"
    fi

    # Check for required templates
    local templates_needed=()
    for config in "${QUBES_CONFIG[@]}"; do
        IFS=':' read -r name label memory netvm template <<< "${config}"
        templates_needed+=("${template}")
    done

    # Unique templates
    templates_needed=($(echo "${templates_needed[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

    for template in "${templates_needed[@]}"; do
        if ! template_exists "${template}"; then
            log WARNING "Template ${template} not found"
            if [ "${DRY_RUN}" = false ]; then
                read -p "Install ${template}? (y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    log INFO "Installing template ${template}..."
                    execute "qubes-dom0-update --enablerepo=qubes-templates-itl ${template}"
                else
                    error_exit "Required template ${template} not available"
                fi
            fi
        else
            log SUCCESS "Template ${template} found"
        fi
    done

    log SUCCESS "Pre-flight checks completed"
}

# ==============================================================================
# QUBE CREATION FUNCTIONS
# ==============================================================================

create_qube() {
    local name=$1
    local label=$2
    local memory=$3
    local netvm=$4
    local template=$5

    log INFO "Processing qube: ${name}"

    # Check if qube already exists
    if qube_exists "${name}"; then
        log WARNING "Qube ${name} already exists, skipping creation"
        return 0
    fi

    # Check if netvm is available (if specified)
    if [ -n "${netvm}" ]; then
        if ! qube_exists "${netvm}"; then
            log WARNING "Network qube ${netvm} not found"
            if [ "${netvm}" = "sys-whonix" ]; then
                log INFO "Falling back to sys-firewall for ${name}"
                netvm="sys-firewall"
            else
                error_exit "Required network qube ${netvm} not found"
            fi
        fi
    fi

    # Create qube
    local create_cmd="qvm-create --label ${label} --template ${template}"
    if [ -n "${netvm}" ]; then
        create_cmd="${create_cmd} ${name}"
    else
        create_cmd="${create_cmd} --property netvm='' ${name}"
    fi

    execute "${create_cmd}"

    # Set memory
    execute "qvm-prefs ${name} memory ${memory}"

    # Set network if specified
    if [ -n "${netvm}" ]; then
        execute "qvm-prefs ${name} netvm ${netvm}"
    fi

    log SUCCESS "Qube ${name} created successfully"
}

# Configure firewall for work qube
configure_work_firewall() {
    local qube_name="work"

    if ! qube_exists "${qube_name}"; then
        log WARNING "Qube ${qube_name} does not exist, skipping firewall configuration"
        return 0
    fi

    log INFO "Configuring firewall for ${qube_name}"

    # Set default deny policy
    execute "qvm-firewall ${qube_name} reset"
    execute "qvm-firewall ${qube_name} del --rule-no 0"

    # Add allowed rules
    for rule in "${WORK_FIREWALL_RULES[@]}"; do
        IFS=':' read -r proto port <<< "${rule}"
        execute "qvm-firewall ${qube_name} add action=accept proto=${proto} dstport=${port}"
    done

    # Add final deny rule
    execute "qvm-firewall ${qube_name} add action=drop"

    log SUCCESS "Firewall configured for ${qube_name}"
}

# Configure untrusted as DispVM template
configure_untrusted_dispvm() {
    local qube_name="untrusted"

    if ! qube_exists "${qube_name}"; then
        log WARNING "Qube ${qube_name} does not exist, skipping DispVM configuration"
        return 0
    fi

    log INFO "Configuring ${qube_name} as DispVM template"

    execute "qvm-prefs ${qube_name} template_for_dispvms True"

    log SUCCESS "${qube_name} configured as DispVM template"
}

# ==============================================================================
# MAIN SETUP FUNCTION
# ==============================================================================

setup_qubes() {
    log INFO "Starting Qubes OS setup..."

    # Create each qube
    for config in "${QUBES_CONFIG[@]}"; do
        IFS=':' read -r name label memory netvm template <<< "${config}"
        create_qube "${name}" "${label}" "${memory}" "${netvm}" "${template}"
    done

    # Configure firewall
    configure_work_firewall

    # Configure DispVM
    configure_untrusted_dispvm

    log SUCCESS "Qubes OS setup completed successfully!"
}

# ==============================================================================
# VALIDATION FUNCTIONS
# ==============================================================================

validate_setup() {
    log INFO "Validating setup..."

    local all_ok=true

    for config in "${QUBES_CONFIG[@]}"; do
        IFS=':' read -r name label memory netvm template <<< "${config}"

        if qube_exists "${name}"; then
            log SUCCESS "Qube ${name} exists"

            # Validate properties
            local actual_memory=$(qvm-prefs "${name}" memory)
            local actual_label=$(qvm-prefs "${name}" label)
            local actual_netvm=$(qvm-prefs "${name}" netvm)

            if [ "${actual_memory}" != "${memory}" ]; then
                log WARNING "Memory mismatch for ${name}: expected ${memory}, got ${actual_memory}"
                all_ok=false
            fi

            if [ "${actual_label}" != "${label}" ]; then
                log WARNING "Label mismatch for ${name}: expected ${label}, got ${actual_label}"
                all_ok=false
            fi

            # Check netvm (handle empty case for vault)
            if [ -n "${netvm}" ]; then
                if [ "${actual_netvm}" != "${netvm}" ]; then
                    log WARNING "NetVM mismatch for ${name}: expected ${netvm}, got ${actual_netvm}"
                    all_ok=false
                fi
            else
                if [ -n "${actual_netvm}" ]; then
                    log WARNING "NetVM should be empty for ${name}, got ${actual_netvm}"
                    all_ok=false
                fi
            fi
        else
            log ERROR "Qube ${name} does not exist"
            all_ok=false
        fi
    done

    if [ "${all_ok}" = true ]; then
        log SUCCESS "Validation completed successfully"
    else
        log WARNING "Validation completed with warnings/errors"
    fi

    return 0
}

# ==============================================================================
# USAGE INFORMATION
# ==============================================================================

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Qubes OS Simple Setup Script
Creates a basic qube topology for secure workflows.

Options:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output (default: enabled)
    -q, --quiet         Disable verbose output
    -d, --dry-run       Perform a dry run without making changes
    -V, --validate      Validate existing setup
    --no-log            Disable logging to file

Examples:
    $0                  # Run normal setup
    $0 --dry-run        # Test what would be done
    $0 --validate       # Check existing setup

Qubes Created:
    work        - General work qube (green, 2GB RAM, firewall restricted)
    vault       - Air-gapped sensitive data storage (black, 1GB RAM, NO NETWORK)
    anon        - Anonymous communications via Tor (purple, 1GB RAM, sys-whonix)
    untrusted   - Risky downloads and testing (red, 1GB RAM, DispVM template)

For advanced features, use qubes-setup-advanced.sh with qubes-config.conf

EOF
}

# ==============================================================================
# COMMAND LINE PARSING
# ==============================================================================

VALIDATE_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quiet)
            VERBOSE=false
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            log INFO "DRY RUN MODE ENABLED"
            shift
            ;;
        -V|--validate)
            VALIDATE_ONLY=true
            shift
            ;;
        --no-log)
            LOG_FILE="/dev/null"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

main() {
    # Initialize log file
    if [ "${LOG_FILE}" != "/dev/null" ]; then
        touch "${LOG_FILE}" 2>/dev/null || LOG_FILE="/tmp/qubes-sdp-setup.log"
        log INFO "=== Qubes SDP Setup Script Started ==="
        log INFO "Log file: ${LOG_FILE}"
    fi

    if [ "${VALIDATE_ONLY}" = true ]; then
        validate_setup
    else
        preflight_checks
        setup_qubes
        validate_setup
    fi

    log INFO "=== Script completed ==="

    if [ "${DRY_RUN}" = true ]; then
        echo -e "\n${YELLOW}NOTE: This was a dry run. No changes were made.${NC}"
        echo -e "Run without --dry-run to apply changes.\n"
    else
        echo -e "\n${GREEN}Setup complete!${NC}"
        echo -e "Check the log file for details: ${LOG_FILE}\n"
    fi
}

# Run main function
main
