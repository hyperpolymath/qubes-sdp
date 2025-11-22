# Contributing to Qubes SDP

Thank you for your interest in contributing to Qubes SDP! This document provides guidelines for contributing to the project.

## Ways to Contribute

### Report Bugs

Found a bug? Please report it!

1. Check if the bug has already been reported
2. Create a new issue with:
   - Clear title
   - Detailed description
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (Qubes version, RAM, etc.)
   - Relevant logs

### Suggest Features

Have an idea for improvement?

1. Check existing issues/discussions
2. Create a feature request with:
   - Clear use case
   - Proposed solution
   - Potential alternatives
   - Impact assessment

### Improve Documentation

Documentation is crucial!

- Fix typos and grammar
- Clarify confusing sections
- Add missing information
- Create new wiki pages
- Add examples
- Translate to other languages

### Submit Code

Code contributions welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Development Setup

### Prerequisites

- Qubes OS 4.1+
- Git
- Bash
- Basic understanding of Qubes OS

### Getting Started

```bash
# Fork and clone
git clone https://github.com/yourusername/qubes-sdp.git
cd qubes-sdp

# Create feature branch
git checkout -b feature/your-feature-name

# Make changes
vi qubes-setup.sh

# Test changes
bash tests/run-tests.sh
```

## Coding Standards

### Bash Scripts

- Use `#!/bin/bash` shebang
- Set `set -e` for error handling
- Use descriptive variable names
- Add comments for complex logic
- Follow existing code style
- Use shellcheck for linting

Example:

```bash
#!/bin/bash
# Description of what this script does

set -e

# Configuration
QUBE_NAME="work"
QUBE_MEMORY="2048"

# Function with clear purpose
create_qube() {
    local name=$1
    local memory=$2

    # Check if exists
    if qvm-ls "${name}" &>/dev/null; then
        echo "Qube ${name} already exists"
        return 0
    fi

    # Create with error handling
    qvm-create --label green --memory "${memory}" "${name}" || \
        error_exit "Failed to create ${name}"
}
```

### Configuration Files

- Use clear key=value format
- Add comments for all options
- Group related settings
- Provide examples in comments
- Use consistent naming

### Documentation

- Use Markdown format
- Clear headings and structure
- Code examples with syntax highlighting
- Links to related docs
- Keep README and wiki in sync

## Testing

All code must be tested:

### Run Tests

```bash
# All tests
bash tests/run-tests.sh

# Specific test
bash tests/unit-tests.sh
bash tests/security-tests.sh
```

### Write Tests

Add tests for new features:

```bash
# In tests/unit-tests.sh
test_assert "New feature works" "[ result = expected ]"
```

### Manual Testing

1. Test in dry-run mode
2. Test in clean Qubes install (if possible)
3. Test with different configurations
4. Verify no unintended side effects

## Pull Request Process

### Before Submitting

✅ Code follows style guidelines
✅ All tests pass
✅ Documentation updated
✅ Commits are clear and atomic
✅ No merge conflicts
✅ Security implications considered

### PR Checklist

1. **Title**: Clear, concise description
2. **Description**:
   - What changes were made
   - Why they were needed
   - How to test them
3. **Tests**: All tests passing
4. **Docs**: Updated as needed
5. **Breaking changes**: Clearly noted

### Example PR Description

```markdown
## Summary

Add VPN qube support to advanced setup.

## Changes

- Add VPN qube configuration to qubes-config.conf
- Implement VPN qube creation in qubes-setup-advanced.sh
- Add VPN section to wiki documentation
- Create example VPN configuration

## Testing

- Tested with OpenVPN configuration
- Tested with WireGuard configuration
- Verified qube provides network to other qubes
- All existing tests still pass

## Breaking Changes

None

## Documentation

- Updated wiki/pages/vpn-setup.md
- Added examples/vpn-config.conf
- Updated README.md
```

## Commit Messages

Use clear, descriptive commit messages:

### Format

```
Short summary (50 chars or less)

Detailed description if needed:
- What was changed
- Why it was changed
- Any side effects

Related issue: #123
```

### Examples

Good:
```
Add VPN qube support

Implements VPN qube creation with configuration
for OpenVPN and WireGuard. Includes automatic
setup of ProxyVM configuration.

Fixes #45
```

Bad:
```
Fixed stuff
```

## Code Review

All PRs will be reviewed for:

- Correctness
- Security implications
- Code quality
- Test coverage
- Documentation
- Backward compatibility

Be patient and responsive to feedback!

## Security

### Reporting Security Issues

DO NOT create public issues for security vulnerabilities.

Email: security@example.com

Include:
- Description of vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Security Considerations

When contributing:

- Never hardcode credentials
- Validate all inputs
- Follow principle of least privilege
- Consider Qubes security model
- Test in dom0 carefully
- Document security implications

## Style Guide

### Bash

```bash
# Good
create_qube() {
    local name=$1
    qvm-create --label green "${name}"
}

# Bad
create_qube(){name=$1;qvm-create --label green $name}
```

### Documentation

```markdown
# Good

## Section Title

Clear explanation with:
- Bullet points
- Code examples
- Links to references

## Bad

section title
some text
```

### Configuration

```bash
# Good
# Enable work qube (true/false)
ENABLE_WORK="true"

# Bad
ENABLE_WORK=true  # enable work
```

## Adding New Features

### Planning

1. Discuss in issue first
2. Get feedback on approach
3. Consider alternatives
4. Plan backward compatibility

### Implementation

1. Create feature branch
2. Implement incrementally
3. Test thoroughly
4. Document extensively
5. Submit PR

### Example: Adding New Qube Type

1. **Update config**:
   - Add configuration variables
   - Add comments
   - Set defaults

2. **Update setup script**:
   - Add creation function
   - Add to main setup flow
   - Add validation

3. **Update tools**:
   - Add to status dashboard
   - Add to firewall analyzer
   - Update relevant tools

4. **Update docs**:
   - Add wiki page
   - Update README
   - Add examples
   - Update FAQ

5. **Add tests**:
   - Unit tests
   - Integration tests
   - Security tests

## Documentation Guidelines

### Wiki Pages

- Use clear structure
- Include examples
- Link related pages
- Keep up to date
- Add table of contents for long pages

### Code Comments

```bash
# Explain WHY, not WHAT
# Bad:
# Create qube
qvm-create work

# Good:
# Create work qube separately to apply custom firewall rules
qvm-create work
```

### README Updates

When adding features:
- Update feature list
- Add usage examples
- Update architecture diagrams
- Note version changes

## Community

### Communication

- Be respectful
- Be patient
- Be constructive
- Help others
- Ask questions

### Code of Conduct

- Harassment-free environment
- Respect diverse viewpoints
- Accept constructive criticism
- Focus on what's best for community

## License

By contributing, you agree that your contributions will be licensed under GPLv3.

## Recognition

Contributors are recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project README

## Questions?

- Create a discussion
- Ask in issues
- Check existing docs
- Join community chat

## Thank You!

Every contribution helps make Qubes SDP better for everyone. Whether it's code, documentation, testing, or feedback - it all matters!

---

Happy contributing! 🎉
