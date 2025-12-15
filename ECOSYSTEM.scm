;; SPDX-License-Identifier: AGPL-3.0-or-later
;; SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
;; ECOSYSTEM.scm — qubes-sdp

(ecosystem
  (version "1.0.0")
  (name "qubes-sdp")
  (type "project")
  (purpose "Automated Qubes OS configuration system for secure, isolated work environments. Deploy a complete qube topology with one command.")

  (position-in-ecosystem
    "Part of hyperpolymath ecosystem. Follows RSR guidelines.")

  (related-projects
    (project (name "rhodium-standard-repositories")
             (url "https://github.com/hyperpolymath/rhodium-standard-repositories")
             (relationship "standard")))

  (what-this-is "Automated Qubes OS configuration system for secure, isolated work environments. Deploy a complete qube topology with one command.")
  (what-this-is-not "- NOT exempt from RSR compliance"))
