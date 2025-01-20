#!/usr/bin/env bash

# Run CI mode
run_ci() {
    # Print message (quiet in CI mode)
    run_quietly_if_ci echo "Running tests in CI mode..."

    # Validate arguments
    local test_scenario="${1}"
    local efss_platform_1="${2}"
    local efss_platform_2="${3}"

    if [[ -z "${test_scenario}" || -z "${efss_platform_1}" || -z "${efss_platform_2}" ]]; then
        error_exit "Usage: run_ci <test_scenario> <efss_platform_1> <efss_platform_2>"
    fi

    # Cypress config file path
    local cypress_config="${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"

    # Ensure the config file actually exists
    if [[ ! -f "${cypress_config}" ]]; then
        error_exit "Cypress config file not found at '${cypress_config}'."
    fi

    # Adjust Cypress configurations for non-default browser platforms
    if [[ "${BROWSER_PLATFORM}" != "electron" ]]; then
        # Disable video and video compression
        sed -i 's/.*video: true,.*/video: false,/' "${cypress_config}"
        sed -i 's/.*videoCompression: true,.*/videoCompression: false,/' "${cypress_config}"
    fi

    # Extract major version numbers for EFSS platforms
    local p1_ver="${EFSS_PLATFORM_1_VERSION%%.*}"
    local p2_ver="${EFSS_PLATFORM_2_VERSION%%.*}"

    # Construct spec file path from the arguments
    local spec_path="cypress/e2e/${test_scenario}/${efss_platform_1}-${p1_ver}-to-${efss_platform_2}-${p2_ver}.cy.js"

    # Run Cypress tests in headless mode
    if ! create_cypress_ci "${spec_path}"; then
        error_exit "Failed to run Cypress tests with spec '${spec_path}'."
    fi

    # Revert Cypress configuration changes if we modified them
    if [[ "${BROWSER_PLATFORM}" != "electron" ]]; then
        sed -i 's/.*video: false,.*/  video: true,/' "${cypress_config}"
        sed -i 's/.*videoCompression: false,.*/  videoCompression: true,/' "${cypress_config}"
    fi

    # Perform cleanup after CI tests
    echo "Cleaning up test environment..."
    if [[ -x "${ENV_ROOT}/scripts/clean.sh" ]]; then
        "${ENV_ROOT}/scripts/clean.sh" "no"
    else
        print_error "Cleanup script not found or not executable at '${ENV_ROOT}/scripts/clean.sh'."
    fi
}
