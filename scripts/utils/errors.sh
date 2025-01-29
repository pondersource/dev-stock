#!/usr/bin/env bash

# Print error message to stderr
print_error() {
    local message="${1}"
    printf "Error: %s\n" "${message}" >&2
}

# Print error message and exit
error_exit() {
    print_error "${1}"
    exit 1
}

# Run command quietly in CI mode
run_quietly_if_ci() {
    if [ "${SCRIPT_MODE}" = "ci" ]; then
        "$@" >/dev/null 2>&1
    else
        "$@"
    fi
}
