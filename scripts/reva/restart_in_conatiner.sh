#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Script to Restart the 'reva' Process in All Docker Containers with 'reva' in Their Names
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# -----------------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status,
# an undefined variable is used, or a command in a pipeline fails
set -euo pipefail

# -----------------------------------------------------------------------------------
# Function: print_error
# Purpose: Prints an error message to stderr.
# Arguments:
#   $1 - The error message to display.
# -----------------------------------------------------------------------------------
print_error() {
    local message="$1"
    printf "Error: %s\n" "$message" >&2
}

# -----------------------------------------------------------------------------------
# Function: restart_reva_in_container
# Purpose: Restarts the 'reva' process inside a Docker container by name.
# Arguments:
#   $1 - The name of the container.
# -----------------------------------------------------------------------------------
restart_reva_in_container() {
    local container_name="$1"
    local success=true

    # Check if container name is provided
    if [[ -z "$container_name" ]]; then
        printf "Warning: Container name is empty. Skipping.\n" >&2
        return 1
    fi

    # Check if the container is running
    if ! docker ps --format '{{.Names}}' | grep -qw "^${container_name}$"; then
        printf "Container '%s' is not running. Starting it...\n" "$container_name"
        if ! docker start "$container_name" >/dev/null 2>&1; then
            print_error "Failed to start container: $container_name"
            success=false
        else
            printf "Container '%s' started successfully.\n" "$container_name"
        fi
    fi

    printf "Restarting 'reva' process in container: %s\n" "$container_name"

    # Kill 'reva' process inside the container
    if ! docker exec "$container_name" bash -c "/terminate.sh"; then
        print_error "Failed to kill 'reva' process in container: $container_name"
        success=false
    else
        printf "Successfully killed 'reva' process in container: %s\n" "$container_name"
    fi

    # Start 'reva' process inside the container
    if ! docker exec "$container_name" bash -c "/init.sh"; then
        print_error "Failed to start 'reva' process in container: $container_name"
        success=false
    else
        printf "Successfully started 'reva' process in container: %s\n" "$container_name"
    fi

    if [ "$success" = true ]; then
        printf "'reva' process successfully restarted in container: %s\n" "$container_name"
        return 0
    else
        print_error "Errors occurred while processing container: $container_name"
        return 1
    fi
}

# -----------------------------------------------------------------------------------
# Function: main
# Purpose: Main function to restart 'reva' process in all Docker containers with 'reva' in their names.
# -----------------------------------------------------------------------------------
main() {
    # Fetch all container names matching "reva" (both running and stopped)
    local reva_containers
    if ! reva_containers=$(docker ps -a --filter "name=reva" --format "{{.Names}}"); then
        print_error "Failed to fetch container names matching 'reva'."
        exit 1
    fi

    # Check if any containers were found
    if [[ -z "$reva_containers" ]]; then
        printf "No containers with 'reva' in their names were found.\n"
        exit 0
    fi

    printf "Found the following 'reva' containers:\n%s\n" "$reva_containers"

    # Restart 'reva' process in each container
    local overall_success=true
    while IFS= read -r container; do
        if ! restart_reva_in_container "$container"; then
            overall_success=false
        fi
    done <<< "$reva_containers"

    if [ "$overall_success" = true ]; then
        printf "All 'reva' containers have been processed successfully.\n"
        exit 0
    else
        print_error "Some containers encountered errors during processing."
        exit 1
    fi
}

# -----------------------------------------------------------------------------------
# Execute the main function
# -----------------------------------------------------------------------------------
main "$@"
