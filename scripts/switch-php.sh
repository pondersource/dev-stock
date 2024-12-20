#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Script to Configure PHP Version Alternatives on the System
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# -----------------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status,
# a variable is used but not defined, or a command in a pipeline fails
set -euo pipefail

# -----------------------------------------------------------------------------------
# Function: print_error
# Purpose: Print an error message to stderr.
# Arguments:
#   $1 - The error message to display.
# -----------------------------------------------------------------------------------
print_error() {
    local message="$1"
    printf "Error: %s\n" "$message" >&2
}

# -----------------------------------------------------------------------------------
# Function: usage
# Purpose: Display usage instructions for the script.
# -----------------------------------------------------------------------------------
usage() {
    printf "Usage: %s <php_version>\n" "$(basename "$0")" >&2
    printf "Example: %s 8.1\n" "$(basename "$0")" >&2
}

# -----------------------------------------------------------------------------------
# Function: command_exists
# Purpose: Check if a command exists on the system.
# Arguments:
#   $1 - The command to check.
# Returns:
#   0 if the command exists, 1 otherwise.
# -----------------------------------------------------------------------------------
command_exists() {
    local command="$1"
    command -v "$command" >/dev/null 2>&1
}

# -----------------------------------------------------------------------------------
# Function: check_php_binaries_exist
# Purpose: Check if the specified PHP version binaries exist.
# Arguments:
#   $1 - The PHP version to check.
# Returns:
#   0 if all binaries exist, exits the script otherwise.
# -----------------------------------------------------------------------------------
check_php_binaries_exist() {
    local version="$1"
    local php_bin="/usr/bin/php$version"
    local phar_bin="/usr/bin/phar$version"
    local phar_phar_bin="/usr/bin/phar.phar$version"
    local missing_binaries=()

    # Check for php binary
    if [[ ! -x "$php_bin" ]]; then
        missing_binaries+=("$php_bin")
    fi

    # Check for phar binary
    if [[ ! -x "$phar_bin" ]]; then
        missing_binaries+=("$phar_bin")
    fi

    # Check for phar.phar binary
    if [[ ! -x "$phar_phar_bin" ]]; then
        missing_binaries+=("$phar_phar_bin")
    fi

    if [[ ${#missing_binaries[@]} -gt 0 ]]; then
        print_error "The following PHP binaries for version $version are missing or not executable:"
        for bin in "${missing_binaries[@]}"; do
            printf "  %s\n" "$bin" >&2
        done
        printf "Please ensure PHP version %s is installed correctly.\n" "$version" >&2
        exit 1
    fi
}

# -----------------------------------------------------------------------------------
# Function: update_php_alternatives
# Purpose: Update the PHP alternatives to point to the specified version.
# Arguments:
#   $1 - The PHP version to set.
# Returns:
#   0 if successful, exits the script otherwise.
# -----------------------------------------------------------------------------------
update_php_alternatives() {
    local version="$1"
    local php_bin="/usr/bin/php$version"
    local phar_bin="/usr/bin/phar$version"
    local phar_phar_bin="/usr/bin/phar.phar$version"

    printf "Configuring PHP alternatives to version %s...\n" "$version"

    # Update 'php' alternative
    if ! sudo update-alternatives --set php "$php_bin"; then
        print_error "Failed to set 'php' alternative to $php_bin."
        exit 1
    fi

    # Update 'phar' alternative
    if ! sudo update-alternatives --set phar "$phar_bin"; then
        print_error "Failed to set 'phar' alternative to $phar_bin."
        exit 1
    fi

    # Update 'phar.phar' alternative
    if ! sudo update-alternatives --set phar.phar "$phar_phar_bin"; then
        print_error "Failed to set 'phar.phar' alternative to $phar_phar_bin."
        exit 1
    fi

    printf "PHP version successfully set to %s.\n" "$version"
}

# -----------------------------------------------------------------------------------
# Function: check_alternative_exists
# Purpose: Check if an alternative group exists.
# Arguments:
#   $1 - The alternative name to check (e.g., 'php').
# Returns:
#   0 if the alternative exists, 1 otherwise.
# -----------------------------------------------------------------------------------
check_alternative_exists() {
    local alt_name="$1"
    if update-alternatives --query "$alt_name" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# -----------------------------------------------------------------------------------
# Function: main
# Purpose: Main function to configure PHP alternatives.
# Arguments:
#   $@ - The command-line arguments passed to the script.
# -----------------------------------------------------------------------------------
main() {
    # Ensure a version number is provided as the first argument
    if [[ $# -ne 1 ]]; then
        print_error "Missing required PHP version number."
        usage
        exit 1
    fi

    local version="$1"

    # Check if 'update-alternatives' command is available
    if ! command_exists "update-alternatives"; then
        print_error "'update-alternatives' command not found. Please install it and try again."
        exit 1
    fi

    # Check if the required PHP binaries exist
    check_php_binaries_exist "$version"

    # Check if the alternatives exist
    local alternatives_missing=()
    for alt in php phar phar.phar; do
        if ! check_alternative_exists "$alt"; then
            alternatives_missing+=("$alt")
        fi
    done

    if [[ ${#alternatives_missing[@]} -gt 0 ]]; then
        print_error "The following alternatives do not exist:"
        for alt in "${alternatives_missing[@]}"; do
            printf "  %s\n" "$alt" >&2
        done
        printf "Please set up the alternatives for PHP versions before switching.\n" >&2
        printf "You may need to run 'sudo update-alternatives --install' for each alternative.\n" >&2
        exit 1
    fi

    # Update PHP alternatives
    update_php_alternatives "$version"
}

# -----------------------------------------------------------------------------------
# Entry Point: Execute the main function with all script arguments
# -----------------------------------------------------------------------------------
main "$@"
