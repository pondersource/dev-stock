#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Script to hold all the utility functions needed in the Dev Stock.
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# -----------------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status,
# a variable is used but not defined, or a command in a pipeline fails
set -euo pipefail

# -----------------------------------------------------------------------------------
# Constants and Default Values
# -----------------------------------------------------------------------------------

# Default versions
DEFAULT_EFSS_1_VERSION="${1}"
DEFAULT_EFSS_2_VERSION="${2}"
DEFAULT_SCRIPT_MODE="dev"
DEFAULT_BROWSER_PLATFORM="electron"
export DEFAULT_EFSS_1_VERSION="${DEFAULT_EFSS_1_VERSION}"
export DEFAULT_EFSS_2_VERSION="${DEFAULT_EFSS_2_VERSION}"
export DEFAULT_SCRIPT_MODE="${DEFAULT_SCRIPT_MODE}"
export DEFAULT_BROWSER_PLATFORM="${DEFAULT_BROWSER_PLATFORM}"

# Docker network name
DOCKER_NETWORK="testnet"
export DOCKER_NETWORK="${DOCKER_NETWORK}"

# MariaDB root password
MARIADB_ROOT_PASSWORD="eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek"
export MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD}"

# Paths to required directories
TEMP_DIR="temp"
TLS_CA_DIR="docker/tls/certificate-authority"
TLS_CERTIFICATES_DIR="docker/tls/certificates"
export TEMP_DIR="${TEMP_DIR}"
export TLS_CA_DIR="${TLS_CA_DIR}"
export TLS_CERTIFICATES_DIR="${TLS_CERTIFICATES_DIR}"

# 3rd party containers
CYPRESS_REPO=cypress/included
CYPRESS_TAG=13.13.1
FIREFOX_REPO=jlesage/firefox
FIREFOX_TAG=v24.11.1
MARIADB_REPO=mariadb
MARIADB_TAG=11.4.4
VNC_REPO=theasp/novnc
VNC_TAG=latest
export CYPRESS_REPO="${CYPRESS_REPO}"
export CYPRESS_TAG="${CYPRESS_TAG}"
export FIREFOX_REPO="${FIREFOX_REPO}"
export FIREFOX_TAG="${FIREFOX_TAG}"
export MARIADB_REPO="${MARIADB_REPO}"
export MARIADB_TAG="${MARIADB_TAG}"
export VNC_REPO="${VNC_REPO}"
export VNC_TAG="${VNC_TAG}"

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
# Function: ensure_required_commands
# Purpose : Ensure that certain commands (e.g., docker) are available on the system.
# Arguments: (none)
# Returns  : 
#   Calls error_exit if any required command is missing.
# -----------------------------------------------------------------------------------
ensure_required_commands() {
    # Ensure required commands are available (here, just 'docker')
    for cmd in docker; do
        if ! command_exists "${cmd}"; then
            error_exit "Required command '${cmd}' is not available. Please install it and try again."
        fi
    done
}

# -----------------------------------------------------------------------------------
# Function: ensure_docker_running
# Purpose : 
#   1) Verify that the Docker daemon is running and accessible (e.g., user permissions).
#
# Arguments:
#   (none)
#
# Returns :
#   Exits with an error if Docker is either not installed or not running.
# -----------------------------------------------------------------------------------
ensure_docker_running() {
    # Check if the Docker daemon is running (or user has permission)
    # 'docker info' returns non-zero if the daemon is not reachable.
    if ! docker info >/dev/null 2>&1; then
        error_exit "Cannot connect to the Docker daemon. Is it running and do you have the right permissions?"
    fi
}

# -----------------------------------------------------------------------------------
# Setup Functions
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Function: extract_platform_variables
# Purpose : 
#   1) Use the script's own file path to determine:
#      - TEST_SCENARIO (from its parent directory)
#      - EFSS_PLATFORM_1 and EFSS_PLATFORM_2 (from the file name minus .sh)
#   2) Export the resulting variables for use in the rest of the script.
#
# Arguments:
#   (none)
# Returns :
#   Exports TEST_SCENARIO, EFSS_PLATFORM_1, EFSS_PLATFORM_2
# -----------------------------------------------------------------------------------
extract_platform_variables() {
    # Extract the parent folder name as TEST_SCENARIO
    local test_scenario
    test_scenario="$(basename "$(dirname "${SOURCE}")")"

    # Extract the filename without the .sh extension
    local filename
    filename="$(basename "${SOURCE}" .sh)"

    # Split the filename by '-' to get EFSS_PLATFORM_1 and EFSS_PLATFORM_2
    local platform1 platform2
    IFS='-' read -r platform1 platform2 <<< "${filename}"

    # Export the variables so the rest of the script can use them
    export TEST_SCENARIO="${test_scenario}"
    export EFSS_PLATFORM_1="${platform1}"
    export EFSS_PLATFORM_2="${platform2}"
}

# -----------------------------------------------------------------------------------
# Function: parse_arguments
# Purpose: Parse command-line arguments and set global variables.
# Arguments:
#   $@ - Command-line arguments
# -----------------------------------------------------------------------------------
parse_arguments() {
    EFSS_PLATFORM_1_VERSION="${1:-$DEFAULT_EFSS_1_VERSION}"
    EFSS_PLATFORM_2_VERSION="${2:-$DEFAULT_EFSS_2_VERSION}"
    SCRIPT_MODE="${3:-$DEFAULT_SCRIPT_MODE}"
    BROWSER_PLATFORM="${4:-$DEFAULT_BROWSER_PLATFORM}"

    export EFSS_PLATFORM_1_VERSION="${EFSS_PLATFORM_1_VERSION}"
    export EFSS_PLATFORM_2_VERSION="${EFSS_PLATFORM_2_VERSION}"
    export SCRIPT_MODE="${SCRIPT_MODE}"
    export BROWSER_PLATFORM="${BROWSER_PLATFORM}"
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
# Function: prepare_environment
# Purpose: 1) Prepare temporary directories and copy necessary files
#          2) Run cleanup script (if it exists)
#          3) Ensure the specified Docker network is available
# -----------------------------------------------------------------------------------
prepare_environment() {
    # Prepare temporary directories and copy necessary files
    remove_directory "${ENV_ROOT}/${TEMP_DIR}" && mkdir -p "${ENV_ROOT}/${TEMP_DIR}"

    # Clean up previous resources (if the cleanup script is available)
    if [ -x "${ENV_ROOT}/scripts/clean.sh" ]; then
        "${ENV_ROOT}/scripts/clean.sh" "no"
    else
        print_error "Cleanup script not found or not executable at '${ENV_ROOT}/scripts/clean.sh'. Continuing without cleanup."
    fi

    # Ensure Docker network exists
    if ! docker network inspect "${DOCKER_NETWORK}" >/dev/null 2>&1; then
        docker network create "${DOCKER_NETWORK}" >/dev/null 2>&1 ||
            error_exit "Failed to create Docker network '${DOCKER_NETWORK}'."
    fi
}

# -----------------------------------------------------------------------------------
# Function: setup_initial_environment
# Purpose : 
#   1) Extract platform-dependent variables from the script path.
#   2) Ensure required commands (and Docker daemon) are running.
#   3) Parse command-line arguments.
#   4) Validate necessary files.
#   5) Prepare the environment (e.g., set up networks, clean old resources).
#
# Arguments:
#   * - All arguments passed to the script (forwarded to parse_arguments).
#
# Returns : None. Exits on error if a required step fails.
# -----------------------------------------------------------------------------------
setup() {
    # Get platform dependent variables.
    extract_platform_variables

    # Ensure required commands (including Docker) are available.
    ensure_required_commands
    ensure_docker_running

    # Parse CLI arguments
    parse_arguments "$@"

    # Validate required files/directories
    validate_files

    # Prepare the environment
    prepare_environment
}

# -----------------------------------------------------------------------------------
# Function: print_ocm_test_setup_instructions
# Purpose : Print messages indicating that the development environment is ready,
#           along with URLs and usage notes.
# Arguments: (none)
# Returns  : (none)
# -----------------------------------------------------------------------------------
print_ocm_test_setup_instructions() {
    echo ""
    echo "Development environment setup complete."
    echo "Access the following URLs in your browser:"
    echo "  Cypress inside VNC Server -> http://localhost:5700/vnc.html"
    echo "  Embedded Firefox          -> http://localhost:5800"
    echo "Note:"
    echo "  Scale VNC to get to the Continue button, and run the appropriate test from ./cypress/ocm-test-suite/cypress/e2e/"
    echo ""
    echo "Log in to EFSS platforms using the following credentials:"
}

# -----------------------------------------------------------------------------------
# Function: create_firefox
# Purpose : Launch a Firefox container with the necessary environment variables,
#           volume mounts, and network configuration.
# Arguments: (none)
# Returns  : (none)
#
# Example Usage:
#   create_firefox
# -----------------------------------------------------------------------------------
create_firefox() {
    # Print message (quiet in CI mode)
    run_quietly_if_ci echo "Starting Firefox container..."

    # Run Docker container with the specified parameters
    run_docker_container --detach \
        --network="${DOCKER_NETWORK}" \
        --name="firefox" \
        -p 5800:5800 \
        --shm-size=2g \
        -e USER_ID="$(id -u)" \
        -e GROUP_ID="$(id -g)" \
        -e DARK_MODE=1 \
        -v "${ENV_ROOT}/docker/tls/browsers/firefox/cert9.db:/config/profile/cert9.db:rw" \
        -v "${ENV_ROOT}/docker/tls/browsers/firefox/cert_override.txt:/config/profile/cert_override.txt:rw" \
        "${FIREFOX_REPO}:${FIREFOX_TAG}" || error_exit "Failed to start Firefox."
}

# -----------------------------------------------------------------------------------
# Function: create_vnc
# Purpose : Launch a VNC server container with the necessary environment variables,
#           volume mounts, and network configuration.
# Arguments: (none)
# Returns  : (none)
#
# Example Usage:
#   create_vnc
# -----------------------------------------------------------------------------------
create_vnc() {
    # Print message (quiet in CI mode)
    run_quietly_if_ci echo "Starting VNC Server..."

    # Define path to the X11 socket directory
    X11_SOCKET="${ENV_ROOT}/${TEMP_DIR}/.X11-unix"
    export X11_SOCKET="${X11_SOCKET}"

    # Clean up any previous socket files and create a new directory
    remove_directory "${X11_SOCKET}"
    mkdir -p "${X11_SOCKET}"

    # Launch the VNC server container
    run_docker_container --detach \
        --network="${DOCKER_NETWORK}" \
        --name="vnc-server" \
        -p 5700:8080 \
        -e RUN_XTERM=no \
        -e DISPLAY_WIDTH=1920 \
        -e DISPLAY_HEIGHT=1080 \
        -v "${X11_SOCKET}:/tmp/.X11-unix" \
        "${VNC_REPO}:${VNC_TAG}" || error_exit "Failed to start VNC Server."
}

# -----------------------------------------------------------------------------------
# Function: create_cypress_dev
# Purpose : Launch a Cypress container with the necessary environment variables,
#           volume mounts, and network configuration.
# Arguments: (none)
# Returns  : (none)
#
# Requirements:
#   - Environment vars: DOCKER_NETWORK, ENV_ROOT, X11_SOCKET, CYPRESS_REPO, CYPRESS_TAG
#   - External function: run_docker_container
#
# Example Usage:
#   create_cypress_dev
# -----------------------------------------------------------------------------------
create_cypress_dev() {
    # Print message (quiet in CI mode)
    run_quietly_if_ci echo "Starting Cypress container..."

    run_docker_container --detach \
        --network="${DOCKER_NETWORK}" \
        --name="cypress.docker" \
        -e DISPLAY="vnc-server:0.0" \
        -v "${ENV_ROOT}/cypress/ocm-test-suite:/ocm" \
        -v "${X11_SOCKET}:/tmp/.X11-unix" \
        -w /ocm \
        --entrypoint cypress \
        "${CYPRESS_REPO}:${CYPRESS_TAG}" \
        open --project . || error_exit "Failed to start Cypress."
}

# -----------------------------------------------------------------------------------
# Function: create_cypress_ci
# Purpose : Run Cypress tests in headless mode with the specified parameters.
# Arguments:
#   1) ${1} - The Cypress spec path (relative path to the spec file).
# Returns  : (none) - exits on error
#
# Usage Example:
#   create_cypress_ci "cypress/e2e/share-with/nextcloud-v27-to-nextcloud-v28.cy.js"
# -----------------------------------------------------------------------------------
create_cypress_ci() {
    local cypress_spec="${1}"

    if [[ -z "$cypress_spec" ]]; then
        error_exit "No Cypress spec provided. Usage: create_cypress_ci <spec-path>"
    fi

    # Print message (quiet in CI mode)
    run_quietly_if_ci echo "Running Cypress tests using spec: $cypress_spec"

    docker run --network="${DOCKER_NETWORK}" \
        --name="cypress.docker" \
        -v "${ENV_ROOT}/cypress/ocm-test-suite:/ocm" \
        -w /ocm \
        "${CYPRESS_REPO}:${CYPRESS_TAG}" \
        cypress run \
        --browser "${BROWSER_PLATFORM}" \
        --spec "${cypress_spec}" ||
        error_exit "Cypress tests failed."
}

# -----------------------------------------------------------------------------------
# Function: create_nextcloud
# Purpose: Create a Nextcloud container with a MariaDB backend.
# Arguments:
#   $1 - Instance number.
#   $2 - Admin username.
#   $3 - Admin password.
#   $4 - Image name.
#   $5 - Image tag.
# -----------------------------------------------------------------------------------
create_nextcloud() {
    local number="${1}"
    local user="${2}"
    local password="${3}"
    local image="${4}"
    local tag="${5}"

    run_quietly_if_ci echo "Creating EFSS instance: nextcloud ${number}"

    # Start MariaDB container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="marianextcloud${number}.docker" \
        -e MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD}" \
        "${MARIADB_REPO}":"${MARIADB_TAG}" \
        --transaction-isolation=READ-COMMITTED \
        --log-bin=binlog \
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
        -e NEXTCLOUD_HOST="nextcloud${number}.docker" \
        -e NEXTCLOUD_TRUSTED_DOMAINS="nextcloud${number}.docker" \
        -e NEXTCLOUD_ADMIN_USER="${user}" \
        -e NEXTCLOUD_ADMIN_PASSWORD="${password}" \
        -e NEXTCLOUD_APACHE_LOGLEVEL="warn" \
        -e MYSQL_HOST="marianextcloud${number}.docker" \
        -e MYSQL_DATABASE="efss" \
        -e MYSQL_USER="root" \
        -e MYSQL_PASSWORD="${MARIADB_ROOT_PASSWORD}" \
        "${image}:${tag}" || error_exit "Failed to start EFSS container for nextcloud ${number}."

    # Wait for EFSS port to open
    run_quietly_if_ci wait_for_port "nextcloud${number}.docker" 443
}

# -----------------------------------------------------------------------------------
# Function: create_owncloud
# Purpose: Create a ownCloud container with a MariaDB backend.
# Arguments:
#   $1 - Instance number.
#   $2 - Admin username.
#   $3 - Admin password.
#   $4 - Image name.
#   $5 - Image tag.
# -----------------------------------------------------------------------------------
create_owncloud() {
    local number="${1}"
    local user="${2}"
    local password="${3}"
    local image="${4}"
    local tag="${5}"

    run_quietly_if_ci echo "Creating EFSS instance: owncloud ${number}"

    # Start MariaDB container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="mariaowncloud${number}.docker" \
        -e MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD}" \
        "${MARIADB_REPO}":"${MARIADB_TAG}" \
        --transaction-isolation=READ-COMMITTED \
        --log-bin=binlog \
        --binlog-format=ROW \
        --innodb-file-per-table=1 \
        --skip-innodb-read-only-compressed || error_exit "Failed to start MariaDB container for owncloud ${number}."

    # Wait for MariaDB port to open
    wait_for_port "mariaowncloud${number}.docker" 3306

    # Start EFSS container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="owncloud${number}.docker" \
        --add-host "host.docker.internal:host-gateway" \
        -e HOST="owncloud${number}" \
        -e OWNCLOUD_HOST="owncloud${number}.docker" \
        -e OWNCLOUD_TRUSTED_DOMAINS="owncloud${number}.docker" \
        -e OWNCLOUD_ADMIN_USER="${user}" \
        -e OWNCLOUD_ADMIN_PASSWORD="${password}" \
        -e OWNCLOUD_APACHE_LOGLEVEL="warn" \
        -e MYSQL_HOST="mariaowncloud${number}.docker" \
        -e MYSQL_DATABASE="efss" \
        -e MYSQL_USER="root" \
        -e MYSQL_PASSWORD="${MARIADB_ROOT_PASSWORD}" \
        "${image}:${tag}" || error_exit "Failed to start EFSS container for owncloud ${number}."

    # Wait for EFSS port to open
    run_quietly_if_ci wait_for_port "owncloud${number}.docker" 443
}

# -----------------------------------------------------------------------------------
# Function:  create_ocmstub
# Purpose: Create a OcmStub container.
# Arguments:
#   $1 - Instance number.
#   $2 - Image name.
#   $3 - Image tag.
# -----------------------------------------------------------------------------------
function create_ocmstub() {
  local number="${1}"
  local image="${2}"
  local tag="${3}"

  run_quietly_if_ci echo "Creating EFSS instance: ocmstub ${number}"

  run_quietly_if_ci docker run --detach --network="${DOCKER_NETWORK}" \
    --name="ocmstub${number}.docker" \
    -e HOST="ocmstub${number}" \
    "${image}:${tag}" || error_exit "Failed to start EFSS container for ocmstub ${number}."

  # Wait for EFSS port to open
  run_quietly_if_ci wait_for_port "ocmstub${number}.docker" 443
}

# -----------------------------------------------------------------------------------
# Function: run_dev
# Purpose :
#   1) Quietly log environment setup when in CI.
#   2) Create Firefox, VNC, and Cypress containers in dev mode.
#   3) Print OCM test setup instructions.
#   4) Echo two additional lines (supplied as arguments), e.g. EFSS login URLs.
#
# Arguments:
#   1) $1 - The first line to echo (e.g., "https://nextcloud1.docker (username...)")
#   2) $2 - The second line to echo (e.g., "https://nextcloud2.docker (username...)")
#
# Example Usage:
#   run_dev \
#       "https://nextcloud1.docker (username: einstein, password: relativity)" \
#       "https://nextcloud2.docker (username: michiel, password: dejong)"
#
# Returns : None
# -----------------------------------------------------------------------------------
run_dev() {
    local url_line_1="${1}"
    local url_line_2="${2}"

    # Quiet log in CI mode
    run_quietly_if_ci echo "Setting up development environment..."

    # Create containers for Firefox, VNC, and Cypress (dev mode)
    create_firefox
    create_vnc
    create_cypress_dev

    # Display setup instructions
    print_ocm_test_setup_instructions

    # Echo the two lines passed as arguments
    echo "  ${url_line_1}"
    echo "  ${url_line_2}"
}

# -----------------------------------------------------------------------------------
# Function: run_ci
# Purpose :
#   1) Update Cypress config based on the chosen browser platform (disables video
#      unless the BROWSER_PLATFORM is "electron").
#   2) Compute major EFSS platform version numbers and run Cypress tests headlessly,
#      using a test scenario path that is dynamically formed.
#   3) Revert Cypress config changes and perform a cleanup of the environment.
#
# Arguments:
#   1) $1 - The test scenario folder name (sub-path under cypress/e2e/).
#   2) $2 - The EFSS platform 1 name (e.g., "nextcloud").
#   3) $3 - The EFSS platform 2 name (e.g., "nextcloud", "owncloud", etc.).
#
# Returns :
#   None. Exits (via error_exit) on critical failure.
# -----------------------------------------------------------------------------------
run_ci() {
    # Print message (quiet in CI mode)
    run_quietly_if_ci echo "Running tests in CI mode..."

    # Validate arguments
    local test_scenario="${1}"
    local efss_platform_1="${2}"
    local efss_platform_2="${3}"

    if [[ -z "${test_scenario}" || -z "${efss_platform_1}" || -z "${efss_platform_2}" ]]; then
        error_exit "Usage: run_ci <test_scenario> <efss_platform_1> <efss_platform_2>"
    fi

    # Cypress config file path
    local cypress_config="${ENV_ROOT}/cypress/ocm-test-suite/cypress.config.js"

    # Ensure the config file actually exists
    if [[ ! -f "${cypress_config}" ]]; then
        error_exit "Cypress config file not found at '${cypress_config}'."
    fi

    # Adjust Cypress configurations for non-default browser platforms
    if [[ "${BROWSER_PLATFORM}" != "electron" ]]; then
        # Disable video and video compression
        sed -i 's/.*video: true,.*/video: false,/' "${cypress_config}"
        sed -i 's/.*videoCompression: true,.*/videoCompression: false,/' "${cypress_config}"
    fi

    # Extract major version numbers for EFSS platforms
    local p1_ver="${EFSS_PLATFORM_1_VERSION%%.*}"
    local p2_ver="${EFSS_PLATFORM_2_VERSION%%.*}"

    # Construct spec file path from the arguments
    local spec_path="cypress/e2e/${test_scenario}/${efss_platform_1}-${p1_ver}-to-${efss_platform_2}-${p2_ver}.cy.js"

    # Run Cypress tests in headless mode
    if ! create_cypress_ci "${spec_path}"; then
        error_exit "Failed to run Cypress tests with spec '${spec_path}'."
    fi

    # Revert Cypress configuration changes if we modified them
    if [[ "${BROWSER_PLATFORM}" != "electron" ]]; then
        sed -i 's/.*video: false,.*/  video: true,/' "${cypress_config}"
        sed -i 's/.*videoCompression: false,.*/  videoCompression: true,/' "${cypress_config}"
    fi

    # Perform cleanup after CI tests
    echo "Cleaning up test environment..."
    if [[ -x "${ENV_ROOT}/scripts/clean.sh" ]]; then
        "${ENV_ROOT}/scripts/clean.sh" "no"
    else
        print_error "Cleanup script not found or not executable at '${ENV_ROOT}/scripts/clean.sh'."
    fi
}
