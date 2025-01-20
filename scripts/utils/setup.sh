#!/usr/bin/env bash

# Extract platform variables from script path
extract_platform_variables() {
    # Extract the parent folder name as TEST_SCENARIO
    local test_scenario
    test_scenario="$(basename "$(dirname "${SOURCE}")")"

    # Extract the filename without the .sh extension
    local filename
    filename="$(basename "${SOURCE}" .sh)"

    # Split the filename by '-' to get EFSS_PLATFORM_1 and EFSS_PLATFORM_2
    local platform1 platform2
    IFS='-' read -r platform1 platform2 <<< "${filename}"

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

    # Parse CLI arguments
    parse_arguments "$@"

    # Validate required files/directories
    validate_files

    # Prepare the environment
    prepare_environment
} 