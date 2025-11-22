# Maintainers

This document lists the maintainers of the Qubes SDP project and explains the governance model.

## Current Maintainers

### Lead Maintainer

* **Name:** [To be designated]
* **GitHub:** [@username]
* **Email:** lead@qubes-sdp.org
* **Responsibilities:**
  - Final decision on contentious issues
  - Release management
  - Security coordination
  - Community health

### Core Maintainers

*(To be added as project grows)*

* **Name:** [Contributor Name]
  - **Focus Areas:** Setup scripts, automation
  - **GitHub:** [@username]
  - **Email:** [email]

* **Name:** [Contributor Name]
  - **Focus Areas:** Documentation, wiki
  - **GitHub:** [@username]
  - **Email:** [email]

* **Name:** [Contributor Name]
  - **Focus Areas:** Testing, CI/CD
  - **GitHub:** [@username]
  - **Email:** [email]

## Governance Model

### TPCF Perimeter 3 - Community Sandbox

This project operates in **TPCF Perimeter 3**, which means:

* **Open contribution** - Anyone can contribute
* **Meritocracy** - Contributions judged on technical merit
* **No corporate control** - Independent from any single organization
* **Community-driven** - Decisions made by consensus when possible
* **Maintainer discretion** - Final decisions when consensus fails

### Decision Making

#### Consensus-Driven

For most decisions, we seek consensus among:
1. Active contributors (3+ merged PRs in last 6 months)
2. Core maintainers
3. Community feedback (issues, discussions)

**Process:**
1. Proposal posted as GitHub Discussion or Issue
2. Minimum 7 days for feedback
3. Address concerns and iterate
4. If consensus reached, implement
5. If no consensus, maintainer makes final call

#### Maintainer Decision

For urgent or contentious issues:
1. Lead maintainer has final say
2. Decision must be explained publicly
3. Appeals can be made (see CODE_OF_CONDUCT.md)

### Areas Requiring Consensus

* Breaking API changes
* License changes
* Security policy changes
* Code of Conduct changes
* Adding/removing maintainers
* Project direction (major features)

### Areas for Maintainer Decision

* Bug fixes
* Documentation improvements
* Dependency updates
* Minor features (aligned with roadmap)
* Code style consistency
* Issue triage

## Becoming a Maintainer

Maintainers are not appointed arbitrarily. The path is:

### 1. Consistent Contribution (6+ months)

* Regular PRs (documentation, code, tests)
* Quality contributions (thorough, well-tested)
* Community engagement (helping others, reviews)
* Alignment with project values

### 2. Domain Expertise

Demonstrate deep knowledge in at least one area:
* Qubes OS architecture
* Security best practices
* Bash scripting
* Salt Stack
* Documentation
* Community management

### 3. Trust Building

* Respectful communication
* Collaborative approach
* Follows Code of Conduct
* Constructive code reviews
* Helps newcomers

### 4. Nomination

Current maintainers discuss and nominate candidates:
* Lead maintainer initiates discussion
* Consensus among current maintainers
* Public announcement and invitation
* Nominee accepts or declines

### 5. Onboarding

New maintainers receive:
* Repository write access
* Maintainer documentation
* Security disclosure access
* Community contact information
* Mentorship from existing maintainer

## Maintainer Responsibilities

### Code Review

* Respond to PRs within 7 days
* Provide constructive feedback
* Ensure code quality standards
* Verify tests pass
* Check security implications

### Issue Triage

* Label issues appropriately
* Close duplicates/spam
* Ask for clarification
* Welcome newcomers
* Identify good-first-issues

### Community

* Be welcoming and inclusive
* Model Code of Conduct
* Help onboard contributors
* Recognize contributions
* Manage conflict constructively

### Security

* Monitor security reports
* Coordinate vulnerability disclosure
* Review security-sensitive changes
* Maintain SECURITY.md
* Update .well-known/security.txt

### Release Management

* Follow semantic versioning
* Maintain CHANGELOG.md
* Tag releases appropriately
* Update documentation
* Announce releases

### Time Commitment

Maintainers should expect:
* **Minimum:** 4 hours/month (issue triage, PR review)
* **Typical:** 8-10 hours/month (above + features)
* **Active releases:** 15-20 hours/month (release prep, testing)

**Note:** This is volunteer work. Life happens. Communicate unavailability.

## Stepping Down

Maintainers can step down anytime:

1. **Notify** other maintainers privately
2. **Transition** ongoing work
3. **Remove** yourself from MAINTAINERS.md
4. **Announce** publicly (optional)

**No explanation required.** We respect your time and privacy.

### Emeritus Status

Former maintainers who contributed significantly:
* Listed in ACKNOWLEDGMENTS.md
* Retain recognition in git history
* Can return as maintainer if desired
* Invited to occasional discussions

## Inactive Maintainers

If a maintainer is inactive (no activity for 6+ months):

1. **Outreach** - Check if they're okay, need help
2. **Transition** - Reassign their responsibilities
3. **Move to emeritus** - Remove write access, list as emeritus
4. **No penalty** - Can return anytime

## Conflict Resolution

### Among Maintainers

1. **Private discussion** - Try to resolve directly
2. **Mediation** - Another maintainer mediates
3. **Lead decision** - Lead maintainer decides
4. **Last resort** - Vote (simple majority)

### With Community

1. **Public discussion** - In issue/PR/discussion
2. **Code of Conduct** - Follow enforcement guidelines
3. **Appeal process** - See CODE_OF_CONDUCT.md

## Contact

### Public

* **GitHub Discussions:** For feature requests, Q&A
* **GitHub Issues:** For bugs, improvements
* **Email:** contribute@qubes-sdp.org

### Private

* **Security:** security@qubes-sdp.org
* **Code of Conduct:** conduct@qubes-sdp.org
* **Maintainers:** maintainers@qubes-sdp.org

## Acknowledgments

We're grateful to all contributors, past and present:

* Contributors (1+ merged PR): See git history
* Community helpers: Forum/chat moderators
* Testers: Those who test in production
* Documenters: Wiki and guide writers
* Security researchers: Responsible disclosure

## Updates

This document is reviewed semi-annually and updated as needed.

**Version:** 1.0.0
**Last Updated:** 2024-11-22

---

## For Prospective Maintainers

Interested in becoming a maintainer?

1. **Start contributing** - Pick an issue, submit PRs
2. **Be patient** - Build trust over months, not weeks
3. **Ask questions** - We're happy to mentor
4. **Have fun** - This is volunteer work; enjoy it!

Welcome to the community! 🎉
