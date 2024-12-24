#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Reva Environment Initialization and Configuration Script
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# -----------------------------------------------------------------------------------

# Description:
#   This script initializes and configures a Reva environment in a Docker container. It:
#     1. Ensures that the /reva directory exists.
#     2. Populates /reva with Reva binaries if it's empty (copied from /reva-git).
#     3. Copies and customizes Reva configuration files from /configs/revad to /etc/revad.
#     4. Sets up TLS certificates from /certificates and /certificate-authority, updating
#        the operating system's CA store as needed.
#     5. Starts the Reva daemon (revad) in the background with the updated configuration.
#
# Requirements:
#   - Reva source code or binaries must exist in /reva-git if /reva is empty.
#   - Reva configuration files must be present in /configs/revad.
#   - Optionally, TLS certificates can be placed in /certificates and/or /certificate-authority.
#   - The HOST environment variable may be set to customize placeholders in the configuration.
#
# Notes:
#   - If HOST is not set, it defaults to "localhost".
#   - The script attempts to update the OS certificate store with any .crt files in /tls.
#   - The script does not exit if copying certificate files fails (it continues silently).
#   - The Reva daemon is launched in the background; logs should be checked for issues.
#
# Example:
#   HOST=revaexample ./init.sh
#
# Exit Codes:
#   0 - Success
#   1 - Failure due to missing directories, files, or commands.
#
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Halt the script on any command failure and treat pipelines robustly.
# -----------------------------------------------------------------------------------
set -euo pipefail

# -----------------------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------------------
REVA_DIR="/reva"                           # Directory where Reva binaries will reside
REVA_GIT_DIR="/reva-git"                   # Directory containing Reva source/binaries for copying
CONFIG_DIR="/configs/revad"                # Directory containing Reva configuration files
REVA_CONFIG_DIR="/etc/revad"               # Directory where config files will be copied
TLS_DIR="/tls"                             # Directory where certificates/keys are stored
CERTS_DIR="/certificates"                  # Directory containing optional certificate files
CA_DIR="/certificate-authority"            # Directory containing optional CA certificate/key files
HOST="${HOST:-localhost}"                  # Hostname for the environment, defaults to "localhost"

# -----------------------------------------------------------------------------------
# Function: create_directory
# Purpose:  Create a directory if it does not exist.
# Arguments:
#   1. dir (string) - The path to the directory to create.
# Returns:
#   0 on success, 1 on failure.
# -----------------------------------------------------------------------------------
create_directory() {
    local dir="$1"

    if [[ -z "$dir" ]]; then
        printf "Error: No directory provided to create_directory.\n" >&2
        return 1
    fi

    mkdir -p "$dir"
}

# -----------------------------------------------------------------------------------
# Function: populate_reva_binaries
# Purpose:  Copy Reva binaries from /reva-git to /reva if /reva is empty.
# Behavior:
#   - If /reva does not exist, print an error and return 1.
#   - If /reva is empty, copy the 'cmd' directory from /reva-git to /reva.
#   - If /reva is not empty, list the contents and do nothing.
# Returns:
#   0 on success, 1 on failure.
# -----------------------------------------------------------------------------------
populate_reva_binaries() {
    if [[ ! -d "$REVA_DIR" ]]; then
        printf "Error: %s does not exist.\n" "$REVA_DIR" >&2
        return 1
    fi

    # Check if /reva is empty
    if [[ -z "$(find "$REVA_DIR" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
        printf "/reva is an empty directory, populating it with Reva binaries...\n"
        # Copy 'cmd' from /reva-git into /reva
        if ! cp -ar "$REVA_GIT_DIR/cmd" "$REVA_DIR"; then
            printf "Error: Failed to copy binaries to /reva.\n" >&2
            return 1
        fi
    else
        # If not empty, list the contents
        ls -lsa "$REVA_DIR"
        printf "/reva contains files, doing nothing.\n"
    fi
}

# -----------------------------------------------------------------------------------
# Function: prepare_configuration
# Purpose:  Copy Reva configuration files to /etc/revad and replace placeholders.
# Behavior:
#   - If /configs/revad is missing, print an error and return 1.
#   - Remove any existing /etc/revad directory.
#   - Copy /configs/revad to /etc/revad.
#   - Replace placeholder hostnames in .toml files with $HOST.docker or derived host.
# Returns:
#   0 on success, 1 on failure.
# -----------------------------------------------------------------------------------
prepare_configuration() {
    if [[ ! -d "$CONFIG_DIR" ]]; then
        printf "Error: Configuration directory %s not found.\n" "$CONFIG_DIR" >&2
        return 1
    fi

    # Remove existing config directory
    rm -rf "$REVA_CONFIG_DIR"

    # Copy config directory
    if ! cp -r "$CONFIG_DIR" "$REVA_CONFIG_DIR"; then
        printf "Error: Failed to copy configuration to %s.\n" "$REVA_CONFIG_DIR" >&2
        return 1
    fi

    # Replace placeholders in .toml files
    sed -i "s/your.revad.org/${HOST}.docker/g" "$REVA_CONFIG_DIR"/*.toml || true
    sed -i "s/localhost/${HOST}.docker/g" "$REVA_CONFIG_DIR"/*.toml || true
    sed -i "s/your.efss.org/${HOST//reva/}.docker/g" "$REVA_CONFIG_DIR"/*.toml || true
    sed -i "s/your.nginx.org/${HOST//reva/}.docker/g" "$REVA_CONFIG_DIR"/*.toml || true
}

# -----------------------------------------------------------------------------------
# Function: prepare_tls_certificates
# Purpose:  Create /tls, copy certificate files from /certificates and /certificate-authority,
#           update the OS certificate store, and create symbolic links for server.crt/key.
# Behavior:
#   - If /certificates or /certificate-authority exist, copy .crt and .key files to /tls.
#   - Update the OS CA store with any .crt files found in /tls.
#   - Link ${HOST}.crt to server.crt and ${HOST}.key to server.key in /tls.
# Returns:
#   0 on success, does not fail if copying certificate files fails (silent ignore).
# -----------------------------------------------------------------------------------
prepare_tls_certificates() {
    create_directory "$TLS_DIR"

    # Copy certificates from /certificates
    if [[ -d "$CERTS_DIR" ]]; then
        cp -f "$CERTS_DIR"/*.crt "$TLS_DIR/" 2>/dev/null || true
        cp -f "$CERTS_DIR"/*.key "$TLS_DIR/" 2>/dev/null || true
    fi

    # Copy certificates from /certificate-authority
    if [[ -d "$CA_DIR" ]]; then
        cp -f "$CA_DIR"/*.crt "$TLS_DIR/" 2>/dev/null || true
        cp -f "$CA_DIR"/*.key "$TLS_DIR/" 2>/dev/null || true
    fi

    # Update OS CA store (ignore errors)
    cp -f "$TLS_DIR"/*.crt /usr/local/share/ca-certificates/ 2>/dev/null || true
    update-ca-certificates || true

    # Create symlinks for Reva's server certificates
    ln -sf "$TLS_DIR/${HOST}.crt" "$TLS_DIR/server.crt"
    ln -sf "$TLS_DIR/${HOST}.key" "$TLS_DIR/server.key"
}

# -----------------------------------------------------------------------------------
# Function: start_reva_daemon
# Purpose:  Launch the Reva daemon (revad) with the dev-dir set to /etc/revad.
# Behavior:
#   - Checks for revad in PATH.
#   - Starts revad in the background.
# Returns:
#   0 on success, 1 if revad is not found.
# -----------------------------------------------------------------------------------
start_reva_daemon() {
    if ! command -v revad &>/dev/null; then
        printf "Error: Reva daemon (revad) not found in PATH.\n" >&2
        return 1
    fi

    printf "Starting Reva daemon...\n"
    # Start revad in the background
    revad --dev-dir "$REVA_CONFIG_DIR" &
}

# -----------------------------------------------------------------------------------
# Main function to coordinate the script flow.
# -----------------------------------------------------------------------------------
main() {
    # Ensure /reva directory exists
    create_directory "$REVA_DIR"

    # Populate /reva if empty
    populate_reva_binaries

    # Prepare Reva configuration files
    prepare_configuration

    # Handle TLS certificates
    prepare_tls_certificates

    # Start the Reva daemon
    start_reva_daemon
}

# -----------------------------------------------------------------------------------
# Execute the main function
# -----------------------------------------------------------------------------------
main
