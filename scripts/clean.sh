#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Script to Clean and Re-Initialize Docker Environment for Testing
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi-baghbani@azadehafzar.io>
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Note: This script performs actions that can significantly alter your Docker 
# environment by removing all containers, networks, and unused data. Ensure that you
# have backups or that it's safe to perform these operations in your environment 
# before running the script.
# -----------------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status,
# a variable is used but not defined, or a command in a pipeline fails
set -euo pipefail

# -----------------------------------------------------------------------------------
# Function: resolve_script_dir
# Purpose: Resolves the absolute path of the script's directory, handling symlinks.
# -----------------------------------------------------------------------------------
resolve_script_dir() {
    local source="${BASH_SOURCE[0]}"
    local dir
    while [ -L "$source" ]; do
        dir="$(cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd)"
        source="$(readlink "$source")"
        [[ "$source" != /* ]] && source="$dir/$source"  # Resolve relative symlink
    done
    dir="$(cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd)"
    printf "%s" "$dir"
}

# -----------------------------------------------------------------------------------
# Function: modify_cypress_config
# Purpose: Modifies the Cypress configuration file to set 'modifyObstructiveCode' to true.
# -----------------------------------------------------------------------------------
modify_cypress_config() {
    local config_file="$ENV_ROOT/cypress/ocm-test-suite/cypress.config.js"
    if [[ -f "$config_file" ]]; then
        sed -i 's/.*modifyObstructiveCode: false,.*/  modifyObstructiveCode: true,/' "$config_file"
    else
        printf "Warning: Configuration file not found: %s\n" "$config_file" >&2
        exit 1
    fi
}

# -----------------------------------------------------------------------------------
# Function: stop_and_remove_docker_containers
# Purpose: Stops and removes all Docker containers.
# -----------------------------------------------------------------------------------
stop_and_remove_docker_containers() {
    docker ps -q | xargs -r docker stop && docker ps -q -a | xargs -r docker rm 
}

# -----------------------------------------------------------------------------------
# Function: docker_cleanup
# Purpose: Cleans up unused Docker volumes and system resources.
# -----------------------------------------------------------------------------------
docker_cleanup() {
    # Prune unused Docker volumes without confirmation
    docker volume prune -f >/dev/null 2>&1 || true
    # Prune unused Docker system data without confirmation
    docker system prune -f >/dev/null 2>&1 || true
}

# -----------------------------------------------------------------------------------
# Function: recreate_docker_network
# Purpose: Removes and recreates a specified Docker network.
# Arguments:
#   $1 - Name of the Docker network to recreate
# -----------------------------------------------------------------------------------
recreate_docker_network() {
    local network_name="$1"
    if [[ -z "$network_name" ]]; then
        printf "Error: Network name is required.\n" >&2
        exit 1
    fi

    # Remove the Docker network if it exists
    if docker network inspect "$network_name" >/dev/null 2>&1; then
        docker network rm "$network_name" >/dev/null 2>&1 || {
            printf "Warning: Failed to remove Docker network: %s\n" "$network_name" >&2
        }
    fi

    # Create the Docker network
    docker network create "$network_name" >/dev/null 2>&1 || {
        printf "Error: Failed to create Docker network: %s\n" "$network_name" >&2
        exit 1
    }
}

# -----------------------------------------------------------------------------------
# Function: main
# Purpose: Main function encapsulating the script logic.
# -----------------------------------------------------------------------------------
main() {
    # Resolve the script's directory and move to the parent directory
    local script_dir
    script_dir="$(resolve_script_dir)"
    cd "$script_dir/.." || {
        printf "Error: Failed to change directory to script's parent.\n" >&2
        exit 1
    }

    # Export the environment root directory
    local env_root
    env_root="$(pwd)"
    export ENV_ROOT="$env_root"

    # Modify the Cypress configuration
    modify_cypress_config

    # Determine whether to clear the terminal (default: yes)
    local clear_terminal="${1:-yes}"

    # Stop and remove all Docker containers
    stop_and_remove_docker_containers

    # Clean up unused Docker volumes and system resources
    docker_cleanup

    # Recreate the Docker network 'testnet'
    recreate_docker_network "testnet"

    # Clear the terminal if requested
    if [[ "$clear_terminal" == "yes" ]]; then
        clear
    fi
}

# -----------------------------------------------------------------------------------
# Execute the main function with all script arguments
# -----------------------------------------------------------------------------------
main "$@"
