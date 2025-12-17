# Changelog

All notable changes to Qubes SDP will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-12-17

### Security
- **CRITICAL**: Fixed expired security.txt (was 2025-11-22, now 2026-12-17)
- SHA-pinned all GitHub Actions for supply chain security (OSSF Scorecard compliance)
- Updated all `actions/checkout` to v4.2.2 with SHA pins
- Updated CodeQL actions to v4.31.9/v3.31.9 with SHA pins
- Updated OSSF Scorecard action to v2.3.1 with SHA pin
- Pinned trufflesecurity/trufflehog, editorconfig-checker, and other third-party actions

### Fixed
- Fixed LICENSE.txt check in flake.nix (was checking for non-existent LICENSE file)
- Fixed version mismatch in STATE.scm (now consistently 1.0.0)
- Updated SECURITY.md last-updated date

### Changed
- Updated STATE.scm to reflect current project status (85% completion)
- Added session history for security review

## [1.0.0] - 2024-11-22

### Added

#### Core System
- Simple setup script (`qubes-setup.sh`) for basic topology
- Advanced setup script (`qubes-setup-advanced.sh`) with full configuration
- Comprehensive configuration file (`qubes-config.conf`)
- Makefile (`Makefile.qubes`) for automation
- Salt Stack configuration for declarative setup

#### Qubes
- Work qube with restricted firewall (HTTP/HTTPS/DNS only)
- Vault qube (air-gapped, no network)
- Anon qube (Tor/Whonix integration)
- Untrusted qube (DisposableVM template)
- Optional VPN qube (ProxyVM)
- Optional USB qube (device management)

#### Features
- Topology presets (journalist, developer, researcher, teacher, pentester)
- Interactive setup wizard
- Dry-run mode for testing
- Comprehensive logging
- Rollback mechanism
- Progress indicators
- Health checks
- Split-GPG automation
- Split-SSH automation
- Qrexec policy generation
- Firewall rule automation
- Automated backups with cron
- Template update automation

#### Tools
- `qubes-status.sh` - Status dashboard
- `qubes-dashboard.sh` - Interactive real-time monitor
- `qubes-firewall-analyzer.sh` - Firewall analysis
- `qubes-template-manager.sh` - Template management
- `qubes-backup-validator.sh` - Backup verification
- `qubes-restore.sh` - Disaster recovery
- `qubes-policy-generator.sh` - Qrexec policy management

#### Documentation
- Comprehensive README with architecture diagrams
- QUICKSTART guide for rapid deployment
- CONTRIBUTING guidelines
- Complete wiki system with 10+ pages:
  - Getting Started
  - Installation Guide
  - Configuration Guide
  - Security Guide
  - Topology Presets
  - Split-GPG Guide
  - Split-SSH Guide
  - Backup & Restore Guide
  - Troubleshooting
  - FAQ
- Example configurations (journalist, developer, minimal)
- API documentation
- Tool documentation

#### Testing
- Syntax tests for all scripts
- Unit tests for components
- Integration tests for system interactions
- Security tests for vulnerabilities
- Automated test runner

#### Wiki System
- Markdown to HTML builder
- Professional responsive design
- Interactive features (TOC, copy buttons)
- Search functionality
- Mobile-friendly layout

### Security
- Air-gapped vault enforced
- Default-deny firewall policies
- Minimal template usage
- DisposableVM for risky content
- Split-GPG/SSH key isolation
- Comprehensive security testing
- Input validation throughout
- No hardcoded credentials

### Documentation
- 10+ wiki pages with 4000+ lines
- README with feature overview
- QUICKSTART for rapid onboarding
- Example configurations
- Troubleshooting guides
- FAQ with 50+ questions
- Tool documentation
- API reference

## [Unreleased]

### Roadmap

#### v1.1.0 - Testing & Validation (Target: Q1 2026)
- [ ] Expand test coverage to 90%+
- [ ] Add integration tests for Qubes VM interactions
- [ ] Automated security regression testing
- [ ] Performance benchmarking suite

#### v1.2.0 - Enhanced Features (Target: Q2 2026)
- [ ] Web-based configuration UI
- [ ] Additional topology presets (privacy-focused, enterprise, minimal)
- [ ] Plugin system for custom qubes
- [ ] Automated security auditing tools

#### v1.3.0 - Enterprise Features (Target: Q3 2026)
- [ ] Multi-language support (i18n)
- [ ] Video tutorials and interactive guides
- [ ] Docker-based testing environment
- [ ] CI/CD pipeline integration examples

#### Future Considerations
- Performance optimization tools
- Integration with Qubes OS 4.3+ features
- Remote management capabilities (with proper security)
- Backup rotation and lifecycle management

## Version History

### [1.0.1] - 2025-12-17
- Security hardening release
- SHA-pinned all GitHub Actions
- Fixed security.txt expiration

### [1.0.0] - 2024-11-22
- Initial release
- Complete feature set
- Full documentation
- Production ready

---

## Types of Changes

- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes
