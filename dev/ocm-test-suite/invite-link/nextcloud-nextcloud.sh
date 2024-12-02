#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Script to Test Nextcloud to Nextcloud OCM invite link flow tests.
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi-baghbani@azadehafzar.io>
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Description:
#   This script automates the setup and testing of EFSS (Enterprise File Synchronization and Sharing) platforms
#   such as Nextcloud, using ScienceMesh integration and tools like Reva, Cypress, and Docker containers.
#   It supports both development and CI environments, with optional browser support.

# Usage:
#   ./nextcloud-nextcloud.sh [EFSS_PLATFORM_1_VERSION] [EFSS_PLATFORM_2_VERSION] [SCRIPT_MODE] [BROWSER_PLATFORM]

# Arguments:
#   EFSS_PLATFORM_1_VERSION : Version of the primary EFSS platform (default: "v27.1.11").
#   EFSS_PLATFORM_2_VERSION : Version of the secondary EFSS platform (default: "v27.1.11").
#   SCRIPT_MODE             : Script mode (default: "dev"). Options: dev, ci.
#   BROWSER_PLATFORM        : Browser platform (default: "electron"). Options: chrome, edge, firefox, electron.

# Requirements:
#   - Docker and required images must be installed.
#   - Test scripts and configurations must be located in the expected directories.
#   - Ensure that the necessary scripts (e.g., init scripts) and configurations exist.

# Example:
#   ./nextcloud-nextcloud.sh v28.0.12 v27.1.11 ci electron

# -----------------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status,
# a variable is used but not defined, or a command in a pipeline fails
set -euo pipefail

# -----------------------------------------------------------------------------------
# Constants and Default Values
# -----------------------------------------------------------------------------------

# Default versions
DEFAULT_EFSS_VERSION="v27.1.11"
DEFAULT_SCRIPT_MODE="dev"
DEFAULT_BROWSER_PLATFORM="electron"

# Docker network name
DOCKER_NETWORK="testnet"

# MariaDB root password
MARIADB_ROOT_PASSWORD="eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek"

# Paths to required directories
TEMP_DIR="temp"
TLS_CA_DIR="docker/tls/certificate-authority"
TLS_CERTIFICATES_DIR="docker/tls/certificates"

# 3rd party containerS
CYPRESS_REPO=cypress/included
CYPRESS_TAG=13.13.1@sha256:e9bb8aa3e4cca25867c1bdb09bd0a334957fc26ec25239534e6909697efb297e
FIREFOX_REPO=jlesage/firefox
FIREFOX_TAG=v24.11.1@sha256:ea3ef3febbfadb876955c2eaff5dde4772f70676cd318e0e3706c5ddc0fd9e68
MARIADB_REPO=mariadb
MARIADB_TAG=11.6.2@sha256:0a620383fe05d20b3cc7510ebccc6749f83f1b0f97f3030d10dd2fa199371f07
VNC_REPO=theasp/novnc
VNC_TAG=latest@sha256:26dcdccd36e5a6f6eb93beb76c8a74d5a5120a58184433f948428bb018d54c58


# -----------------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Function: print_error
# Purpose: Print an error message to stderr.
# Arguments:
#   $1 - The error message to display.
# -----------------------------------------------------------------------------------
print_error() {
    local message="${1}"
    printf "Error: %s\n" "${message}" >&2
}

# -----------------------------------------------------------------------------------
# Function: error_exit
# Purpose: Print an error message and exit with code 1.
# Arguments:
#   $1 - The error message to display.
# -----------------------------------------------------------------------------------
error_exit() {
    print_error "${1}"
    exit 1
}

# -----------------------------------------------------------------------------------
# Function: resolve_script_dir
# Purpose: Resolves the absolute path of the script's directory, handling symlinks.
# Returns:
#   The absolute path to the script's directory.
# -----------------------------------------------------------------------------------
resolve_script_dir() {
    local source="${BASH_SOURCE[0]}"
    local dir
    while [ -L "${source}" ]; do
        dir="$(cd -P "$(dirname "${source}")" >/dev/null 2>&1 && pwd)"
        source="$(readlink "${source}")"
        # Resolve relative symlink
        [[ "${source}" != /* ]] && source="${dir}/${source}"
    done
    dir="$(cd -P "$(dirname "${source}")" >/dev/null 2>&1 && pwd)"
    printf "%s" "${dir}"
}

# -----------------------------------------------------------------------------------
# Function: initialize_environment
# Purpose: Initialize the environment and set global variables.
# -----------------------------------------------------------------------------------
initialize_environment() {
    local script_dir
    script_dir="$(resolve_script_dir)"
    cd "${script_dir}/../../.." || error_exit "Failed to change directory to the script root."
    ENV_ROOT="$(pwd)"
    export ENV_ROOT="${ENV_ROOT}"

    # Ensure required commands are available
    for cmd in docker; do
        if ! command_exists "${cmd}"; then
            error_exit "Required command '${cmd}' is not available. Please install it and try again."
        fi
    done
}

# -----------------------------------------------------------------------------------
# Function: wait_for_port
# Purpose: Wait for a Docker container to open a specific port.
# Arguments:
#   $1 - The name of the Docker container.
#   $2 - The port number to check.
# -----------------------------------------------------------------------------------
wait_for_port() {
    local container="${1}"
    local port="${2}"

    run_quietly_if_ci echo "Waiting for port ${port} on container ${container}..."
    until docker exec "${container}" sh -c "ss -tulpn | grep -q 'LISTEN.*:${port}'" >/dev/null 2>&1; do
        run_quietly_if_ci echo "Port ${port} not open yet on ${container}. Retrying..."
        sleep 1
    done
    run_quietly_if_ci echo "Port ${port} is now open on ${container}."
}

# -----------------------------------------------------------------------------------
# Function: run_quietly_if_ci
# Purpose: Run a command, suppressing stdout in CI mode.
# Arguments:
#   $@ - The command and arguments to execute.
# -----------------------------------------------------------------------------------
run_quietly_if_ci() {
    if [ "${SCRIPT_MODE}" = "ci" ]; then
        "$@" >/dev/null 2>&1
    else
        "$@"
    fi
}

# -----------------------------------------------------------------------------------
# Function: run_docker_container
# Purpose: Start a Docker container with the provided arguments.
# Arguments:
#   $@ - Docker run command arguments
# -----------------------------------------------------------------------------------
run_docker_container() {
    run_quietly_if_ci docker run "$@" || error_exit "Failed to start Docker container: $*"
}


# -----------------------------------------------------------------------------------
# Function: remove_directory
# Purpose: Safely remove a directory if it exists.
# Arguments:
#   $1 - Directory path
# -----------------------------------------------------------------------------------
remove_directory() {
    local dir="${1}"
    if [ -d "${dir}" ]; then
        run_quietly_if_ci rm -rf "${dir}" || error_exit "Failed to remove directory: ${dir}"
    fi
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
    command -v "${1}" >/dev/null 2>&1
}

# -----------------------------------------------------------------------------------
# Setup Functions
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Function: create_nextcloud
# Purpose: Create a Nextcloud container with a MariaDB backend.
# Arguments:
#   $1 - Instance number.
#   $2 - Admin username.
#   $3 - Admin password.
#   $4 - Initialization script filename.
#   $5 - EFSS platform version (optional).
# -----------------------------------------------------------------------------------
create_nextcloud() {
    local number="${1}"
    local user="${2}"
    local password="${3}"
    local init_script="${4}"
    local version="${6:-$DEFAULT_EFSS_VERSION}"

    run_quietly_if_ci echo "Creating EFSS instance: nextcloud ${number}"

    # Validate that the init script exists
    if [ ! -f "${ENV_ROOT}/${TEMP_DIR}/${init_script}" ]; then
        error_exit "Initialization script not found: ${ENV_ROOT}/${TEMP_DIR}/${init_script}"
    fi

    # Start MariaDB container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="marianextcloud${number}.docker" \
        -e MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD}" \
        "${MARIADB_REPO}":"${MARIADB_TAG}" \
        --transaction-isolation=READ-COMMITTED \
        --binlog-format=ROW \
        --innodb-file-per-table=1 \
        --skip-innodb-read-only-compressed || error_exit "Failed to start MariaDB container for nextcloud ${number}."

    # Wait for MariaDB port to open
    wait_for_port "marianextcloud${number}.docker" 3306

    # Start EFSS container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="nextcloud${number}.docker" \
        --add-host "host.docker.internal:host-gateway" \
        -e HOST="nextcloud${number}" \
        -e DBHOST="marianextcloud${number}.docker" \
        -e USER="${user}" \
        -e PASS="${password}" \
        -v "${ENV_ROOT}/${TLS_CERTIFICATES_DIR}:/certificates" \
        -v "${ENV_ROOT}/${TLS_CA_DIR}:/certificate-authority" \
        -v "${ENV_ROOT}/${TEMP_DIR}/${init_script}":"/init.sh" \
        -v "${ENV_ROOT}/docker/scripts/entrypoint.sh":"/entrypoint.sh" \
        "pondersource/dev-stock-nextcloud-sciencemesh:latest" || error_exit "Failed to start EFSS container for nextcloud ${number}."

    # Wait for EFSS port to open
    run_quietly_if_ci wait_for_port "nextcloud${number}.docker" 443

    # Install and update certificates inside the EFSS container
    run_quietly_if_ci docker exec "nextcloud${number}.docker" sh -c "cp /certificates/*.crt /usr/local/share/ca-certificates/ || true"
    run_quietly_if_ci docker exec "nextcloud${number}.docker" sh -c "update-ca-certificates" || error_exit "Failed to update CA certificates in ${platform} ${number}."
    # Run the initialization script inside EFSS
    run_quietly_if_ci docker exec -u www-data "nextcloud${number}.docker" sh -c "/init.sh" || error_exit "Initialization script failed for ${platform} ${number}."
}

# -----------------------------------------------------------------------------------
# Function: create_reva
# Purpose: Create a Reva container for the specified EFSS platform and instance.
# Arguments:
#   $1 - EFSS platform (e.g., nextcloud).
#   $2 - Instance number.
# -----------------------------------------------------------------------------------
create_reva() {
    local platform="${1}"
    local number="${2}"

    run_quietly_if_ci echo "Creating Reva instance: ${platform} ${number}"

    # Ensure Reva scripts are executable
    run_quietly_if_ci chmod +x "${ENV_ROOT}/${TEMP_DIR}/reva/"{run.sh,kill.sh,entrypoint.sh} || error_exit "Failed to make Reva scripts executable."

    # Start Reva container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="reva${platform}${number}.docker" \
        -e HOST="reva${platform}${number}" \
        -v "${ENV_ROOT}/${TLS_CERTIFICATES_DIR}:/certificates" \
        -v "${ENV_ROOT}/${TLS_CA_DIR}:/certificate-authority" \
        -v "${ENV_ROOT}/${TEMP_DIR}/reva/configs:/configs/revad" \
        -v "${ENV_ROOT}/${TEMP_DIR}/reva/run.sh":"/usr/bin/run.sh" \
        -v "${ENV_ROOT}/${TEMP_DIR}/reva/kill.sh":"/usr/bin/kill.sh" \
        -v "${ENV_ROOT}/${TEMP_DIR}/reva/entrypoint.sh":"/usr/bin/entrypoint.sh" \
        pondersource/dev-stock-revad || error_exit "Failed to start Reva container for ${platform} ${number}."

    # Wait for Reva port to open (assuming Reva uses port 19000)
    wait_for_port "reva${platform}${number}.docker" 19000
}


# -----------------------------------------------------------------------------------
# Function: configure_sciencemesh
# Purpose: Configure ScienceMesh settings for the EFSS platform.
# Arguments:
#   $1 - EFSS platform (e.g., nextcloud).
#   $2 - Instance number.
# -----------------------------------------------------------------------------------
configure_sciencemesh() {
    local platform="${1}"
    local number="${2}"

    run_quietly_if_ci echo "Configuring ScienceMesh for ${platform} ${number}"

    local mysql_cmd="docker exec maria${platform}${number}.docker mariadb -u root -p${MARIADB_ROOT_PASSWORD} efss"

    # Insert ScienceMesh configuration into the database
    $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'iopUrl', 'https://reva${platform}${number}.docker/');" >/dev/null 2>&1
    $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'revaSharedSecret', 'shared-secret-1');" >/dev/null 2>&1
    $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'meshDirectoryUrl', 'https://meshdir.docker/meshdir');" >/dev/null 2>&1
    $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'inviteManagerApikey', 'invite-manager-endpoint');" >/dev/null 2>&1    
}

# -----------------------------------------------------------------------------------
# Function: parse_arguments
# Purpose: Parse command-line arguments and set global variables.
# Arguments:
#   $@ - Command-line arguments
# -----------------------------------------------------------------------------------
parse_arguments() {
    EFSS_PLATFORM_1_VERSION="${1:-$DEFAULT_EFSS_VERSION}"
    EFSS_PLATFORM_2_VERSION="${2:-$DEFAULT_EFSS_VERSION}"
    SCRIPT_MODE="${3:-$DEFAULT_SCRIPT_MODE}"
    BROWSER_PLATFORM="${4:-$DEFAULT_BROWSER_PLATFORM}"
}

# -----------------------------------------------------------------------------------
# Function: validate_files
# Purpose: Validate that required files and directories exist.
# -----------------------------------------------------------------------------------
validate_files() {
    # Check if TLS certificate files exist
    if [ ! -d "${ENV_ROOT}/${TLS_CERTIFICATES_DIR}" ]; then
        error_exit "TLS certificates directory not found: ${ENV_ROOT}/${TLS_CERTIFICATES_DIR}"
    fi
    if [ ! -d "${ENV_ROOT}/${TLS_CA_DIR}" ]; then
        error_exit "TLS certificate authority directory not found: ${ENV_ROOT}/${TLS_CA_DIR}"
    fi

    # Check if Firefox certificate files exist
    if [ ! -f "${ENV_ROOT}/docker/tls/browsers/firefox/cert9.db" ]; then
        error_exit "Firefox cert9.db file not found: ${ENV_ROOT}/docker/tls/browsers/firefox/cert9.db"
    fi
    if [ ! -f "${ENV_ROOT}/docker/tls/browsers/firefox/cert_override.txt" ]; then
        error_exit "Firefox cert_override.txt file not found: ${ENV_ROOT}/docker/tls/browsers/firefox/cert_override.txt"
    fi

    # Check if Cypress configuration exists
    if [ ! -f "${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js" ]; then
        error_exit "Cypress configuration file not found: ${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"
    fi
}

# -----------------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------------

main() {
    # Initialize environment and parse arguments
    initialize_environment
    parse_arguments "$@"
    validate_files

    # Prepare temporary directories and copy necessary files
    remove_directory "${ENV_ROOT}/${TEMP_DIR}" && mkdir -p "${ENV_ROOT}/${TEMP_DIR}"
    # Copy init files.
    cp -fr  "${ENV_ROOT}/docker/scripts/reva"                               "${ENV_ROOT}/${TEMP_DIR}/"
    cp -fr "${ENV_ROOT}/docker/configs/revad"                               "${ENV_ROOT}/${TEMP_DIR}/reva/configs"
    cp -f  "${ENV_ROOT}/docker/scripts/ocmstub/index.js"                    "${ENV_ROOT}/${TEMP_DIR}/index.js"
    cp -f  "${ENV_ROOT}/docker/scripts/init/nextcloud-sciencemesh.sh"       "${ENV_ROOT}/${TEMP_DIR}/nextcloud.sh"
    # Remove unnecessary configs.
    rm "${ENV_ROOT}/${TEMP_DIR}/reva/configs/sciencemesh-apps-codimd.toml"
    rm "${ENV_ROOT}/${TEMP_DIR}/reva/configs/sciencemesh-apps-collabora.toml"

    # Clean up previous resources and ensure Docker network exists
    if [ -x "${ENV_ROOT}/scripts/clean.sh" ]; then
        "${ENV_ROOT}/scripts/clean.sh" "no"
    else
        print_error "Cleanup script not found or not executable at '${ENV_ROOT}/scripts/clean.sh'. Continuing without cleanup."
    fi

    if ! docker network inspect "${DOCKER_NETWORK}" >/dev/null 2>&1; then
        docker network create "${DOCKER_NETWORK}" >/dev/null 2>&1 || error_exit "Failed to create Docker network '${DOCKER_NETWORK}'."
    fi

    # Create Nextcloud containers
    #                   #id  #username     #password       #init_filename    #nextcloud_version      
    create_nextcloud    1    "einstein"    "relativity"    "nextcloud.sh"    "${EFSS_PLATFORM_1_VERSION}"
    create_nextcloud    2    "michiel"     "dejong"        "nextcloud.sh"    "${EFSS_PLATFORM_2_VERSION}"

    # Create Reva containers
    create_reva "nextcloud" 1
    create_reva "nextcloud" 2

    # Configure ScienceMesh integration
    configure_sciencemesh "nextcloud" 1
    configure_sciencemesh "nextcloud" 2
	
	# Start Mesh Directory
    run_quietly_if_ci echo "Starting Mesh Directory..."
    run_docker_container --detach --network="$DOCKER_NETWORK" \
        --name="meshdir.docker" \
        -e HOST="meshdir" \
        -v "${ENV_ROOT}/${TEMP_DIR}/index.js:/ocmstub/index.js" \
        pondersource/dev-stock-ocmstub

    if [ "${SCRIPT_MODE}" = "dev" ]; then
        echo "Setting up development environment..."

        # Start Firefox container
        run_quietly_if_ci echo "Starting Firefox container..."
        run_docker_container --detach --network="${DOCKER_NETWORK}" \
            --name="firefox" \
            -p 5800:5800 \
            --shm-size=2g \
            -e USER_ID="$(id -u)" \
            -e GROUP_ID="$(id -g)" \
            -e DARK_MODE=1 \
            -v "${ENV_ROOT}/docker/tls/browsers/firefox/cert9.db:/config/profile/cert9.db:rw" \
            -v "${ENV_ROOT}/docker/tls/browsers/firefox/cert_override.txt:/config/profile/cert_override.txt:rw" \
            "${FIREFOX_REPO}":"${FIREFOX_TAG}"

        # Start VNC Server container
        run_quietly_if_ci echo "Starting VNC Server..."
        local x11_socket="${ENV_ROOT}/${TEMP_DIR}/.X11-unix"
        # Ensure previous socket files are removed
        remove_directory "${x11_socket}"
        mkdir -p "${x11_socket}"
        run_docker_container --detach --network="${DOCKER_NETWORK}" \
            --name="vnc-server" \
            -p 5700:8080 \
            -e RUN_XTERM=no \
            -e DISPLAY_WIDTH=1920 \
            -e DISPLAY_HEIGHT=1080 \
            -v "${x11_socket}:/tmp/.X11-unix" \
            "${VNC_REPO}":"${VNC_TAG}"

        # Start Cypress container
        echo "Starting Cypress container..."
        run_docker_container --detach --network="${DOCKER_NETWORK}" \
            --name="cypress.docker" \
            -e DISPLAY="vnc-server:0.0" \
            -v "${ENV_ROOT}/cypress/ocm-test-suite:/ocm" \
            -v "${x11_socket}:/tmp/.X11-unix" \
            -w /ocm \
            --entrypoint cypress \
            "${CYPRESS_REPO}":"${CYPRESS_TAG}" \
            open --project .

        # Display setup instructions
        echo ""
        echo "Development environment setup complete."
        echo "Access the following URLs in your browser:"
        echo "  Cypress inside VNC Server -> http://localhost:5700/vnc.html"
        echo "  Embedded Firefox          -> http://localhost:5800"
        echo "Note:"
        echo "  Scale VNC to get to the Continue button, and run the appropriate test from ./cypress/ocm-test-suite/cypress/e2e/"
        echo ""
        echo "Log in to EFSS platforms using the following credentials:"
        echo "  https://nextcloud1.docker (username: einstein, password: relativity)"
        echo "  https://nextcloud2.docker (username: michiel, password: dejong)"

    else
        echo "Running tests in CI mode..."

        # Cypress configuration file
        local cypress_config="${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"

        # Adjust Cypress configurations for non-default browser platforms
        if [ "${BROWSER_PLATFORM}" != "electron" ]; then
            sed -i 's/.*video: true,.*/video: false,/' "${cypress_config}"
            sed -i 's/.*videoCompression: true,.*/videoCompression: false,/' "${cypress_config}"
        fi

        # Extract major version numbers for EFSS platforms
        local P1_VER="${EFSS_PLATFORM_1_VERSION%%.*}"
        local P2_VER="${EFSS_PLATFORM_2_VERSION%%.*}"

        # Run Cypress tests in headless mode
        echo "Running Cypress tests..."
        docker run --network="${DOCKER_NETWORK}" \
            --name="cypress.docker" \
            -v "${ENV_ROOT}/cypress/ocm-test-suite:/ocm" \
            -w /ocm \
            "${CYPRESS_REPO}":"${CYPRESS_TAG}" \
            cypress run \
            --browser "${BROWSER_PLATFORM}" \
            --spec "cypress/e2e/invite-link/nextcloud-${P1_VER}-to-nextcloud-${P2_VER}.cy.js" || error_exit "Cypress tests failed."

        # Revert Cypress configuration changes
        if [ "${BROWSER_PLATFORM}" != "electron" ]; then
            sed -i 's/.*video: false,.*/  video: true,/' "${cypress_config}"
            sed -i 's/.*videoCompression: false,.*/  videoCompression: true,/' "${cypress_config}"
        fi

        # Perform cleanup after CI tests
        echo "Cleaning up test environment..."
        if [ -x "${ENV_ROOT}/scripts/clean.sh" ]; then
            "${ENV_ROOT}/scripts/clean.sh" "no"
        else
            print_error "Cleanup script not found or not executable at '${ENV_ROOT}/scripts/clean.sh'."
        fi
    fi
}

# -----------------------------------------------------------------------------------
# Execute the main function with passed arguments
# -----------------------------------------------------------------------------------
main "$@"
