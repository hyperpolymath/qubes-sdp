;;; STATE.scm - Qubes SDP Project State
;;; Checkpoint/restore for AI conversation context
;;; Format: https://github.com/hyperpolymath/state.scm
;;; ============================================================

(define-module (qubes-sdp state)
  #:use-module (srfi srfi-19)  ; Date/time
  #:export (state))

;;; ============================================================
;;; METADATA
;;; ============================================================

(define metadata
  '((format-version . "1.0.0")
    (state-created . "2024-11-22T00:00:00Z")
    (state-updated . "2025-12-08T00:00:00Z")
    (project-name . "qubes-sdp")
    (project-version . "1.0.0")
    (license . "MIT + Palimpsest v0.8")
    (repository . "https://github.com/hyperpolymath/qubes-sdp")))

;;; ============================================================
;;; CURRENT POSITION
;;; ============================================================

(define current-position
  '((status . production-ready)
    (phase . maintenance)
    (completion-percent . 95)
    (maturity-level . "v1.0.0 Released")

    (core-features-complete
     (topology-setup . #t)          ; One-command qube creation
     (config-system . #t)           ; Comprehensive configuration
     (security-enforcement . #t)    ; Air-gap, firewalls, split-GPG
     (management-tools . #t)        ; 7 operational tools
     (testing-framework . #t)       ; Syntax, unit, integration, security
     (documentation . #t)           ; 4,238 lines of wiki + docs
     (salt-stack . #t)              ; Declarative IaC support
     (build-systems . #t)           ; Make, Just, Nix flakes
     (ci-cd . #t)                   ; CodeQL, SLSA3, Dependabot
     (governance . #t))             ; TPCF Perimeter 3, RSR Gold

    (deployment-methods
     (simple-script . complete)     ; qubes-setup.sh (442 lines)
     (advanced-script . complete)   ; qubes-setup-advanced.sh (1,281 lines)
     (interactive-wizard . complete)
     (salt-stack . complete)
     (nix-flake . complete))

    (topology-presets
     (journalist . complete)
     (developer . complete)
     (researcher . partial)
     (teacher . partial)
     (pentester . partial)
     (minimal . complete))

    (qube-types-supported
     (work . "green, 2GB, HTTP/HTTPS/DNS")
     (vault . "black, 1GB, air-gapped")
     (anon . "purple, 1GB, Tor/Whonix")
     (untrusted . "red, 1GB, disposable")
     (vpn . "optional, ProxyVM")
     (usb . "optional, USB management"))))

;;; ============================================================
;;; ROUTE TO MVP v1 (ACHIEVED)
;;; ============================================================

(define mvp-v1-roadmap
  '((status . COMPLETE)
    (release-date . "2024-11-22")

    (milestones-achieved
     ((name . "Core Setup System")
      (status . complete)
      (deliverables
       "One-command topology creation"
       "Config-driven setup with 40+ settings"
       "Dry-run and rollback capabilities"
       "Progress indicators and logging"))

     ((name . "Security Foundation")
      (status . complete)
      (deliverables
       "Enforced air-gapped vault"
       "Default-deny firewall policies"
       "Split-GPG/SSH automation"
       "Qrexec policy generation"
       "Input validation throughout"))

     ((name . "Management Tooling")
      (status . complete)
      (deliverables
       "qubes-status.sh - Real-time dashboard"
       "qubes-dashboard.sh - Interactive monitoring"
       "qubes-firewall-analyzer.sh"
       "qubes-template-manager.sh"
       "qubes-backup-validator.sh"
       "qubes-restore.sh - Disaster recovery"
       "qubes-policy-generator.sh"))

     ((name . "Documentation")
      (status . complete)
      (deliverables
       "9 wiki pages (4,238 lines)"
       "QUICKSTART.md - 3-step guide"
       "SECURITY.md - Threat model"
       "Example configurations"
       "Troubleshooting guide"))

     ((name . "Testing & Quality")
      (status . complete)
      (deliverables
       "Syntax validation tests"
       "Unit test framework"
       "Integration tests"
       "Security vulnerability tests"
       "ShellCheck linting"))

     ((name . "Compliance & Governance")
      (status . complete)
      (deliverables
       "RSR Framework Gold compliance"
       "TPCF Perimeter 3 governance"
       "RFC 9116 security.txt"
       "MAINTAINERS.md with roles"
       "CODE_OF_CONDUCT.md")))))

;;; ============================================================
;;; KNOWN ISSUES & GAPS
;;; ============================================================

(define known-issues
  '((category . technical)
    (issues
     ((id . "ISSUE-001")
      (severity . low)
      (title . "Topology presets need refinement")
      (description . "researcher, teacher, pentester presets are basic skeletons")
      (impact . "Users must customize heavily for non-journalist/developer use cases")
      (remediation . "Flesh out preset configurations with use-case-specific settings"))

     ((id . "ISSUE-002")
      (severity . low)
      (title . "Template auto-installation opt-in")
      (description . "AUTO_INSTALL_TEMPLATES defaults to false")
      (impact . "First-time users may need manual template setup")
      (remediation . "Consider safer auto-detection of missing templates"))

     ((id . "ISSUE-003")
      (severity . medium)
      (title . "No automated end-to-end testing in actual Qubes")
      (description . "Tests run syntax/unit level but not in real Qubes VMs")
      (impact . "Integration issues may not surface until user deployment")
      (remediation . "Create Qubes-based CI/CD testing environment"))

     ((id . "ISSUE-004")
      (severity . low)
      (title . "Backup automation integration")
      (description . "Cron job setup exists but is not deeply integrated")
      (impact . "Users must manually configure backup schedules")
      (remediation . "Add interactive backup wizard to setup flow"))

     ((id . "ISSUE-005")
      (severity . info)
      (title . "No GUI/web interface")
      (description . "CLI-only currently; planned for future")
      (impact . "Steeper learning curve for non-technical users")
      (remediation . "Roadmap item: web-based configuration UI")))))

;;; ============================================================
;;; QUESTIONS FOR MAINTAINER
;;; ============================================================

(define questions-for-maintainer
  '((context . "Clarifications needed for roadmap prioritization")
    (questions
     ((id . "Q1")
      (question . "What is the primary target audience going forward?")
      (options
       "Journalists (current strong support)"
       "Developers (current strong support)"
       "Security researchers (needs preset work)"
       "General Qubes users"
       "Enterprise/organizational deployments")
      (impact . "Determines which presets and features to prioritize"))

     ((id . "Q2")
      (question . "Is a web-based configuration UI a priority?")
      (context . "Currently mentioned in roadmap but no timeline")
      (considerations
       "Would significantly lower barrier to entry"
       "Adds maintenance burden and attack surface"
       "Could be a separate complementary project")
      (impact . "Major architectural decision affecting v2.0 scope"))

     ((id . "Q3")
      (question . "What Qubes OS versions should be supported?")
      (current . "Assumes Qubes 4.x compatibility")
      (considerations
       "Qubes 4.2+ has different template handling"
       "Salt Stack syntax may vary between versions"
       "Should minimum version be enforced?")
      (impact . "Testing matrix and compatibility scope"))

     ((id . "Q4")
      (question . "Interest in plugin/extension system?")
      (context . "Makefile has plugin-* targets but no plugin ecosystem")
      (considerations
       "Would enable community contributions"
       "Could modularize specialized workflows"
       "Adds complexity and maintenance")
      (impact . "Community growth and extensibility"))

     ((id . "Q5")
      (question . "Containerized testing environment priority?")
      (context . "Real Qubes testing not possible in standard CI")
      (options
       "Docker-based mock testing"
       "Dedicated Qubes test hardware"
       "Community testing program"
       "Accept current limitation")
      (impact . "Test coverage and regression prevention"))

     ((id . "Q6")
      (question . "Multi-language/i18n support timeline?")
      (context . "Mentioned in roadmap, no current implementation")
      (considerations
       "Security documentation translation is sensitive"
       "Community translators needed"
       "Which languages first?")
      (impact . "Global accessibility of the project")))))

;;; ============================================================
;;; LONG-TERM ROADMAP
;;; ============================================================

(define long-term-roadmap
  '((vision . "Become the standard secure development environment for Qubes OS")

    (v1.1-maintenance
     (status . planned)
     (focus . "Stability and preset refinement")
     (items
      ((item . "Refine researcher preset with data collection workflows")
       (priority . medium))
      ((item . "Refine teacher preset with student isolation patterns")
       (priority . medium))
      ((item . "Refine pentester preset with common tool integrations")
       (priority . medium))
      ((item . "Improve error messages and troubleshooting hints")
       (priority . low))
      ((item . "Add more example configurations")
       (priority . low))))

    (v1.5-enhanced-tooling
     (status . planned)
     (focus . "Operational improvements")
     (items
      ((item . "Interactive backup wizard in setup flow")
       (priority . medium))
      ((item . "Automated health check scheduling")
       (priority . low))
      ((item . "Enhanced qube resource monitoring")
       (priority . low))
      ((item . "Template version tracking and update notifications")
       (priority . medium))
      ((item . "Split-GPG/SSH status verification tool")
       (priority . medium))))

    (v2.0-major-features
     (status . future)
     (focus . "Major new capabilities")
     (items
      ((item . "Web-based configuration UI")
       (priority . high)
       (complexity . high)
       (notes . "Separate service running in dedicated qube"))
      ((item . "Plugin/extension system")
       (priority . medium)
       (complexity . medium)
       (notes . "Enable community workflow contributions"))
      ((item . "Multi-language support (i18n)")
       (priority . medium)
       (complexity . medium)
       (notes . "Start with Spanish, German, French"))
      ((item . "Video tutorial series")
       (priority . low)
       (complexity . low)
       (notes . "Complement written documentation"))))

    (v2.5-enterprise
     (status . future)
     (focus . "Organizational deployment")
     (items
      ((item . "Centralized policy management")
       (priority . medium))
      ((item . "Fleet deployment tooling")
       (priority . medium))
      ((item . "Audit logging and compliance reporting")
       (priority . medium))
      ((item . "Integration with identity providers")
       (priority . low))))

    (long-term-vision
     (status . aspirational)
     (items
      ((item . "Qubes OS upstream integration consideration"))
      ((item . "Hardware security module (HSM) support"))
      ((item . "Automated threat response workflows"))
      ((item . "Machine learning anomaly detection"))
      ((item . "Cross-platform secure development bridges"))))))

;;; ============================================================
;;; CRITICAL NEXT ACTIONS
;;; ============================================================

(define critical-next-actions
  '((last-updated . "2025-12-08")
    (actions
     ((priority . 1)
      (action . "Review and refine researcher topology preset")
      (context . "Basic skeleton exists, needs workflow-specific configuration")
      (deliverable . "Complete qubes-config-researcher.conf example")
      (blocking . #f))

     ((priority . 2)
      (action . "Review and refine teacher topology preset")
      (context . "Basic skeleton exists, needs student isolation patterns")
      (deliverable . "Complete qubes-config-teacher.conf example")
      (blocking . #f))

     ((priority . 3)
      (action . "Review and refine pentester topology preset")
      (context . "Basic skeleton exists, needs security testing tool integration")
      (deliverable . "Complete qubes-config-pentester.conf example")
      (blocking . #f))

     ((priority . 4)
      (action . "Answer maintainer questions for roadmap prioritization")
      (context . "See questions-for-maintainer section")
      (deliverable . "Documented decisions on Q1-Q6")
      (blocking . "Blocks v2.0 planning"))

     ((priority . 5)
      (action . "Evaluate containerized testing options")
      (context . "Current tests cannot validate in real Qubes environment")
      (deliverable . "Recommendation on testing strategy")
      (blocking . #f)))))

;;; ============================================================
;;; HISTORY / VELOCITY
;;; ============================================================

(define project-history
  '((snapshots
     ((date . "2024-11-22")
      (version . "1.0.0")
      (milestone . "Initial production release")
      (completion . 95)
      (notes . "Full feature set, documentation, governance"))

     ((date . "2025-12-08")
      (version . "1.0.0")
      (milestone . "State documentation created")
      (completion . 95)
      (notes . "Added STATE.scm for conversation continuity")))))

;;; ============================================================
;;; DEPENDENCIES & BLOCKERS
;;; ============================================================

(define dependencies
  '((external
     ((name . "Qubes OS")
      (version . "4.x")
      (status . stable)
      (notes . "Primary platform dependency"))

     ((name . "Fedora templates")
      (version . "fedora-*-minimal")
      (status . stable)
      (notes . "Default template for most qubes"))

     ((name . "Debian templates")
      (version . "debian-*-minimal")
      (status . stable)
      (notes . "Alternative template option"))

     ((name . "Whonix")
      (version . "whonix-*")
      (status . stable)
      (notes . "Required for anon qube functionality")))

    (blockers
     ;; No current blockers for v1.x maintenance
     ())))

;;; ============================================================
;;; STATE EXPORT
;;; ============================================================

(define state
  `((metadata . ,metadata)
    (current-position . ,current-position)
    (mvp-v1-roadmap . ,mvp-v1-roadmap)
    (known-issues . ,known-issues)
    (questions-for-maintainer . ,questions-for-maintainer)
    (long-term-roadmap . ,long-term-roadmap)
    (critical-next-actions . ,critical-next-actions)
    (project-history . ,project-history)
    (dependencies . ,dependencies)))

;;; ============================================================
;;; USAGE
;;; ============================================================
;;;
;;; This file captures the complete project state for Qubes SDP.
;;;
;;; To resume context in a new Claude conversation:
;;; 1. Upload this STATE.scm file at the start of conversation
;;; 2. Claude will parse the state and resume with full context
;;;
;;; To update state:
;;; 1. At end of productive session, ask Claude to update STATE.scm
;;; 2. Download the updated file for next session
;;;
;;; Query examples (for future tooling):
;;; - (assoc 'status (assoc 'current-position state))
;;; - (filter blocked? (assoc 'critical-next-actions state))
;;; - (map 'item (assoc 'v2.0-major-features long-term-roadmap))
;;;
;;; ============================================================
