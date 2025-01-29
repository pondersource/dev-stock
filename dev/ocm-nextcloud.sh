#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Nextcloud to Nextcloud Testing Script
#
# This script automates end-to-end testing of OCM (Open Cloud Mesh) functionality
# between two Nextcloud instances. It handles setup, execution, and cleanup of
# test environments using Docker containers.
#
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# ------------------------------------------------------------------------------

# Exit on error, undefined vars, or pipe failures
set -euo pipefail

# ------------------------------------------------------------------------------
# Default Configuration
# ------------------------------------------------------------------------------

# Default Nextcloud versions for both instances
DEFAULT_EFSS_1_VERSION="v30.0.2-contacts"
DEFAULT_EFSS_2_VERSION="v30.0.2-contacts"

# Volume mounts for development
# Format: "local_path:container_path,local_path2:container_path2"
NEXTCLOUD_DEV_VOLUMES=""

# ------------------------------------------------------------------------------
# Function: resolve_script_dir
# Purpose: Resolves the absolute path of the script directory
#
# This function handles symlinks and ensures we have the correct working directory
# regardless of how the script is invoked.
#
# Exports:
#   SOURCE: The resolved path to the script file
#   SCRIPT_DIR: The resolved directory containing the script
# ------------------------------------------------------------------------------
resolve_script_dir() {
    local source="${BASH_SOURCE[0]}"
    
    # Follow symlinks to get real script location
    while [ -L "${source}" ]; do
        dir="$(cd -P "$(dirname "${source}")" >/dev/null 2>&1 && pwd)"
        source="$(readlink "${source}")"
        [[ "${source}" != /* ]] && source="${dir}/${source}"
    done
    
    SCRIPT_DIR="$(cd -P "$(dirname "${source}")" >/dev/null 2>&1 && pwd)"
    
    export SOURCE="${source}"
    export SCRIPT_DIR="${SCRIPT_DIR}"
}

# ------------------------------------------------------------------------------
# Function: initialize_environment
# Purpose: Sets up the testing environment
#
# This function:
# 1. Resolves the script directory
# 2. Changes to the specified working directory
# 3. Sources utility functions
# 4. Exports environment variables
#
# Arguments:
#   $1: Target subdirectory (optional, defaults to current directory)
#
# Exports:
#   ENV_ROOT: The root directory for test execution
# ------------------------------------------------------------------------------
initialize_environment() {
    # Resolve script location
    resolve_script_dir
    
    # Set working directory
    local subdir
    subdir="${1:-.}"
    
    if cd "${SCRIPT_DIR}/${subdir}"; then
        ENV_ROOT="$(pwd)"
        export ENV_ROOT
    else
        printf "Error: %s\n" "Failed to change directory to '${SCRIPT_DIR}/${subdir}'." >&2 && exit 1
    fi
    
    # Source utility functions
    if [[ -f "${ENV_ROOT}/scripts/utils.sh" ]]; then
        source "${ENV_ROOT}/scripts/utils.sh" "${DEFAULT_EFSS_1_VERSION}" "${DEFAULT_EFSS_2_VERSION}"
    else
        printf "Error: %s\n" "Could not source '${ENV_ROOT}/scripts/utils.sh' (file not found)." >&2 && exit 1
    fi
}

# ------------------------------------------------------------------------------
# Function: main
# Purpose: Main script execution
#
# This function orchestrates the test execution:
# 1. Initializes the environment
# 2. Creates Nextcloud containers with development mounts
# 3. Sets up test configuration
# 4. Executes tests based on mode
#
# Arguments:
#   All command line arguments are passed through
# ------------------------------------------------------------------------------
main() {
    # Initialize environment and parse arguments
    initialize_environment ".."
    setup "$@"
    
    # Create Nextcloud container with development configuration and volume mounts
    #                    ID    Username     Password      Image                  Version                      Volumes
    create_nextcloud_dev 1     "einstein"   "relativity"  pondersource/nextcloud "${EFSS_PLATFORM_1_VERSION}" "${ENV_ROOT}/contatcs:/ponder/apps/contacts"

    # Create container for Firefox
    create_firefox
    
    # Show reduced output in CI mode
    run_quietly_if_ci echo "Setting up development environment..."
    
    print_development_instructions
    echo "https://nextcloud1.docker (username: einstein, password: relativity)"
}

# ------------------------------------------------------------------------------
# Script Entry Point
# ------------------------------------------------------------------------------
main "$@"
