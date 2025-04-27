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
    if [[ "${DEVSTOCK_DEBUG}" == "true" ]]; then
        # Debug flag forces full output
        "$@"
    elif [[ "${SCRIPT_MODE}" == "ci" ]]; then
        # CI mode: suppress stdout & stderr
        "$@" >/dev/null 2>&1
    else
        # Normal execution
        "$@"
    fi
}
