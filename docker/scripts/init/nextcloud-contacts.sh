#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Nextcloud Contacts App Initialization Script
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# ------------------------------------------------------------------------------
#
# Description:
#   This script initializes the Nextcloud Contacts app in a Docker container.
#   It creates necessary symlinks and enables the app through Nextcloud console.
#
# Operations:
#   1. Creates a symlink from the source directory to Nextcloud apps directory
#   2. Enables the Contacts app using Nextcloud console
#
# Environment:
#   - Requires root or appropriate permissions to create symlinks
#   - Needs access to Nextcloud console.php
#
# Exit Codes:
#   0 - Success
#   1 - General error
#   2 - Permission error
#   3 - App activation error
# ------------------------------------------------------------------------------

# Exit on error, undefined vars, or pipe failures
set -euo pipefail

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

# Path configuration
readonly APP_SOURCE="/ponder/apps/contacts"     # Source directory containing the app
readonly APP_TARGET="/var/www/html/apps/contacts" # Target directory in Nextcloud
readonly CONSOLE_PATH="/var/www/html/console.php" # Path to Nextcloud console

# ------------------------------------------------------------------------------
# Function: log_message
# Purpose: Prints formatted log messages
#
# Arguments:
#   $1 - Message type (INFO, ERROR, WARNING)
#   $2 - Message content
# ------------------------------------------------------------------------------
log_message() {
    local type="$1"
    local message="$2"
    printf "[%s] [%s]: %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "${type}" "${message}"
}

# ------------------------------------------------------------------------------
# Function: check_prerequisites
# Purpose: Validates required files and permissions
#
# Returns:
#   0 - All prerequisites met
#   1 - Prerequisites not met
# ------------------------------------------------------------------------------
check_prerequisites() {
    # Check if source directory exists
    if [[ ! -d "${APP_SOURCE}" ]]; then
        log_message "ERROR" "Source directory ${APP_SOURCE} does not exist"
        return 1
    fi

    # Check if Nextcloud console exists
    if [[ ! -f "${CONSOLE_PATH}" ]]; then
        log_message "ERROR" "Nextcloud console not found at ${CONSOLE_PATH}"
        return 1
    fi

    # Check write permissions for target parent directory
    if [[ ! -w "$(dirname "${APP_TARGET}")" ]]; then
        log_message "ERROR" "Insufficient permissions to create symlink at ${APP_TARGET}"
        return 2
    fi

    return 0
}

# ------------------------------------------------------------------------------
# Function: setup_symlink
# Purpose: Creates symlink from source to target directory
#
# Returns:
#   0 - Symlink created successfully
#   1 - Error creating symlink
# ------------------------------------------------------------------------------
setup_symlink() {
    log_message "INFO" "Setting up Contacts app symlink..."

    # Remove existing directory or symlink if it exists
    if [[ -e "${APP_TARGET}" ]] || [[ -L "${APP_TARGET}" ]]; then
        log_message "INFO" "Removing existing target..."
        rm -rf "${APP_TARGET}"
    fi

    # Create new symlink
    if ! ln -sf "${APP_SOURCE}" "${APP_TARGET}"; then
        log_message "ERROR" "Failed to create symlink"
        return 1
    fi

    log_message "INFO" "Symlink created successfully"
    return 0
}

# ------------------------------------------------------------------------------
# Function: enable_app
# Purpose: Enables the Contacts app in Nextcloud
#
# Returns:
#   0 - App enabled successfully
#   1 - Error enabling app
# ------------------------------------------------------------------------------
enable_app() {
    log_message "INFO" "Enabling Contacts app..."

    if ! php "${CONSOLE_PATH}" app:enable contacts; then
        log_message "ERROR" "Failed to enable Contacts app"
        return 1
    fi

    log_message "INFO" "Contacts app enabled successfully"
    return 0
}

# ------------------------------------------------------------------------------
# Main Script Execution
# ------------------------------------------------------------------------------
main() {
    log_message "INFO" "Starting Contacts app initialization..."

    # Check prerequisites
    if ! check_prerequisites; then
        log_message "ERROR" "Prerequisites check failed"
        exit 1
    fi

    # Setup symlink
    if ! setup_symlink; then
        log_message "ERROR" "Symlink setup failed"
        exit 2
    fi

    # Enable the app
    if ! enable_app; then
        log_message "ERROR" "App activation failed"
        exit 3
    fi

    log_message "INFO" "Contacts app initialization completed successfully"
    exit 0
}

# Execute main function
main
