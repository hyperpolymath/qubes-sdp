#!/bin/bash
# Syntax Test - Checks bash script syntax

SCRIPT_TO_TEST="$1"

if [ -z "${SCRIPT_TO_TEST}" ]; then
    echo "Usage: $0 <script-to-test>"
    exit 1
fi

# Check if file exists
if [ ! -f "${SCRIPT_TO_TEST}" ]; then
    echo "ERROR: File not found: ${SCRIPT_TO_TEST}"
    exit 1
fi

# Check syntax with bash -n
if bash -n "${SCRIPT_TO_TEST}" 2>/dev/null; then
    exit 0
else
    echo "Syntax error in ${SCRIPT_TO_TEST}"
    bash -n "${SCRIPT_TO_TEST}"
    exit 1
fi
