# Qubes SDP Justfile
# Just command runner for common tasks
# Install: https://github.com/casey/just

# Default recipe - show available commands
default:
    @just --list

# ============================================================================
# Setup and Installation
# ============================================================================

# Run simple setup (basic topology)
setup-simple:
    @echo "Running simple setup..."
    bash qubes-setup.sh

# Run advanced setup (config-driven)
setup-advanced:
    @echo "Running advanced setup..."
    bash qubes-setup-advanced.sh

# Run interactive setup wizard
setup-interactive:
    @echo "Starting interactive wizard..."
    bash qubes-setup-advanced.sh --interactive

# Test setup with dry-run (no changes)
setup-dry-run:
    @echo "Running dry-run (no changes will be made)..."
    bash qubes-setup-advanced.sh --dry-run

# Setup with specific preset
setup-preset preset:
    @echo "Running setup with preset: {{preset}}"
    make -f Makefile.qubes setup-preset-{{preset}}

# ============================================================================
# Validation and Testing
# ============================================================================

# Validate existing setup
validate:
    @echo "Validating setup..."
    bash qubes-setup-advanced.sh --validate

# Run health checks
health-check:
    @echo "Running health checks..."
    bash qubes-setup-advanced.sh --health-check

# Run all tests
test:
    @echo "Running all tests..."
    bash tests/run-tests.sh

# Run syntax tests only
test-syntax:
    @echo "Running syntax tests..."
    bash tests/syntax-test.sh qubes-setup.sh
    bash tests/syntax-test.sh qubes-setup-advanced.sh

# Run unit tests only
test-unit:
    @echo "Running unit tests..."
    bash tests/unit-tests.sh

# Run integration tests only
test-integration:
    @echo "Running integration tests..."
    bash tests/integration-tests.sh

# Run security tests only
test-security:
    @echo "Running security tests..."
    bash tests/security-tests.sh

# Verify RSR compliance
rsr-verify:
    @echo "Verifying RSR compliance..."
    bash scripts/rsr-verify.sh

# ============================================================================
# Status and Monitoring
# ============================================================================

# Show status dashboard
status:
    @bash tools/qubes-status.sh

# Launch interactive dashboard
dashboard:
    @bash tools/qubes-dashboard.sh

# Analyze firewall rules
firewall-check:
    @bash tools/qubes-firewall-analyzer.sh

# Check template status
template-status:
    @bash tools/qubes-template-manager.sh status

# ============================================================================
# Template Management
# ============================================================================

# Update all templates
template-update:
    @echo "Updating templates..."
    bash tools/qubes-template-manager.sh update

# Install missing templates
template-install:
    @echo "Installing missing templates..."
    bash tools/qubes-template-manager.sh install

# Clean template cache
template-clean:
    @echo "Cleaning template cache..."
    bash tools/qubes-template-manager.sh clean

# Show detailed template info
template-info:
    @bash tools/qubes-template-manager.sh info

# ============================================================================
# Backup and Recovery
# ============================================================================

# Create backup
backup:
    @echo "Creating backup..."
    make -f Makefile.qubes backup

# Validate backups
backup-validate:
    @bash tools/qubes-backup-validator.sh

# Restore from backup
backup-restore path:
    @echo "Restoring from {{path}}..."
    bash tools/qubes-restore.sh {{path}}

# ============================================================================
# Policy Management
# ============================================================================

# Show current qrexec policies
policy-show:
    @bash tools/qubes-policy-generator.sh show

# Generate recommended policies
policy-generate:
    @bash tools/qubes-policy-generator.sh generate

# Apply generated policies
policy-apply:
    @bash tools/qubes-policy-generator.sh apply

# Backup existing policies
policy-backup:
    @bash tools/qubes-policy-generator.sh backup

# ============================================================================
# Documentation
# ============================================================================

# Build wiki HTML
wiki-build:
    @echo "Building wiki..."
    cd wiki && bash build-wiki.sh

# Start wiki server
wiki-serve:
    @echo "Starting wiki server on http://localhost:8080"
    cd wiki/html && python3 -m http.server 8080

# View README
readme:
    @less README.md

# View QUICKSTART
quickstart:
    @less QUICKSTART.md

# View security policy
security:
    @less SECURITY.md

# ============================================================================
# Development
# ============================================================================

# Lint all shell scripts
lint:
    @echo "Linting shell scripts..."
    @find . -name "*.sh" -type f -exec bash -n {} \;
    @echo "All scripts passed syntax check"

# Format shell scripts (if shfmt installed)
format:
    @if command -v shfmt >/dev/null 2>&1; then \
        echo "Formatting shell scripts..."; \
        shfmt -w -i 4 *.sh tools/*.sh tests/*.sh; \
    else \
        echo "shfmt not installed, skipping"; \
    fi

# Run shellcheck (if installed)
shellcheck:
    @if command -v shellcheck >/dev/null 2>&1; then \
        echo "Running shellcheck..."; \
        find . -name "*.sh" -type f -exec shellcheck {} +; \
    else \
        echo "shellcheck not installed, skipping"; \
    fi

# Check for TODO items
todos:
    @echo "Searching for TODO items..."
    @grep -rn "TODO\|FIXME\|XXX\|HACK" --include="*.sh" --include="*.md" . || echo "No TODOs found"

# Count lines of code
loc:
    @echo "Lines of code:"
    @find . -name "*.sh" -o -name "*.md" | xargs wc -l | sort -n

# ============================================================================
# Cleanup
# ============================================================================

# Clean temporary files
clean:
    @echo "Cleaning temporary files..."
    @rm -f /var/log/qubes-sdp-setup.log
    @rm -f /var/run/qubes-sdp-*.{json,sh}
    @rm -f /tmp/qubes-sdp-*.log
    @echo "Cleanup complete"

# Clean build artifacts (wiki)
clean-build:
    @echo "Cleaning build artifacts..."
    @rm -rf wiki/html
    @echo "Build artifacts cleaned"

# Remove all SDP qubes (DANGEROUS!)
clean-all:
    @echo "WARNING: This will remove all SDP qubes!"
    @read -p "Are you sure? [y/N] " -n 1 -r; \
    if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
        make -f Makefile.qubes clean-all; \
    else \
        echo "Cancelled"; \
    fi

# ============================================================================
# Installation
# ============================================================================

# Install system-wide
install:
    @echo "Installing Qubes SDP system-wide..."
    @make -f Makefile.qubes install

# Uninstall system-wide
uninstall:
    @echo "Uninstalling Qubes SDP..."
    @make -f Makefile.qubes uninstall

# ============================================================================
# CI/CD
# ============================================================================

# Run CI checks (what GitLab CI would run)
ci: lint test rsr-verify
    @echo "All CI checks passed!"

# Pre-commit checks
pre-commit: lint test-syntax
    @echo "Pre-commit checks passed!"

# Pre-push checks
pre-push: test ci
    @echo "Pre-push checks passed!"

# ============================================================================
# Quick Actions
# ============================================================================

# Quick setup for journalists
quick-journalist:
    @just setup-preset journalist

# Quick setup for developers
quick-developer:
    @just setup-preset developer

# Quick setup for researchers
quick-researcher:
    @just setup-preset researcher

# Quick setup for minimal systems
quick-minimal:
    @cp examples/minimal-config.conf qubes-config.conf
    @just setup-advanced

# ============================================================================
# Utilities
# ============================================================================

# Show project info
info:
    @echo "Qubes SDP - Software Development Platform"
    @echo "Version: 1.0.0"
    @echo "RSR Compliance: Bronze Level (Target)"
    @echo "TPCF: Perimeter 3 (Community Sandbox)"
    @echo ""
    @echo "Quick commands:"
    @echo "  just setup-simple    - Basic setup"
    @echo "  just setup-advanced  - Config-driven setup"
    @echo "  just status          - Show dashboard"
    @echo "  just test            - Run all tests"
    @echo "  just backup          - Create backup"
    @echo ""
    @echo "Documentation:"
    @echo "  just readme          - View README"
    @echo "  just quickstart      - View QUICKSTART"
    @echo ""
    @echo "Full command list: just --list"

# Show environment info
env:
    @echo "Environment Information:"
    @echo "========================"
    @hostname | grep -q "dom0" && echo "✓ Running in dom0" || echo "✗ NOT in dom0"
    @echo ""
    @echo "System Resources:"
    @xl info | grep -E "(total_memory|free_memory)" || echo "Qubes tools not available"
    @echo ""
    @echo "Templates:"
    @qvm-template list --installed | head -10 || echo "qvm-template not available"

# Check dependencies
check-deps:
    @echo "Checking dependencies..."
    @command -v bash >/dev/null && echo "✓ bash" || echo "✗ bash (required)"
    @command -v qvm-create >/dev/null && echo "✓ qvm-create" || echo "✗ qvm-create (required)"
    @command -v make >/dev/null && echo "✓ make" || echo "⚠ make (optional)"
    @command -v git >/dev/null && echo "✓ git" || echo "⚠ git (optional)"
    @command -v python3 >/dev/null && echo "✓ python3" || echo "⚠ python3 (optional)"

# ============================================================================
# Help
# ============================================================================

# Show detailed help
help:
    @cat << 'EOF'
Qubes SDP Just Commands

SETUP:
  setup-simple          Run simple setup (4 basic qubes)
  setup-advanced        Run config-driven advanced setup
  setup-interactive     Interactive wizard
  setup-dry-run         Test without making changes
  setup-preset <name>   Use preset (journalist/developer/etc)

TESTING:
  test                  Run all tests
  test-syntax           Syntax checks only
  test-unit             Unit tests only
  test-integration      Integration tests only
  test-security         Security tests only
  validate              Validate existing setup
  health-check          Health status check
  rsr-verify            RSR compliance verification

MONITORING:
  status                Status dashboard
  dashboard             Interactive real-time dashboard
  firewall-check        Analyze firewall rules
  template-status       Template information

MAINTENANCE:
  template-update       Update all templates
  template-install      Install missing templates
  template-clean        Clean template cache
  backup                Create backup
  backup-validate       Verify backup integrity
  backup-restore <path> Restore from backup

DEVELOPMENT:
  lint                  Lint all scripts
  format                Format code (requires shfmt)
  shellcheck            Run shellcheck (if installed)
  todos                 Find TODO items
  loc                   Count lines of code

CLEANUP:
  clean                 Remove temporary files
  clean-build           Remove build artifacts
  clean-all             Remove all SDP qubes (DANGEROUS!)

OTHER:
  info                  Project information
  env                   Environment information
  check-deps            Check dependencies
  wiki-build            Build documentation
  readme                View README
  quickstart            View QUICKSTART guide

Use 'just --list' for complete command list.
Use 'just <command>' to run a specific command.
EOF
