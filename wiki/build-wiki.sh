#!/bin/bash
# Qubes SDP Wiki Builder
# Converts markdown pages to HTML wiki

set -e

WIKI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAGES_DIR="${WIKI_DIR}/pages"
OUTPUT_DIR="${WIKI_DIR}/html"
TEMPLATES_DIR="${WIKI_DIR}/templates"
STATIC_DIR="${WIKI_DIR}/static"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[WIKI]${NC} $*"
}

success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

# Create output directory
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/static"

# Copy static files
log "Copying static files..."
cp -r "${STATIC_DIR}"/* "${OUTPUT_DIR}/static/" 2>/dev/null || true

# Read template
TEMPLATE=$(<"${TEMPLATES_DIR}/page.html")

# Convert markdown to HTML
convert_page() {
    local md_file=$1
    local base_name=$(basename "${md_file}" .md)
    local html_file="${OUTPUT_DIR}/${base_name}.html"

    log "Converting ${base_name}.md..."

    # Read markdown content
    local content=$(<"${md_file}")

    # Simple markdown to HTML conversion
    # (In production, use pandoc or a proper markdown processor)
    content=$(echo "${content}" | \
        sed 's/^# \(.*\)/<h1>\1<\/h1>/g' | \
        sed 's/^## \(.*\)/<h2>\1<\/h2>/g' | \
        sed 's/^### \(.*\)/<h3>\1<\/h3>/g' | \
        sed 's/^#### \(.*\)/<h4>\1<\/h4>/g' | \
        sed 's/^\* \(.*\)/<li>\1<\/li>/g' | \
        sed 's/^\([0-9]\+\)\. \(.*\)/<li>\2<\/li>/g' | \
        sed 's/\*\*\([^*]*\)\*\*/<strong>\1<\/strong>/g' | \
        sed 's/\*\([^*]*\)\*/<em>\1<\/em>/g' | \
        sed 's/`\([^`]*\)`/<code>\1<\/code>/g' | \
        sed 's/\[\([^]]*\)\](\([^)]*\))/<a href="\2">\1<\/a>/g')

    # Wrap consecutive <li> tags in <ul>
    content=$(echo "${content}" | perl -0pe 's/(<li>.*?<\/li>\n)+/<ul>\n$&<\/ul>\n/gs')

    # Get title from first h1
    local title=$(echo "${content}" | grep -oP '<h1>\K[^<]+' | head -1 || echo "${base_name}")

    # Replace template variables
    local output="${TEMPLATE}"
    output="${output//\{\{TITLE\}\}/${title}}"
    output="${output//\{\{CONTENT\}\}/${content}}"

    echo "${output}" > "${html_file}"

    success "${base_name}.html created"
}

# Build index
build_index() {
    log "Building index..."

    local index_content="<h1>Qubes SDP Wiki</h1>"
    index_content+="<p>Documentation for the Qubes Software Development Platform</p>"
    index_content+="<h2>Pages</h2><ul>"

    for page in "${PAGES_DIR}"/*.md; do
        if [ -f "${page}" ]; then
            local name=$(basename "${page}" .md)
            local title=$(grep '^# ' "${page}" | head -1 | sed 's/^# //' || echo "${name}")
            index_content+="<li><a href=\"${name}.html\">${title}</a></li>"
        fi
    done

    index_content+="</ul>"

    local output="${TEMPLATE}"
    output="${output//\{\{TITLE\}\}/Qubes SDP Wiki}"
    output="${output//\{\{CONTENT\}\}/${index_content}}"

    echo "${output}" > "${OUTPUT_DIR}/index.html"

    success "Index created"
}

# Main build process
main() {
    log "Building Qubes SDP Wiki..."

    # Convert all markdown pages
    for md_file in "${PAGES_DIR}"/*.md; do
        if [ -f "${md_file}" ]; then
            convert_page "${md_file}"
        fi
    done

    # Build index
    build_index

    success "Wiki build complete!"
    log "Output directory: ${OUTPUT_DIR}"
    log "Open ${OUTPUT_DIR}/index.html in a browser"
}

main "$@"
