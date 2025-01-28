#!/usr/bin/env bash

# Extract platform variables from script path
extract_platform_variables() {
    # Extract the parent folder name as TEST_SCENARIO
    local test_scenario
    test_scenario="$(basename "$(dirname "${SOURCE}")")"

    # Extract the filename without the .sh extension
    local filename
    filename="$(basename "${SOURCE}" .sh)"

    # For login scenario, we only have one platform
    if [ "${test_scenario}" = "login" ]; then
        export TEST_SCENARIO="${test_scenario}"
        export EFSS_PLATFORM_1="${filename}"
        export EFSS_PLATFORM_2=""
        return
    fi

    # For other scenarios, split the filename at the correct hyphen
    # First remove the .sh extension
    local name_without_extension="${filename%.sh}"
    
    # Check if there's at least one hyphen
    if [[ "${name_without_extension}" != *-* ]]; then
        error_exit "Invalid filename format: ${filename}. Expected format: platform1-platform2.sh"
    fi
    
    # For cases like nextcloud-sm-nextcloud-sm.sh, we need to split at the middle
    # For cases like nextcloud-sm-owncloud.sh, we need to split after nextcloud-sm
    # We can do this by counting from the right and splitting at the correct position
    if [[ "${name_without_extension}" == *-*-*-* ]]; then
        # Case with 3 hyphens (like nextcloud-sm-nextcloud-sm)
        # Split at the second hyphen
        local platform1=$(echo "${name_without_extension}" | cut -d'-' -f1-2)
        local platform2=$(echo "${name_without_extension}" | cut -d'-' -f3-)
    else
        # Case with 1 or 2 hyphens
        # If it matches known pattern with platform1 containing a hyphen,
        # split at the second hyphen, otherwise split at the first
        if [[ "${name_without_extension}" == nextcloud-sm-* ]] || 
           [[ "${name_without_extension}" == owncloud-sm-* ]]; then
            local platform1=$(echo "${name_without_extension}" | cut -d'-' -f1-2)
            local platform2=$(echo "${name_without_extension}" | cut -d'-' -f3)
        else
            local platform1=$(echo "${name_without_extension}" | cut -d'-' -f1)
            local platform2=$(echo "${name_without_extension}" | cut -d'-' -f2-)
        fi
    fi
    
    # Export the variables so the rest of the script can use them
    export TEST_SCENARIO="${test_scenario}"
    export EFSS_PLATFORM_1="${platform1}"
    export EFSS_PLATFORM_2="${platform2}"
}

# Main setup function that orchestrates the initialization
setup() {
    # Get platform dependent variables
    extract_platform_variables

    # Ensure required commands (including Docker) are available
    ensure_required_commands
    ensure_docker_running

    # Parse CLI arguments based on test scenario
    if [ "${TEST_SCENARIO}" = "login" ]; then
        parse_login_arguments "$@"
    else
        parse_share_arguments "$@"
    fi

    # Validate required files/directories
    validate_files

    # Prepare the environment
    prepare_environment
} 