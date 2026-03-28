# CLAUDE.md

This document provides guidance for using Claude Code with the Qubes SDP (Software Development Platform) repository.

## Overview

This repository contains the Qubes Software Development Platform, designed to facilitate secure development workflows within the Qubes OS environment.

## Working with Claude Code

### Getting Started

When working with Claude Code on this project, you can:

1. **Explore the codebase**: Ask Claude to explain components, trace functionality, or understand architecture
2. **Implement features**: Request new functionality with clear requirements
3. **Debug issues**: Share error messages or unexpected behavior for investigation
4. **Refactor code**: Ask for improvements to code structure, performance, or maintainability
5. **Review changes**: Request code reviews before committing

### Project Structure

The repository follows a standard Qubes OS project structure:

- Configuration files for Qubes integration
- Development tools and scripts
- Documentation
- Source code organized by component

### Development Workflow

When asking Claude to help with development:

1. **Be specific**: Clearly describe what you want to achieve
2. **Provide context**: Share relevant error messages, logs, or requirements
3. **Incremental changes**: Request changes in logical steps
4. **Test as you go**: Ask Claude to help write tests or validate functionality

### Qubes OS Specific Considerations

When working with Qubes-related code:

- **Security first**: All changes should maintain Qubes' security model
- **Domain isolation**: Respect VM boundaries and inter-qube communication patterns
- **Qrexec protocols**: When working with qrexec, ensure proper validation and security
- **Salt stack integration**: Follow Qubes' configuration management patterns
- **Documentation**: Keep documentation updated for any qube-specific functionality

### Common Tasks

#### Code Review
```
Review the changes in [file/component] for security issues and best practices
```

#### Feature Implementation
```
Implement [feature] that [does X] while maintaining compatibility with Qubes [version]
```

#### Debugging
```
I'm seeing [error/behavior]. The relevant code is in [location]. Can you help diagnose?
```

#### Testing
```
Create tests for [component] that verify [functionality]
```

### Git Workflow

Claude Code can help with git operations:

- Creating feature branches
- Writing commit messages
- Reviewing diffs before committing
- Preparing pull requests

All changes will be committed to feature branches following the pattern `claude/*`.

### Best Practices

1. **Security Review**: Always review generated code for security implications
2. **Test in Qubes**: Test changes in an actual Qubes environment when possible
3. **Documentation**: Update docs alongside code changes
4. **Incremental commits**: Make logical, atomic commits
5. **Code style**: Follow existing patterns in the codebase

### Tips for Effective Collaboration

- **Ask for explanations**: If generated code is unclear, ask Claude to explain
- **Request alternatives**: Ask for different approaches when evaluating options
- **Iterative refinement**: Start with a basic implementation and refine
- **Context sharing**: Share relevant background about the Qubes environment

### Limitations

Be aware that Claude Code:

- Cannot execute code in actual Qubes VMs
- Cannot access running qube states
- Cannot test qrexec calls between qubes
- Should have changes validated in a real Qubes environment

### Getting Help

For issues specific to:
- **Claude Code**: Use `/help` or visit https://docs.claude.com/claude-code
- **This repository**: Check documentation or open an issue
- **Qubes OS**: Consult https://www.qubes-os.org/doc/

## Example Interactions

### Exploring Code
```
What does the [component] do and how does it integrate with Qubes?
```

### Adding Features
```
Add support for [feature] that works across qubes using qrexec
```

### Security Analysis
```
Review [component] for potential security issues in a Qubes context
```

### Documentation
```
Generate documentation for [module] explaining its purpose and usage
```

## Contributing

When using Claude Code to contribute:

1. Work on feature branches (automatically managed)
2. Ensure changes pass any existing tests
3. Update documentation as needed
4. Request code review before merging
5. Follow Qubes OS contribution guidelines

## Additional Resources

- [Qubes OS Documentation](https://www.qubes-os.org/doc/)
- [Qubes OS Development Guide](https://www.qubes-os.org/doc/development-workflow/)
- [Claude Code Documentation](https://docs.claude.com/claude-code)

---

**Note**: This file helps optimize collaboration between developers and Claude Code. Keep it updated as the project evolves.
