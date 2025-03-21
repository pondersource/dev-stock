#!/usr/bin/env bash

# Run CI mode
run_ci() {
    # Print message (quiet in CI mode)
    run_quietly_if_ci echo "Running tests in CI mode..."

    # Validate arguments based on scenario
    if [ "${TEST_SCENARIO}" = "login" ]; then
        if [[ -z "${EFSS_PLATFORM_1}" ]]; then
            error_exit "Usage for login: <platform> <version> ci <browser>"
        fi
    else
        if [[ -z "${EFSS_PLATFORM_1}" || -z "${EFSS_PLATFORM_2}" ]]; then
            error_exit "Usage for test script: <platform1>-<platform2>.sh <version1> <version2> ci <browser>"
        fi
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

    # Construct spec file path based on scenario
    local spec_path
    if [ "${TEST_SCENARIO}" = "login" ]; then
        # For login tests, we only need one platform version
        local p1_ver="${EFSS_PLATFORM_1_VERSION%%.*}"
        local platform_abbr
        case "${EFSS_PLATFORM_1}" in
            nextcloud)
                platform_abbr="nc"
                ;;
            owncloud)
                platform_abbr="oc"
                ;;
            ocmstub)
                platform_abbr="os"
                ;;
            seafile)
                platform_abbr="sf"
                ;;
            *)
                platform_abbr="${EFSS_PLATFORM_1}"
                ;;
        esac
        spec_path="cypress/e2e/${TEST_SCENARIO}/${platform_abbr}-${p1_ver}.cy.js"
    else
        # For share tests, we need both platform versions
        local p1_ver="${EFSS_PLATFORM_1_VERSION%%.*}"
        local p2_ver="${EFSS_PLATFORM_2_VERSION%%.*}"
        spec_path="cypress/e2e/${TEST_SCENARIO}/${EFSS_PLATFORM_1}-${p1_ver}-to-${EFSS_PLATFORM_2}-${p2_ver}.cy.js"
    fi

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
