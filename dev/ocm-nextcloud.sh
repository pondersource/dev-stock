#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Nextcloud Development Environment Setup Script
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# ------------------------------------------------------------------------------
#
# Description:
#   This script automates the setup of a Nextcloud development environment using
#   Docker containers. It handles container creation, configuration, and volume
#   mounting for development purposes.
#
# Features:
#   - Creates Nextcloud containers with configurable versions
#   - Supports development volume mounts for live code updates
#   - Includes Firefox container for testing
#   - Configurable user credentials
#
# Usage:
#   ./ocm-nextcloud.sh [options]
#
# Environment Variables:
#   NEXTCLOUD_DEV_VOLUMES - Comma-separated list of volume mounts
#   Example: "local_path:/container_path,local_path2:/container_path2"
#
# Dependencies:
#   - Docker must be installed and running
#   - Bash 4.0 or later
#   - utils.sh script must be available in scripts/utils/
# ------------------------------------------------------------------------------

# Exit on error, undefined vars, or pipe failures
set -euo pipefail

# ------------------------------------------------------------------------------
# Default Configuration
# ------------------------------------------------------------------------------

# Default Nextcloud version for development
# Format: vX.Y.Z-suffix (e.g., v30.0.10-contacts)
DEFAULT_EFSS_1_VERSION="v30.0.10-contacts"
DEFAULT_EFSS_2_VERSION="v30.0.10-contacts"

# Volume mounts for development (empty by default)
# Examples:
# 1. Developing contacts app:
#    NEXTCLOUD_DEV_VOLUMES="${ENV_ROOT}/contacts:/ponder/apps/contacts"
# 2. Custom initialization scripts:
#    NEXTCLOUD_DEV_VOLUMES="${ENV_ROOT}/contacts:/ponder/apps/contacts,${ENV_ROOT}/nc-contacts.sh:/docker-entrypoint-hooks.d/before-starting/contacts.sh"
NEXTCLOUD_DEV_VOLUMES=""

# -----------------------------------------------------------------------------------
# Function: resolve_script_dir
# Purpose : Resolves the absolute path of the script's directory, handling symlinks.
# Returns : 
#   Exports SOURCE, SCRIPT_DIR
# Note    : This function relies on BASH_SOURCE, so it must be used in a Bash shell.
# -----------------------------------------------------------------------------------
resolve_script_dir() {
    local source="${BASH_SOURCE[0]}"

    # Follow symbolic links until we get the real file location
    while [ -L "${source}" ]; do
        # Get the directory path where the symlink is located
        dir="$(cd -P "$(dirname "${source}")" >/dev/null 2>&1 && pwd)"
        # Use readlink to get the target the symlink points to
        source="$(readlink "${source}")"
        # If the source was a relative symlink, convert it to an absolute path
        [[ "${source}" != /* ]] && source="${dir}/${source}"
    done

    # After resolving symlinks, retrieve the directory of the final source
    SCRIPT_DIR="$(cd -P "$(dirname "${source}")" >/dev/null 2>&1 && pwd)"

    # Exports
    export SOURCE="${source}"
    export SCRIPT_DIR="${SCRIPT_DIR}"
}

# -----------------------------------------------------------------------------------
# Function: initialize_environment
# Purpose :
#   1) Resolve the script's directory.
#   2) Change into that directory plus an optional subdirectory (if provided).
#   3) Export ENV_ROOT as the new working directory.
#   4) Source a utility script (`utils.sh`) with optional version parameters.
#
# Arguments:
#   1) $1 - Relative or absolute path to a subdirectory (optional).
#           If omitted or empty, defaults to '.' (the same directory as resolve_script_dir).
#
# Usage Example:
#   initialize_environment        # Uses the script's directory
#   initialize_environment "dev"  # Changes to script's directory + "/dev"
# -----------------------------------------------------------------------------------
initialize_environment() {
    # Resolve script's directory
    resolve_script_dir

    # Local variables
    local subdir
    # Check if a subdirectory argument was passed; default to '.' if not
    subdir="${1:-.}"

    # Attempt to change into the resolved directory + the subdirectory
    if cd "${SCRIPT_DIR}/${subdir}"; then
        ENV_ROOT="$(pwd)"
        export ENV_ROOT
    else
        printf "Error: %s\n" "Failed to change directory to '${SCRIPT_DIR}/${subdir}'." >&2 && exit 1
    fi

    # shellcheck source=/dev/null
    # Source utility script (assuming it exists and is required for subsequent commands)
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
# This function orchestrates the development environment setup:
# 1. Initializes the environment and configuration
# 2. Creates Nextcloud container with specified version and mounts
# 3. Sets up Firefox container for testing
# 4. Displays setup instructions
#
# Arguments:
#   All command line arguments are passed through to setup function
#
# Environment:
#   Uses NEXTCLOUD_DEV_VOLUMES for volume mounting configuration
# ------------------------------------------------------------------------------
main() {
    # Initialize environment and parse arguments
    initialize_environment ".."
    setup "$@"
    
    # Create Nextcloud container with development configuration
    # Volume mounts for development (empty by default)
    # Examples:
    # 1. Developing contacts app:
    #    NEXTCLOUD_DEV_VOLUMES="${ENV_ROOT}/contacts:/ponder/apps/contacts"
    # 2. Custom initialization scripts:
    #    NEXTCLOUD_DEV_VOLUMES="${ENV_ROOT}/contacts:/ponder/apps/contacts,${ENV_ROOT}/nc-contacts.sh:/docker-entrypoint-hooks.d/before-starting/contacts.sh"
    #                    ID    Username     Password      Image                  Version                      Volumes
    create_nextcloud_dev 1     "einstein"   "relativity"  pondersource/nextcloud "${EFSS_PLATFORM_1_VERSION}" "${NEXTCLOUD_DEV_VOLUMES}"

    # Create Firefox container for testing
    create_firefox
    
    # Show reduced output in CI mode
    run_quietly_if_ci echo "Setting up development environment..."
    
    # Display access information
    print_development_instructions
    echo "https://nextcloud1.docker (username: einstein, password: relativity)"
}

# ------------------------------------------------------------------------------
# Script Entry Point
# ------------------------------------------------------------------------------
main "$@"
