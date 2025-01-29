#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Script to Execute the Reva Command-Line Tool Inside a Docker Container
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# -----------------------------------------------------------------------------------

# Description:
#   This script executes the Reva command-line tool inside a running Docker container.
#   It validates the container's state, handles errors gracefully, and ensures modularity.

# Usage:
#   ./cli.sh [container_name] [reva_command]

# Arguments:
#   container_name : (Optional) Name of the Docker container. Defaults to "revad1.docker".
#   reva_command   : (Optional) Reva command to execute. Defaults to "/reva/cmd/reva/reva -insecure -host localhost:19000".

# Requirements:
#   - Docker must be installed and accessible to the current user.
#   - A running Docker container with the specified name.
#   - The Reva binary should exist inside the container at the specified path.
#   - The script must be executed by a user with permissions to run Docker commands.

# Examples:
#   ./cli.sh
#     Executes the default Reva command inside the "revad1.docker" container.
#
#   ./cli.sh my_container "/usr/local/bin/reva -help"
#     Executes the Reva help command inside the "my_container" container.

# -----------------------------------------------------------------------------------

# Exit immediately on any error, treat unset variables as an error, and catch errors in pipelines.
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
# Function: validate_docker_installed
# Purpose: Validate that Docker is installed and available in the system PATH.
# -----------------------------------------------------------------------------------
validate_docker_installed() {
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker is not installed or not available in the system PATH."
        exit 1
    fi
}

# -----------------------------------------------------------------------------------
# Function: validate_container_running
# Purpose: Validate if the Docker container is running.
# Arguments:
#   $1 - The name of the container.
# -----------------------------------------------------------------------------------
validate_container_running() {
    local container_name="$1"
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        print_error "Docker container '${container_name}' is not running. Please start the container and try again."
        exit 1
    fi
}

# -----------------------------------------------------------------------------------
# Function: check_reva_exists_in_container
# Purpose: Check if the Reva binary exists inside the container.
# Arguments:
#   $1 - The name of the container.
#   $2 - The path to the Reva binary or command inside the container.
# -----------------------------------------------------------------------------------
check_reva_exists_in_container() {
    local container_name="$1"
    local reva_command="$2"

    # Extract the command path (assumes the command is the first word)
    local reva_path
    reva_path=$(echo "$reva_command" | awk '{print $1}')

    # Check if the file exists inside the container
    if ! docker exec "$container_name" test -x "$reva_path"; then
        print_error "Reva binary not found or not executable at '$reva_path' inside container '$container_name'."
        exit 1
    fi
}

# -----------------------------------------------------------------------------------
# Function: run_reva_command
# Purpose: Execute the Reva CLI command inside the Docker container.
# Arguments:
#   $1 - The name of the container.
#   $2 - The Reva command to execute.
# -----------------------------------------------------------------------------------
run_reva_command() {
    local container_name="$1"
    local reva_command="$2"

    # Execute the command inside the container.
    if ! docker exec -it "$container_name" /bin/bash -c "$reva_command"; then
        print_error "Failed to execute the Reva command inside container '$container_name'."
        exit 1
    fi
}

# -----------------------------------------------------------------------------------
# Function: main
# Purpose: Main function to encapsulate script logic.
# -----------------------------------------------------------------------------------
main() {
    # Default values
    local container_name="revad1.docker"
    # TODO: @MahdiBaghbani probably outdated, checck it soon.
    local reva_command="/reva/cmd/reva/reva -insecure -host localhost:19000"

    # Override defaults with arguments if provided
    if [ $# -ge 1 ]; then
        container_name="$1"
    fi

    if [ $# -ge 2 ]; then
        reva_command="$2"
    fi

    # Validate prerequisites.
    validate_docker_installed
    validate_container_running "$container_name"

    # Check if Reva exists inside the container
    check_reva_exists_in_container "$container_name" "$reva_command"

    # Execute the Reva command.
    run_reva_command "$container_name" "$reva_command"

    # Print success message.
    printf "Successfully executed the Reva command in container '%s'.\n" "$container_name"
}


# -----------------------------------------------------------------------------------
# Execute the main function
# -----------------------------------------------------------------------------------
main "$@"
