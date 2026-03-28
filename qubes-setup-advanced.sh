#!/bin/bash
# Qubes OS Advanced Setup Script
# Configuration-driven setup with advanced features
# Reads configuration from qubes-config.conf

set -e  # Exit on error
set -o pipefail  # Catch errors in pipes

# ==============================================================================
# CONSTANTS AND GLOBALS
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/qubes-config.conf"
LOG_FILE="/var/log/qubes-sdp-setup.log"
STATE_FILE="/var/run/qubes-sdp-state.json"
ROLLBACK_FILE="/var/run/qubes-sdp-rollback.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Track created qubes for rollback
CREATED_QUBES=()
MODIFIED_QUBES=()

# ==============================================================================
# LOGGING AND OUTPUT
# ==============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"

    if [ "${VERBOSE:-true}" = "true" ]; then
        case "${level}" in
            INFO)     echo -e "${BLUE}[INFO]${NC} ${message}" ;;
            SUCCESS)  echo -e "${GREEN}[✓]${NC} ${message}" ;;
            WARNING)  echo -e "${YELLOW}[⚠]${NC} ${message}" ;;
            ERROR)    echo -e "${RED}[✗]${NC} ${message}" ;;
            STEP)     echo -e "${CYAN}[→]${NC} ${message}" ;;
            *)        echo "[${level}] ${message}" ;;
        esac
    fi
}

progress() {
    local current=$1
    local total=$2
    local task=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))

    printf "\r${CYAN}[%3d%%]${NC} [" "${percent}"
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "] ${task}"

    if [ "${current}" -eq "${total}" ]; then
        echo
    fi
}

error_exit() {
    log ERROR "$1"
    if [ "${DRY_RUN:-false}" = "false" ]; then
        log INFO "Initiating rollback..."
        rollback_changes
    fi
    exit 1
}

# ==============================================================================
# CONFIGURATION LOADING
# ==============================================================================

load_config() {
    if [ ! -f "${CONFIG_FILE}" ]; then
        error_exit "Configuration file not found: ${CONFIG_FILE}"
    fi

    log INFO "Loading configuration from ${CONFIG_FILE}"

    # Source the config file
    # shellcheck source=/dev/null
    source "${CONFIG_FILE}"

    # Set global variables from config
    DRY_RUN="${DRY_RUN:-false}"
    VERBOSE="${VERBOSE:-true}"
    LOG_FILE="${LOG_FILE:-/var/log/qubes-sdp-setup.log}"

    log SUCCESS "Configuration loaded successfully"
}

# ==============================================================================
# PRE-FLIGHT CHECKS
# ==============================================================================

check_dom0() {
    if [ "$(hostname)" != "dom0" ]; then
        error_exit "This script must be run in dom0"
    fi
    log SUCCESS "Running in dom0"
}

check_qubes_commands() {
    local required_commands=("qvm-create" "qvm-prefs" "qvm-ls" "qvm-firewall")

    for cmd in "${required_commands[@]}"; do
        if ! command -v "${cmd}" &>/dev/null; then
            error_exit "Required command not found: ${cmd}"
        fi
    done

    log SUCCESS "All required Qubes commands available"
}

check_templates() {
    local templates_to_check=()

    # Collect all templates that will be needed
    [ "${ENABLE_WORK:-true}" = "true" ] && templates_to_check+=("${WORK_TEMPLATE:-$DEFAULT_TEMPLATE}")
    [ "${ENABLE_VAULT:-true}" = "true" ] && templates_to_check+=("${VAULT_TEMPLATE:-$DEFAULT_TEMPLATE}")
    [ "${ENABLE_ANON:-true}" = "true" ] && templates_to_check+=("${ANON_TEMPLATE:-$DEFAULT_TEMPLATE}")
    [ "${ENABLE_UNTRUSTED:-true}" = "true" ] && templates_to_check+=("${UNTRUSTED_TEMPLATE:-$DEFAULT_TEMPLATE}")
    [ "${ENABLE_VPN:-false}" = "true" ] && templates_to_check+=("${VPN_TEMPLATE:-$DEFAULT_TEMPLATE}")
    [ "${ENABLE_USB:-false}" = "true" ] && templates_to_check+=("${USB_TEMPLATE:-$DEFAULT_TEMPLATE}")

    # Get unique templates
    templates_to_check=($(printf '%s\n' "${templates_to_check[@]}" | sort -u))

    log INFO "Checking required templates..."

    for template in "${templates_to_check[@]}"; do
        if qvm-ls --raw-list | grep -q "^${template}$"; then
            log SUCCESS "Template ${template} is installed"
        else
            log WARNING "Template ${template} not found"

            if [ "${AUTO_INSTALL_TEMPLATES:-true}" = "true" ] && [ "${DRY_RUN}" = "false" ]; then
                log INFO "Installing template ${template}..."
                if ! qubes-dom0-update --enablerepo=qubes-templates-itl -y "${template}"; then
                    error_exit "Failed to install template ${template}"
                fi
                log SUCCESS "Template ${template} installed"
            else
                error_exit "Required template ${template} not available"
            fi
        fi
    done
}

update_templates() {
    if [ "${UPDATE_TEMPLATES:-true}" != "true" ]; then
        return 0
    fi

    log INFO "Updating templates..."

    local templates=($(qvm-ls --raw-list --tags template))

    for template in "${templates[@]}"; do
        log INFO "Updating ${template}..."
        if [ "${DRY_RUN}" = "false" ]; then
            qvm-run -p -u root "${template}" 'dnf update -y || apt-get update && apt-get upgrade -y || true' || \
                log WARNING "Failed to update ${template}"
        fi
    done

    log SUCCESS "Templates updated"
}

preflight_checks() {
    log STEP "Running pre-flight checks..."

    check_dom0
    check_qubes_commands
    check_templates

    if [ "${UPDATE_TEMPLATES:-true}" = "true" ]; then
        update_templates
    fi

    log SUCCESS "Pre-flight checks completed"
}

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

qube_exists() {
    qvm-ls "$1" &>/dev/null
}

execute() {
    local cmd="$*"

    if [ "${DRY_RUN}" = "true" ]; then
        log INFO "[DRY-RUN] ${cmd}"
        return 0
    else
        log INFO "Executing: ${cmd}"
        if ! eval "${cmd}"; then
            error_exit "Command failed: ${cmd}"
        fi
    fi
}

# ==============================================================================
# ROLLBACK SYSTEM
# ==============================================================================

init_rollback() {
    if [ "${DRY_RUN}" = "false" ]; then
        cat > "${ROLLBACK_FILE}" << 'EOF'
#!/bin/bash
# Auto-generated rollback script
set -e

echo "Rolling back Qubes SDP setup..."

EOF
        chmod +x "${ROLLBACK_FILE}"
    fi
}

add_rollback_step() {
    if [ "${DRY_RUN}" = "false" ]; then
        echo "$*" >> "${ROLLBACK_FILE}"
    fi
}

rollback_changes() {
    if [ -f "${ROLLBACK_FILE}" ] && [ "${DRY_RUN}" = "false" ]; then
        log WARNING "Executing rollback..."
        if bash "${ROLLBACK_FILE}"; then
            log SUCCESS "Rollback completed"
        else
            log ERROR "Rollback failed - manual intervention required"
        fi
        rm -f "${ROLLBACK_FILE}"
    fi
}

# ==============================================================================
# TOPOLOGY PRESETS
# ==============================================================================

apply_preset_journalist() {
    log INFO "Applying 'journalist' topology preset"

    # Override config for journalist workflow
    ENABLE_WORK="true"
    ENABLE_VAULT="true"
    ENABLE_ANON="true"
    ENABLE_UNTRUSTED="true"
    ENABLE_VPN="false"
    ENABLE_USB="false"

    ENABLE_SPLIT_GPG="true"
    SPLIT_GPG_BACKEND="vault"
    SPLIT_GPG_CLIENTS="work"

    ENABLE_QREXEC_POLICIES="true"
    ALLOW_WORK_TO_VAULT_COPY="true"
    ALLOW_UNTRUSTED_TO_WORK_COPY="ask"

    log SUCCESS "Journalist preset applied"
}

apply_preset_developer() {
    log INFO "Applying 'developer' topology preset"

    ENABLE_WORK="true"
    ENABLE_VAULT="true"
    ENABLE_ANON="false"
    ENABLE_UNTRUSTED="true"
    ENABLE_VPN="false"
    ENABLE_USB="false"

    WORK_MEMORY="4096"
    WORK_PACKAGES="vim git curl wget build-essential python3 nodejs"

    ENABLE_SPLIT_SSH="true"
    SPLIT_SSH_BACKEND="vault"
    SPLIT_SSH_CLIENTS="work"

    log SUCCESS "Developer preset applied"
}

apply_preset_researcher() {
    log INFO "Applying 'researcher' topology preset"

    ENABLE_WORK="true"
    ENABLE_VAULT="true"
    ENABLE_ANON="true"
    ENABLE_UNTRUSTED="true"
    ENABLE_VPN="true"
    ENABLE_USB="false"

    WORK_MEMORY="3072"
    VPN_PROVIDES_NETWORK="true"

    log SUCCESS "Researcher preset applied"
}

apply_preset_teacher() {
    log INFO "Applying 'teacher' topology preset"

    ENABLE_WORK="true"
    ENABLE_VAULT="true"
    ENABLE_ANON="false"
    ENABLE_UNTRUSTED="true"
    ENABLE_VPN="false"
    ENABLE_USB="true"

    USB_NAME="sys-usb"

    log SUCCESS "Teacher preset applied"
}

apply_preset_pentester() {
    log INFO "Applying 'pentester' topology preset"

    ENABLE_WORK="true"
    ENABLE_VAULT="true"
    ENABLE_ANON="true"
    ENABLE_UNTRUSTED="true"
    ENABLE_VPN="true"
    ENABLE_USB="true"

    WORK_MEMORY="4096"
    WORK_PACKAGES="vim git curl wget nmap wireshark metasploit-framework"

    VPN_PROVIDES_NETWORK="true"

    ENABLE_SPLIT_GPG="true"
    ENABLE_SPLIT_SSH="true"

    log SUCCESS "Pentester preset applied"
}

apply_topology_preset() {
    local preset="${TOPOLOGY_PRESET:-custom}"

    if [ "${preset}" = "custom" ]; then
        log INFO "Using custom topology configuration"
        return 0
    fi

    case "${preset}" in
        journalist)
            apply_preset_journalist
            ;;
        developer)
            apply_preset_developer
            ;;
        researcher)
            apply_preset_researcher
            ;;
        teacher)
            apply_preset_teacher
            ;;
        pentester)
            apply_preset_pentester
            ;;
        *)
            log WARNING "Unknown preset: ${preset}, using custom configuration"
            ;;
    esac
}

# ==============================================================================
# QUBE CREATION
# ==============================================================================

create_standard_qube() {
    local name=$1
    local label=$2
    local memory=$3
    local netvm=$4
    local template=$5
    local packages=$6

    if qube_exists "${name}"; then
        log WARNING "Qube ${name} already exists, skipping"
        return 0
    fi

    log STEP "Creating qube: ${name}"

    # Check netvm availability
    if [ -n "${netvm}" ] && ! qube_exists "${netvm}"; then
        log WARNING "Network qube ${netvm} not found"

        # Try fallback for whonix
        if [ "${netvm}" = "sys-whonix" ]; then
            local fallback="${ANON_NETVM_FALLBACK:-sys-firewall}"
            log INFO "Falling back to ${fallback}"
            netvm="${fallback}"
        else
            error_exit "Required network qube ${netvm} not found"
        fi
    fi

    # Create qube
    local create_cmd="qvm-create --label ${label} --template ${template} --property memory=${memory}"

    if [ -n "${netvm}" ]; then
        create_cmd="${create_cmd} --property netvm=${netvm}"
    else
        create_cmd="${create_cmd} --property netvm=''"
    fi

    create_cmd="${create_cmd} ${name}"

    execute "${create_cmd}"

    CREATED_QUBES+=("${name}")
    add_rollback_step "qvm-remove -f ${name} 2>/dev/null || true"

    # Install packages if specified
    if [ -n "${packages}" ] && [ "${DRY_RUN}" = "false" ]; then
        log INFO "Installing packages in ${name}: ${packages}"
        install_packages_in_qube "${name}" "${packages}"
    fi

    log SUCCESS "Qube ${name} created successfully"
}

install_packages_in_qube() {
    local qube=$1
    local packages=$2

    if [ "${DRY_RUN}" = "true" ]; then
        log INFO "[DRY-RUN] Would install packages in ${qube}: ${packages}"
        return 0
    fi

    log INFO "Installing packages in ${qube}..."

    # Detect package manager and install
    qvm-run -p -u root "${qube}" "
        if command -v dnf &>/dev/null; then
            dnf install -y ${packages}
        elif command -v apt-get &>/dev/null; then
            apt-get update && apt-get install -y ${packages}
        else
            echo 'Unknown package manager' >&2
            exit 1
        fi
    " || log WARNING "Failed to install packages in ${qube}"
}

# ==============================================================================
# FIREWALL CONFIGURATION
# ==============================================================================

configure_firewall() {
    local qube=$1
    local policy=$2
    local allowed_ports=$3

    if ! qube_exists "${qube}"; then
        log WARNING "Qube ${qube} does not exist, skipping firewall configuration"
        return 0
    fi

    log STEP "Configuring firewall for ${qube}"

    execute "qvm-firewall ${qube} reset"

    if [ "${policy}" = "allow-all" ]; then
        log INFO "Firewall policy: allow all"
        return 0
    elif [ "${policy}" = "deny-all" ]; then
        execute "qvm-firewall ${qube} del --rule-no 0"
        execute "qvm-firewall ${qube} add action=drop"
        log SUCCESS "Firewall set to deny all"
        return 0
    fi

    # Custom policy
    execute "qvm-firewall ${qube} del --rule-no 0"

    IFS=',' read -ra ports <<< "${allowed_ports}"
    for port_spec in "${ports[@]}"; do
        IFS=':' read -r proto port <<< "${port_spec}"
        execute "qvm-firewall ${qube} add action=accept proto=${proto} dstport=${port}"
        log INFO "Allowed ${proto}:${port}"
    done

    execute "qvm-firewall ${qube} add action=drop"

    log SUCCESS "Firewall configured for ${qube}"
}

# ==============================================================================
# DISPVM CONFIGURATION
# ==============================================================================

configure_dispvm_template() {
    local qube=$1

    if ! qube_exists "${qube}"; then
        log WARNING "Qube ${qube} does not exist, skipping DispVM configuration"
        return 0
    fi

    log STEP "Configuring ${qube} as DispVM template"

    execute "qvm-prefs ${qube} template_for_dispvms True"
    execute "qvm-features ${qube} appmenus-dispvm 1"

    log SUCCESS "${qube} configured as DispVM template"
}

# ==============================================================================
# VPN QUBE SETUP
# ==============================================================================

setup_vpn_qube() {
    if [ "${ENABLE_VPN:-false}" != "true" ]; then
        return 0
    fi

    local name="${VPN_NAME:-vpn}"
    local label="${VPN_LABEL:-blue}"
    local memory="${VPN_MEMORY:-512}"
    local netvm="${VPN_NETVM:-sys-firewall}"
    local template="${VPN_TEMPLATE:-$DEFAULT_TEMPLATE}"
    local packages="${VPN_PACKAGES:-openvpn wireguard-tools}"

    log STEP "Setting up VPN qube: ${name}"

    create_standard_qube "${name}" "${label}" "${memory}" "${netvm}" "${template}" "${packages}"

    if [ "${VPN_PROVIDES_NETWORK:-true}" = "true" ]; then
        execute "qvm-prefs ${name} provides_network True"
        log SUCCESS "VPN qube ${name} will provide network to other qubes"
    fi

    # Copy VPN config if provided
    if [ -n "${VPN_CONFIG_FILE}" ] && [ -f "${VPN_CONFIG_FILE}" ]; then
        log INFO "Copying VPN configuration..."
        execute "qvm-copy-to-vm ${name} ${VPN_CONFIG_FILE}"
    fi

    log SUCCESS "VPN qube setup completed"
}

# ==============================================================================
# USB QUBE SETUP
# ==============================================================================

setup_usb_qube() {
    if [ "${ENABLE_USB:-false}" != "true" ]; then
        return 0
    fi

    local name="${USB_NAME:-sys-usb}"
    local label="${USB_LABEL:-red}"
    local memory="${USB_MEMORY:-512}"
    local template="${USB_TEMPLATE:-$DEFAULT_TEMPLATE}"

    log STEP "Setting up USB qube: ${name}"

    if qube_exists "${name}"; then
        log WARNING "USB qube ${name} already exists"
        return 0
    fi

    execute "qvm-create --label ${label} --template ${template} --property memory=${memory} --property provides_network=False ${name}"

    CREATED_QUBES+=("${name}")
    add_rollback_step "qvm-remove -f ${name} 2>/dev/null || true"

    # Attach USB devices if specified
    if [ -n "${USB_PCI_DEVICES}" ]; then
        IFS=',' read -ra devices <<< "${USB_PCI_DEVICES}"
        for device in "${devices[@]}"; do
            log INFO "Attaching PCI device ${device} to ${name}"
            execute "qvm-pci attach ${name} ${device} --persistent"
        done
    fi

    log SUCCESS "USB qube setup completed"
}

# ==============================================================================
# SPLIT-GPG SETUP
# ==============================================================================

setup_split_gpg() {
    if [ "${ENABLE_SPLIT_GPG:-false}" != "true" ]; then
        return 0
    fi

    local backend="${SPLIT_GPG_BACKEND:-vault}"
    local clients="${SPLIT_GPG_CLIENTS:-work}"

    log STEP "Setting up split-GPG (backend: ${backend})"

    if ! qube_exists "${backend}"; then
        log WARNING "GPG backend qube ${backend} does not exist, skipping split-GPG setup"
        return 0
    fi

    # Install split-gpg packages
    if [ "${DRY_RUN}" = "false" ]; then
        log INFO "Installing split-gpg in ${backend}..."
        install_packages_in_qube "${backend}" "qubes-gpg-split"
    fi

    IFS=',' read -ra client_list <<< "${clients}"
    for client in "${client_list[@]}"; do
        if qube_exists "${client}"; then
            log INFO "Configuring split-GPG for client: ${client}"

            if [ "${DRY_RUN}" = "false" ]; then
                install_packages_in_qube "${client}" "qubes-gpg-split"

                # Set GPG backend
                execute "qvm-prefs ${client} management_dispvm ''"
                qvm-run -p "${client}" "echo 'export QUBES_GPG_DOMAIN=${backend}' >> ~/.bashrc" || true
            fi

            # Add qrexec policy
            add_qrexec_policy "qubes.Gpg" "${client}" "${backend}" "ask"
        else
            log WARNING "Client qube ${client} does not exist"
        fi
    done

    log SUCCESS "Split-GPG setup completed"
}

# ==============================================================================
# SPLIT-SSH SETUP
# ==============================================================================

setup_split_ssh() {
    if [ "${ENABLE_SPLIT_SSH:-false}" != "true" ]; then
        return 0
    fi

    local backend="${SPLIT_SSH_BACKEND:-vault}"
    local clients="${SPLIT_SSH_CLIENTS:-work}"

    log STEP "Setting up split-SSH (backend: ${backend})"

    if ! qube_exists "${backend}"; then
        log WARNING "SSH backend qube ${backend} does not exist, skipping split-SSH setup"
        return 0
    fi

    IFS=',' read -ra client_list <<< "${clients}"
    for client in "${client_list[@]}"; do
        if qube_exists "${client}"; then
            log INFO "Configuring split-SSH for client: ${client}"

            if [ "${DRY_RUN}" = "false" ]; then
                # Configure SSH client
                qvm-run -p "${client}" "echo 'export SSH_AUTH_SOCK=~/.SSH_AGENT_${backend}' >> ~/.bashrc" || true

                # Set up SSH agent forwarding
                qvm-run -p "${client}" "mkdir -p ~/.config/systemd/user" || true
            fi

            # Add qrexec policy
            add_qrexec_policy "qubes.SshAgent" "${client}" "${backend}" "ask"
        else
            log WARNING "Client qube ${client} does not exist"
        fi
    done

    log SUCCESS "Split-SSH setup completed"
}

# ==============================================================================
# QREXEC POLICY MANAGEMENT
# ==============================================================================

add_qrexec_policy() {
    local service=$1
    local source=$2
    local dest=$3
    local action=$4  # allow, deny, ask

    if [ "${ENABLE_QREXEC_POLICIES:-true}" != "true" ]; then
        return 0
    fi

    if [ "${DRY_RUN}" = "true" ]; then
        log INFO "[DRY-RUN] Would add qrexec policy: ${service}: ${source} -> ${dest} (${action})"
        return 0
    fi

    local policy_file="/etc/qubes-rpc/policy/${service}"

    # Create policy file if it doesn't exist
    if [ ! -f "${policy_file}" ]; then
        touch "${policy_file}"
    fi

    # Add policy rule (prepend to file)
    local rule="${source} ${dest} ${action}"

    if ! grep -q "${rule}" "${policy_file}" 2>/dev/null; then
        sed -i "1i ${rule}" "${policy_file}"
        log INFO "Added qrexec policy: ${service}: ${rule}"
    else
        log INFO "Qrexec policy already exists: ${service}: ${rule}"
    fi
}

configure_qrexec_policies() {
    if [ "${ENABLE_QREXEC_POLICIES:-true}" != "true" ]; then
        return 0
    fi

    log STEP "Configuring qrexec policies..."

    # File copy policies
    if [ "${ALLOW_WORK_TO_VAULT_COPY:-true}" = "true" ]; then
        add_qrexec_policy "qubes.Filecopy" "${WORK_NAME:-work}" "${VAULT_NAME:-vault}" "allow"
    fi

    if [ "${ALLOW_UNTRUSTED_TO_WORK_COPY:-ask}" != "deny" ]; then
        add_qrexec_policy "qubes.Filecopy" "${UNTRUSTED_NAME:-untrusted}" "${WORK_NAME:-work}" "${ALLOW_UNTRUSTED_TO_WORK_COPY:-ask}"
    fi

    # Clipboard policies
    if [ "${ALLOW_WORK_VAULT_CLIPBOARD:-ask}" != "deny" ]; then
        add_qrexec_policy "qubes.ClipboardPaste" "${WORK_NAME:-work}" "${VAULT_NAME:-vault}" "${ALLOW_WORK_VAULT_CLIPBOARD:-ask}"
    fi

    log SUCCESS "Qrexec policies configured"
}

# ==============================================================================
# BACKUP SYSTEM
# ==============================================================================

create_backup() {
    if [ "${AUTO_BACKUP:-true}" != "true" ]; then
        return 0
    fi

    log STEP "Creating backup..."

    local backup_qubes="${BACKUP_QUBES:-vault,work}"
    local backup_dest="${BACKUP_DEST:-dom0:/var/backups/qubes-sdp}"

    if [ "${DRY_RUN}" = "true" ]; then
        log INFO "[DRY-RUN] Would create backup of: ${backup_qubes}"
        return 0
    fi

    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_path="${backup_dest}/backup-${timestamp}"

    log INFO "Creating backup: ${backup_path}"

    # Create backup directory
    mkdir -p "$(dirname "${backup_path}")"

    # Use qvm-backup
    local qubes_list="${backup_qubes//,/ }"

    if qvm-backup ${qubes_list} "${backup_path}"; then
        log SUCCESS "Backup created: ${backup_path}"
    else
        log WARNING "Backup failed"
    fi
}

setup_backup_cron() {
    if [ "${AUTO_BACKUP:-true}" != "true" ] || [ -z "${BACKUP_SCHEDULE}" ]; then
        return 0
    fi

    log STEP "Setting up backup cron job..."

    if [ "${DRY_RUN}" = "true" ]; then
        log INFO "[DRY-RUN] Would add cron job: ${BACKUP_SCHEDULE}"
        return 0
    fi

    local cron_cmd="$(realpath "$0") --backup-only"
    local cron_entry="${BACKUP_SCHEDULE} ${cron_cmd}"

    # Add to root crontab
    (crontab -l 2>/dev/null | grep -v "${cron_cmd}"; echo "${cron_entry}") | crontab -

    log SUCCESS "Backup cron job configured"
}

# ==============================================================================
# MAIN QUBE SETUP
# ==============================================================================

setup_work_qube() {
    if [ "${ENABLE_WORK:-true}" != "true" ]; then
        return 0
    fi

    local name="${WORK_NAME:-work}"
    local label="${WORK_LABEL:-green}"
    local memory="${WORK_MEMORY:-2048}"
    local netvm="${WORK_NETVM:-sys-firewall}"
    local template="${WORK_TEMPLATE:-$DEFAULT_TEMPLATE}"
    local packages="${WORK_PACKAGES:-vim git curl wget}"

    create_standard_qube "${name}" "${label}" "${memory}" "${netvm}" "${template}" "${packages}"

    if [ "${WORK_FIREWALL_POLICY:-custom}" = "custom" ]; then
        configure_firewall "${name}" "custom" "${WORK_ALLOWED_PORTS:-tcp:80,tcp:443,udp:53}"
    else
        configure_firewall "${name}" "${WORK_FIREWALL_POLICY}" ""
    fi

    if [ "${WORK_AUTOSTART:-false}" = "true" ]; then
        execute "qvm-prefs ${name} autostart True"
    fi
}

setup_vault_qube() {
    if [ "${ENABLE_VAULT:-true}" != "true" ]; then
        return 0
    fi

    local name="${VAULT_NAME:-vault}"
    local label="${VAULT_LABEL:-black}"
    local memory="${VAULT_MEMORY:-1024}"
    local template="${VAULT_TEMPLATE:-$DEFAULT_TEMPLATE}"
    local packages="${VAULT_PACKAGES:-vim keepassxc}"

    # Vault has NO network
    create_standard_qube "${name}" "${label}" "${memory}" "" "${template}" "${packages}"

    if [ "${VAULT_AUTOSTART:-false}" = "true" ]; then
        execute "qvm-prefs ${name} autostart True"
    fi
}

setup_anon_qube() {
    if [ "${ENABLE_ANON:-true}" != "true" ]; then
        return 0
    fi

    local name="${ANON_NAME:-anon}"
    local label="${ANON_LABEL:-purple}"
    local memory="${ANON_MEMORY:-1024}"
    local netvm="${ANON_NETVM:-sys-whonix}"
    local template="${ANON_TEMPLATE:-$DEFAULT_TEMPLATE}"
    local packages="${ANON_PACKAGES:-vim tor-browser}"

    create_standard_qube "${name}" "${label}" "${memory}" "${netvm}" "${template}" "${packages}"

    if [ "${ANON_AUTOSTART:-false}" = "true" ]; then
        execute "qvm-prefs ${name} autostart True"
    fi
}

setup_untrusted_qube() {
    if [ "${ENABLE_UNTRUSTED:-true}" != "true" ]; then
        return 0
    fi

    local name="${UNTRUSTED_NAME:-untrusted}"
    local label="${UNTRUSTED_LABEL:-red}"
    local memory="${UNTRUSTED_MEMORY:-1024}"
    local netvm="${UNTRUSTED_NETVM:-sys-firewall}"
    local template="${UNTRUSTED_TEMPLATE:-$DEFAULT_TEMPLATE}"
    local packages="${UNTRUSTED_PACKAGES:-vim}"

    create_standard_qube "${name}" "${label}" "${memory}" "${netvm}" "${template}" "${packages}"

    if [ "${UNTRUSTED_IS_DISPVM_TEMPLATE:-true}" = "true" ]; then
        configure_dispvm_template "${name}"
    fi

    if [ "${UNTRUSTED_AUTOSTART:-false}" = "true" ]; then
        execute "qvm-prefs ${name} autostart True"
    fi
}

# ==============================================================================
# VALIDATION
# ==============================================================================

validate_qube() {
    local name=$1
    local expected_label=$2
    local expected_memory=$3
    local expected_netvm=$4

    if ! qube_exists "${name}"; then
        log ERROR "Qube ${name} does not exist"
        return 1
    fi

    local actual_label=$(qvm-prefs "${name}" label)
    local actual_memory=$(qvm-prefs "${name}" memory)
    local actual_netvm=$(qvm-prefs "${name}" netvm)

    local all_ok=true

    if [ "${actual_label}" != "${expected_label}" ]; then
        log WARNING "${name}: label mismatch (expected: ${expected_label}, got: ${actual_label})"
        all_ok=false
    fi

    if [ "${actual_memory}" != "${expected_memory}" ]; then
        log WARNING "${name}: memory mismatch (expected: ${expected_memory}, got: ${actual_memory})"
        all_ok=false
    fi

    if [ -z "${expected_netvm}" ]; then
        if [ -n "${actual_netvm}" ]; then
            log WARNING "${name}: should have no network (got: ${actual_netvm})"
            all_ok=false
        fi
    else
        if [ "${actual_netvm}" != "${expected_netvm}" ]; then
            log WARNING "${name}: netvm mismatch (expected: ${expected_netvm}, got: ${actual_netvm})"
            all_ok=false
        fi
    fi

    if [ "${all_ok}" = "true" ]; then
        log SUCCESS "${name}: validation passed"
        return 0
    else
        return 1
    fi
}

validate_setup() {
    log STEP "Validating setup..."

    local validation_failed=false

    [ "${ENABLE_WORK:-true}" = "true" ] && \
        (validate_qube "${WORK_NAME:-work}" "${WORK_LABEL:-green}" "${WORK_MEMORY:-2048}" "${WORK_NETVM:-sys-firewall}" || validation_failed=true)

    [ "${ENABLE_VAULT:-true}" = "true" ] && \
        (validate_qube "${VAULT_NAME:-vault}" "${VAULT_LABEL:-black}" "${VAULT_MEMORY:-1024}" "" || validation_failed=true)

    [ "${ENABLE_ANON:-true}" = "true" ] && \
        (validate_qube "${ANON_NAME:-anon}" "${ANON_LABEL:-purple}" "${ANON_MEMORY:-1024}" "${ANON_NETVM:-sys-whonix}" || validation_failed=true)

    [ "${ENABLE_UNTRUSTED:-true}" = "true" ] && \
        (validate_qube "${UNTRUSTED_NAME:-untrusted}" "${UNTRUSTED_LABEL:-red}" "${UNTRUSTED_MEMORY:-1024}" "${UNTRUSTED_NETVM:-sys-firewall}" || validation_failed=true)

    if [ "${validation_failed}" = "true" ]; then
        log WARNING "Validation completed with warnings"
        return 1
    else
        log SUCCESS "All validations passed"
        return 0
    fi
}

# ==============================================================================
# HEALTH CHECKS
# ==============================================================================

health_check() {
    log STEP "Running health checks..."

    local all_healthy=true

    for qube in "${CREATED_QUBES[@]}"; do
        if qube_exists "${qube}"; then
            local state=$(qvm-ls "${qube}" --raw-data --fields state | tail -1)

            if [ "${state}" = "Halted" ]; then
                log SUCCESS "${qube} is halted (healthy)"
            elif [ "${state}" = "Running" ]; then
                log SUCCESS "${qube} is running (healthy)"
            else
                log WARNING "${qube} is in unexpected state: ${state}"
                all_healthy=false
            fi
        else
            log ERROR "${qube} does not exist"
            all_healthy=false
        fi
    done

    if [ "${all_healthy}" = "true" ]; then
        log SUCCESS "All health checks passed"
    else
        log WARNING "Some health checks failed"
    fi
}

# ==============================================================================
# INTERACTIVE WIZARD
# ==============================================================================

interactive_wizard() {
    log INFO "Starting interactive setup wizard..."

    echo -e "${CYAN}Qubes SDP Interactive Setup${NC}"
    echo "=============================="
    echo

    read -p "Choose topology preset (custom/journalist/developer/researcher/teacher/pentester) [custom]: " preset
    TOPOLOGY_PRESET="${preset:-custom}"

    if [ "${TOPOLOGY_PRESET}" != "custom" ]; then
        apply_topology_preset
        echo -e "${GREEN}Preset '${TOPOLOGY_PRESET}' applied${NC}"
        return 0
    fi

    # Custom configuration
    read -p "Create work qube? [Y/n]: " answer
    ENABLE_WORK="${answer:-y}"
    [[ "${ENABLE_WORK,,}" =~ ^(y|yes)$ ]] && ENABLE_WORK="true" || ENABLE_WORK="false"

    read -p "Create vault qube? [Y/n]: " answer
    ENABLE_VAULT="${answer:-y}"
    [[ "${ENABLE_VAULT,,}" =~ ^(y|yes)$ ]] && ENABLE_VAULT="true" || ENABLE_VAULT="false"

    read -p "Create anon qube? [Y/n]: " answer
    ENABLE_ANON="${answer:-y}"
    [[ "${ENABLE_ANON,,}" =~ ^(y|yes)$ ]] && ENABLE_ANON="true" || ENABLE_ANON="false"

    read -p "Create untrusted qube? [Y/n]: " answer
    ENABLE_UNTRUSTED="${answer:-y}"
    [[ "${ENABLE_UNTRUSTED,,}" =~ ^(y|yes)$ ]] && ENABLE_UNTRUSTED="true" || ENABLE_UNTRUSTED="false"

    read -p "Enable split-GPG? [y/N]: " answer
    ENABLE_SPLIT_GPG="${answer:-n}"
    [[ "${ENABLE_SPLIT_GPG,,}" =~ ^(y|yes)$ ]] && ENABLE_SPLIT_GPG="true" || ENABLE_SPLIT_GPG="false"

    echo -e "${GREEN}Configuration complete${NC}"
}

# ==============================================================================
# MAIN SETUP ORCHESTRATION
# ==============================================================================

run_setup() {
    log INFO "==== Qubes SDP Advanced Setup ===="

    init_rollback

    # Apply topology preset if configured
    apply_topology_preset

    # Setup qubes
    local total_steps=12
    local current_step=0

    progress $((++current_step)) ${total_steps} "Creating work qube"
    setup_work_qube

    progress $((++current_step)) ${total_steps} "Creating vault qube"
    setup_vault_qube

    progress $((++current_step)) ${total_steps} "Creating anon qube"
    setup_anon_qube

    progress $((++current_step)) ${total_steps} "Creating untrusted qube"
    setup_untrusted_qube

    progress $((++current_step)) ${total_steps} "Setting up VPN qube"
    setup_vpn_qube

    progress $((++current_step)) ${total_steps} "Setting up USB qube"
    setup_usb_qube

    progress $((++current_step)) ${total_steps} "Configuring split-GPG"
    setup_split_gpg

    progress $((++current_step)) ${total_steps} "Configuring split-SSH"
    setup_split_ssh

    progress $((++current_step)) ${total_steps} "Configuring qrexec policies"
    configure_qrexec_policies

    progress $((++current_step)) ${total_steps} "Creating backup"
    create_backup

    progress $((++current_step)) ${total_steps} "Setting up backup cron"
    setup_backup_cron

    progress $((++current_step)) ${total_steps} "Validating setup"
    validate_setup || true

    progress ${total_steps} ${total_steps} "Complete"

    health_check

    # Cleanup rollback file on success
    rm -f "${ROLLBACK_FILE}"

    log SUCCESS "==== Setup completed successfully ===="
}

# ==============================================================================
# COMMAND LINE INTERFACE
# ==============================================================================

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Qubes OS Advanced Setup Script - Configuration-driven qube topology setup

Options:
    -h, --help              Show this help message
    -c, --config FILE       Use alternate configuration file
    -i, --interactive       Run interactive setup wizard
    -v, --verbose           Enable verbose output (default)
    -q, --quiet             Disable verbose output
    -d, --dry-run           Perform dry run without making changes
    --validate              Validate existing setup only
    --health-check          Run health checks only
    --backup-only           Create backup only
    --rollback              Rollback last setup
    --no-log                Disable logging to file

Examples:
    $(basename "$0")                    # Normal setup
    $(basename "$0") --dry-run          # Test without changes
    $(basename "$0") --interactive      # Interactive wizard
    $(basename "$0") --validate         # Validate current setup

Configuration:
    Edit qubes-config.conf to customize your setup

EOF
}

# Parse command line arguments
INTERACTIVE=false
VALIDATE_ONLY=false
HEALTH_CHECK_ONLY=false
BACKUP_ONLY=false
ROLLBACK_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -i|--interactive)
            INTERACTIVE=true
            shift
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
            shift
            ;;
        --validate)
            VALIDATE_ONLY=true
            shift
            ;;
        --health-check)
            HEALTH_CHECK_ONLY=true
            shift
            ;;
        --backup-only)
            BACKUP_ONLY=true
            shift
            ;;
        --rollback)
            ROLLBACK_ONLY=true
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
# MAIN
# ==============================================================================

main() {
    # Initialize logging
    if [ "${LOG_FILE}" != "/dev/null" ]; then
        touch "${LOG_FILE}" 2>/dev/null || LOG_FILE="/tmp/qubes-sdp-advanced-setup.log"
        log INFO "=== Qubes SDP Advanced Setup Started ==="
    fi

    # Load configuration
    if [ ! "${INTERACTIVE}" = "true" ]; then
        load_config
    fi

    # Handle special modes
    if [ "${ROLLBACK_ONLY}" = "true" ]; then
        rollback_changes
        exit 0
    fi

    if [ "${VALIDATE_ONLY}" = "true" ]; then
        load_config
        validate_setup
        exit $?
    fi

    if [ "${HEALTH_CHECK_ONLY}" = "true" ]; then
        health_check
        exit $?
    fi

    if [ "${BACKUP_ONLY}" = "true" ]; then
        load_config
        create_backup
        exit 0
    fi

    # Run pre-flight checks
    preflight_checks

    # Interactive wizard if requested
    if [ "${INTERACTIVE}" = "true" ]; then
        interactive_wizard
    fi

    # Run main setup
    run_setup

    # Summary
    if [ "${DRY_RUN}" = "true" ]; then
        echo -e "\n${YELLOW}DRY RUN COMPLETE${NC}"
        echo "No changes were made. Run without --dry-run to apply."
    else
        echo -e "\n${GREEN}SETUP COMPLETE${NC}"
        echo "Log file: ${LOG_FILE}"
        echo
        echo "Created qubes: ${CREATED_QUBES[*]}"
        echo
        echo "Next steps:"
        echo "  - Review qube configurations: qvm-ls"
        echo "  - Start qubes: qvm-start <qube-name>"
        echo "  - Check firewall rules: qvm-firewall <qube-name> list"
    fi
}

# Execute main function
main
