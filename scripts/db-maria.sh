#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Script to Execute MariaDB Commands Inside a Docker Container
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# -----------------------------------------------------------------------------------

# Description:
#   This script executes a specified MariaDB command inside a Docker container.
#   It is intended for platforms such as ownCloud or Nextcloud, using Dockerized MariaDB instances.

# Usage:
#   db-maria.sh <platform> <number> [<db_command>]

# Arguments:
#   platform   : Platform name (e.g., 'owncloud' or 'nextcloud'). Must be alphanumeric.
#   number     : A unique numeric identifier for the MariaDB container instance.
#   db_command : (Optional) MariaDB database name or SQL command to execute.
#                If not provided, the script will open an interactive MariaDB shell.

# Requirements:
#   - A running Docker container with a name matching "maria<platform><number>.docker".
#   - Docker must be installed and configured for the current user.
#   - Environment variable `DB_PASSWORD` should contain the root password for MariaDB.
#     Alternatively, the script will prompt for the password securely.

# Examples:
#   ./db-maria.sh owncloud 1 my_database
#     Connects to database 'my_database' inside the container 'mariaowncloud1.docker'.
#
#   ./db-maria.sh owncloud 1 -e "SHOW DATABASES;"
#     Executes the SQL command 'SHOW DATABASES;' inside the container 'mariaowncloud1.docker'.

# -----------------------------------------------------------------------------------

# Exit immediately on any error, treat unset variables as an error, and catch errors in pipelines.
set -euo pipefail

# -----------------------------------------------------------------------------------
# Function: print_error
# Purpose: Print an error message to stderr and exit with a failure code.
# Arguments:
#   $1 - The error message to display.
# -----------------------------------------------------------------------------------
print_error() {
    local message="$1"
    printf "Error: %s\n" "$message" >&2
    exit 1
}

# -----------------------------------------------------------------------------------
# Function: validate_alphanumeric
# Purpose: Validate that an argument is alphanumeric.
# Arguments:
#   $1 - The argument to validate.
# -----------------------------------------------------------------------------------
validate_alphanumeric() {
    local arg="$1"
    if [[ ! "$arg" =~ ^[a-zA-Z0-9]+$ ]]; then
        print_error "Invalid value '$arg'. Only alphanumeric characters are allowed."
    fi
}

# -----------------------------------------------------------------------------------
# Function: validate_numeric
# Purpose: Validate that an argument is numeric.
# Arguments:
#   $1 - The argument to validate.
# -----------------------------------------------------------------------------------
validate_numeric() {
    local arg="$1"
    if [[ ! "$arg" =~ ^[0-9]+$ ]]; then
        print_error "Invalid value '$arg'. It must be a numeric value."
    fi
}

# -----------------------------------------------------------------------------------
# Function: prompt_for_password
# Purpose: Prompt the user for the MariaDB root password securely.
# Sets the global variable 'DB_PASSWORD'.
# -----------------------------------------------------------------------------------
prompt_for_password() {
    read -s -p "Enter MariaDB root password: " DB_PASSWORD
    echo
    if [[ -z "$DB_PASSWORD" ]]; then
        print_error "Password cannot be empty."
    fi
}

# -----------------------------------------------------------------------------------
# Function: check_container_running
# Purpose: Check if the Docker container is running.
# Arguments:
#   $1 - The name of the container.
# -----------------------------------------------------------------------------------
check_container_running() {
    local container_name="$1"
    if ! docker ps --format '{{.Names}}' | grep -qw "^${container_name}$"; then
        print_error "Docker container '${container_name}' is not running."
    fi
}

# -----------------------------------------------------------------------------------
# Function: execute_mariadb_command
# Purpose: Execute the MariaDB command inside the Docker container.
# Arguments:
#   $1 - The name of the container.
#   $2 - The database name or SQL command to execute.
# -----------------------------------------------------------------------------------
execute_mariadb_command() {
    local container_name="$1"
    shift
    local mariadb_args=("$@")

    # Avoid passing password via command-line arguments
    # Use MYSQL_PWD environment variable inside the container
    if ! docker exec -i -e MYSQL_PWD="${DB_PASSWORD}" "${container_name}" mariadb -u root "${mariadb_args[@]}"; then
        print_error "Failed to execute MariaDB command inside container '${container_name}'."
    fi
}

# -----------------------------------------------------------------------------------
# Function: main
# Purpose: Main function to Execute MariaDB Commands Inside a Docker Container.
# -----------------------------------------------------------------------------------
main() {
    # Check if at least two arguments are provided.
    if [[ $# -lt 2 ]]; then
        print_error "Usage: $0 <platform> <number> [<db_command>]"
    fi

    # Assign and sanitize script arguments.
    platform="$1"
    number="$2"
    shift 2
    db_command=("$@") # Remaining arguments

    validate_alphanumeric "$platform"
    validate_numeric "$number"

    # Construct Docker container name.
    container_name="maria${platform}${number}.docker"

    # Check if the Docker container is running.
    check_container_running "$container_name"

    # @MahdiBaghbani: Yeah I know not the best way to do it,
    # but remember this is development environment so ... who cares xD
    export DB_PASSWORD="peilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek"

    # Ensure the MariaDB root password is provided via the DB_PASSWORD environment variable or prompt for it.
    if [[ -z "${DB_PASSWORD:-}" ]]; then
        prompt_for_password
    fi

    # If no command is provided, open an interactive MariaDB shell.
    if [[ ${#db_command[@]} -eq 0 ]]; then
        echo "No command provided. Opening interactive MariaDB shell inside container '${container_name}'."
        docker exec -it -e MYSQL_PWD="${DB_PASSWORD}" "${container_name}" mariadb -u root
        exit 0
    fi

    # Execute the MariaDB command inside the container.
    execute_mariadb_command "$container_name" "${db_command[@]}"

    # Success message.
    printf "Command '%s' executed successfully in container '%s'.\n" "${db_command[*]}" "${container_name}"
}

# -----------------------------------------------------------------------------------
# Execute the main function
# -----------------------------------------------------------------------------------
main "$@"
