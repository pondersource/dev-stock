#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Script to Restart All Docker Containers with 'reva' in Their Names
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# -----------------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status,
# an undefined variable is used, or a command in a pipeline fails
set -euo pipefail

# -----------------------------------------------------------------------------------
# Function: print_error
# Purpose: Prints an error message to stderr and exits the script.
# Arguments:
#   $1 - The error message to display.
# -----------------------------------------------------------------------------------
print_error() {
    local message="$1"
    printf "Error: %s\n" "$message" >&2
    exit 1
}

# -----------------------------------------------------------------------------------
# Function: restart_container
# Purpose: Restarts a Docker container by name.
# Arguments:
#   $1 - The name of the container to restart.
# -----------------------------------------------------------------------------------
restart_container() {
    local container_name="$1"

    # Check if container name is provided
    if [[ -z "$container_name" ]]; then
        printf "Warning: Container name is empty. Skipping.\n" >&2
        return 1
    fi

    # Attempt to restart the container
    if docker restart "$container_name" >/dev/null 2>&1; then
        printf "Successfully restarted container: %s\n" "$container_name"
    else
        printf "Failed to restart container: %s\n" "$container_name" >&2
    fi
}

# -----------------------------------------------------------------------------------
# Function: main
# Purpose: Main function to restart all Docker containers with 'reva' in their names.
# -----------------------------------------------------------------------------------
main() {
    # Fetch all container names matching "reva" (both running and stopped)
    local reva_containers
    if ! reva_containers=$(docker ps -a --filter "name=reva" --format "{{.Names}}"); then
        print_error "Failed to fetch container names matching 'reva'."
    fi

    # Check if any containers were found
    if [[ -z "$reva_containers" ]]; then
        printf "No containers with 'reva' in their names were found.\n"
        exit 0
    fi

    printf "Found the following 'reva' containers:\n%s\n" "$reva_containers"

    # Restart each container
    while IFS= read -r container; do
        restart_container "$container"
    done <<< "$reva_containers"

    printf "All 'reva' containers have been processed.\n"
}

# -----------------------------------------------------------------------------------
# Execute the main function
# -----------------------------------------------------------------------------------
main "$@"
