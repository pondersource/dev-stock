#!/usr/bin/env bash

# Validate that required files and directories exist
validate_files() {
    # Check if TLS certificate files exist
    if [ ! -d "${ENV_ROOT}/${TLS_CERTIFICATES_DIR}" ]; then
        error_exit "TLS certificates directory not found: ${ENV_ROOT}/${TLS_CERTIFICATES_DIR}"
    fi
    if [ ! -d "${ENV_ROOT}/${TLS_CA_DIR}" ]; then
        error_exit "TLS certificate authority directory not found: ${ENV_ROOT}/${TLS_CA_DIR}"
    fi

    # Check if Firefox certificate files exist
    if [ ! -f "${ENV_ROOT}/docker/tls/browsers/firefox/cert9.db" ]; then
        error_exit "Firefox cert9.db file not found: ${ENV_ROOT}/docker/tls/browsers/firefox/cert9.db"
    fi
    if [ ! -f "${ENV_ROOT}/docker/tls/browsers/firefox/cert_override.txt" ]; then
        error_exit "Firefox cert_override.txt file not found: ${ENV_ROOT}/docker/tls/browsers/firefox/cert_override.txt"
    fi

    # Check if Cypress configuration exists
    if [ ! -f "${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js" ]; then
        error_exit "Cypress configuration file not found: ${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"
    fi
}

# Parse command-line arguments
parse_arguments() {
    EFSS_PLATFORM_1_VERSION="${1:-$DEFAULT_EFSS_1_VERSION}"
    EFSS_PLATFORM_2_VERSION="${2:-$DEFAULT_EFSS_2_VERSION}"
    SCRIPT_MODE="${3:-$DEFAULT_SCRIPT_MODE}"
    BROWSER_PLATFORM="${4:-$DEFAULT_BROWSER_PLATFORM}"

    export EFSS_PLATFORM_1_VERSION="${EFSS_PLATFORM_1_VERSION}"
    export EFSS_PLATFORM_2_VERSION="${EFSS_PLATFORM_2_VERSION}"
    export SCRIPT_MODE="${SCRIPT_MODE}"
    export BROWSER_PLATFORM="${BROWSER_PLATFORM}"
}
