#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Seafile Seahub Settings Configuration Script
# -----------------------------------------------------------------------------------
# Description:
#   This script updates the Seafile Seahub settings to:
#     1. Enable and configure Open Cloud Mesh (OCM) integration with a unique provider UUID.
#     2. Update Memcached settings based on environment variables or defaults.
#
# Requirements:
#   - Seahub settings file must exist at the specified SEAHUB_SETTINGS path.
#   - The user running this script must have write permissions to the Seahub settings file.
#
# Environment Variables:
#   SEAFILE_MEMCACHE_HOST (optional): Hostname for Memcached (default: "memcached")
#   SEAFILE_MEMCACHE_PORT (optional): Port for Memcached (default: "11211")
#
# Arguments:
#   1 (optional): Remote server name for OCM (default: "seafile")
#
# Notes:
#   - A unique UUID is generated from /proc/sys/kernel/random/uuid for OCM.
#   - Modifications are appended to the Seahub settings file. Existing settings are not removed.
#
# Example:
#   ./seafile.sh "myserver"
#
# Exit Codes:
#   0 - Success
#   1 - Failure due to missing files, permissions, or command errors.
#
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Exit on Errors and Ensure Robust Pipeline Handling
# -----------------------------------------------------------------------------------
set -e
set -o pipefail

# -----------------------------------------------------------------------------------
# Constants and Environment Variables
# -----------------------------------------------------------------------------------
SEAHUB_SETTINGS="/opt/seafile/conf/seahub_settings.py"  # Path to Seahub settings file

# Default values for Memcached host and port
SEAFILE_MEMCACHE_HOST="${SEAFILE_MEMCACHE_HOST:-memcached}"
SEAFILE_MEMCACHE_PORT="${SEAFILE_MEMCACHE_PORT:-11211}"

# Default remote server name for OCM (can be overridden by script argument)
DEFAULT_REMOTE_SERVER="seafile"

# -----------------------------------------------------------------------------------
# Function: generate_uuid
# Purpose: Generate a UUID using the kernel's random generator.
# Returns: UUID as a string.
# On Error: Prints an error and exits with code 1 if the UUID file is not found.
# -----------------------------------------------------------------------------------
generate_uuid() {
    local uuid_file="/proc/sys/kernel/random/uuid"
    if [[ -f "${uuid_file}" ]]; then
        cat "${uuid_file}"
    else
        echo "Error: UUID generator file not found at ${uuid_file}." >&2
        exit 1
    fi
}

# -----------------------------------------------------------------------------------
# Function: append_ocm_configuration
# Purpose: Append OCM configuration to the Seahub settings file.
# Arguments:
#   1. settings_file: Path to the Seahub settings file
#   2. uuid: Unique provider ID for OCM
#   3. remote_server: Remote server name for OCM
# On Error: Prints an error and exits if the file is not writable.
# -----------------------------------------------------------------------------------
append_ocm_configuration() {
    local settings_file="$1"
    local uuid="$2"
    local remote_server="$3"

    # Verify write permission for the settings file
    if [[ ! -w "${settings_file}" ]]; then
        echo "Error: Cannot write to ${settings_file}. Check file permissions." >&2
        exit 1
    fi

    printf "Appending OCM configuration to %s...\n" "${settings_file}"

    cat >> "${settings_file}" <<EOL

# -----------------------------------------------------------------------------------
# Open Cloud Mesh (OCM) Configuration
# -----------------------------------------------------------------------------------
ENABLE_OCM = True
OCM_PROVIDER_ID = "${uuid}"  # Unique ID of this server
OCM_REMOTE_SERVERS = [
    {
        "server_name": "${remote_server}",
        "server_url": "http://${remote_server}.docker/",  # Must end with '/'
    },
]
EOL

    printf "OCM configuration added successfully.\n"
}

# -----------------------------------------------------------------------------------
# Function: update_memcached_configuration
# Purpose: Update Memcached configuration in Seahub settings to match user input or defaults.
# Arguments:
#   1. settings_file: Path to the Seahub settings file
#   2. memcache_host: Memcached hostname
#   3. memcache_port: Memcached port
# On Error: Prints an error and exits if sed fails to update the line.
# -----------------------------------------------------------------------------------
update_memcached_configuration() {
    local settings_file="$1"
    local memcache_host="$2"
    local memcache_port="$3"

    printf "Updating memcached configuration in %s...\n" "${settings_file}"

    # Use a safer sed command to update the LOCATION line for memcached
    # This assumes there is a line containing 'LOCATION': 'memcached:11211' in the file.
    if ! sed -i "s|\('LOCATION':\s*'\)memcached:11211'|\1${memcache_host}:${memcache_port}'|" "${settings_file}"; then
        echo "Error: Failed to update memcached configuration in ${settings_file}." >&2
        exit 1
    fi

    printf "Memcached configuration updated successfully to %s:%s\n" "${memcache_host}" "${memcache_port}"
}

# -----------------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------------
main() {
    # Verify Seahub settings file exists
    if [[ ! -f "${SEAHUB_SETTINGS}" ]]; then
        echo "Error: Seahub settings file not found at ${SEAHUB_SETTINGS}" >&2
        exit 1
    fi

    # Generate a UUID for the OCM provider
    printf "Generating UUID for OCM provider...\n"
    uuid=$(generate_uuid)
    printf "Generated UUID: %s\n" "${uuid}"

    # Parse input argument for remote server name
    # If no argument provided, use DEFAULT_REMOTE_SERVER
    remote_server=${1:-"${DEFAULT_REMOTE_SERVER}"}
    printf "Using remote server: %s\n" "${remote_server}"

    # Append OCM configuration to Seahub settings
    append_ocm_configuration "${SEAHUB_SETTINGS}" "${uuid}" "${remote_server}"

    # Update memcached configuration
    update_memcached_configuration "${SEAHUB_SETTINGS}" "${SEAFILE_MEMCACHE_HOST}" "${SEAFILE_MEMCACHE_PORT}"

    printf "Seafile Seahub configuration completed successfully.\n"
}

# Execute the main function
main "$@"
