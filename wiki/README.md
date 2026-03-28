# Qubes SDP Wiki

Comprehensive documentation for the Qubes Software Development Platform.

## Overview

This wiki provides complete documentation for installing, configuring, and using Qubes SDP for secure, isolated work environments.

## Building the Wiki

```bash
# Build HTML from markdown
./build-wiki.sh

# Output will be in html/ directory
# Open html/index.html in a browser
```

## Serving the Wiki

```bash
# Start local server
cd html
python3 -m http.server 8080

# Open browser to http://localhost:8080
```

## Wiki Structure

### Pages

- **getting-started.md** - Quick start guide
- **installation.md** - Installation instructions
- **configuration.md** - Configuration guide
- **security-guide.md** - Security best practices
- **topology-presets.md** - Pre-configured setups
- **split-gpg.md** - GPG key management
- **split-ssh.md** - SSH key management
- **vpn-setup.md** - VPN qube configuration
- **backup-restore.md** - Backup and recovery
- **troubleshooting.md** - Common issues
- **faq.md** - Frequently asked questions
- **api-reference.md** - API documentation
- **contributing.md** - Contribution guidelines

### Templates

- **page.html** - Main page template with navigation

### Static Assets

- **css/style.css** - Stylesheet
- **js/main.js** - JavaScript for interactivity
- **images/** - Images and diagrams

## Adding Pages

1. Create new markdown file in `pages/`:
```bash
vim pages/new-page.md
```

2. Write content using markdown syntax

3. Add to navigation in `templates/page.html`

4. Rebuild wiki:
```bash
./build-wiki.sh
```

## Markdown Features

The wiki builder supports:

- Headings: `# H1`, `## H2`, etc.
- Lists: `* item` or `1. item`
- Code: `` `inline` `` or ` ```block``` `
- Links: `[text](url)`
- Emphasis: `*italic*` or `**bold**`

## Development

### Requirements

- Bash
- Python 3 (for serving)
- Markdown processor (optional, for advanced features)

### Enhancing the Builder

For production use, consider:

- Use pandoc for markdown conversion
- Add syntax highlighting (highlight.js)
- Implement search functionality
- Generate table of contents automatically
- Add PDF export capability

### Example with Pandoc

```bash
# Install pandoc
sudo dnf install pandoc  # Fedora
sudo apt-get install pandoc  # Debian

# Convert with pandoc
pandoc -s -f markdown -t html5 \
    --template=template.html \
    --toc \
    --highlight-style=pygments \
    input.md -o output.html
```

## Contributing

Contributions to the wiki are welcome:

- Fix typos and errors
- Add missing information
- Improve explanations
- Add examples
- Create new pages

See **CONTRIBUTING.md** for guidelines.

## License

Documentation is licensed under CC-BY-SA 4.0

## Support

- Report issues via issue tracker
- Discuss on forums
- Contribute via pull requests
