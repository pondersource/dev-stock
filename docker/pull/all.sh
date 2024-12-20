#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Docker Pull Script for PonderSource Development Images
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# -----------------------------------------------------------------------------------
# This script pulls various Docker images for the PonderSource development environment,
# including both third-party and PonderSource-specific images. It ensures that necessary
# Docker images are pulled from specified repositories for continuous integration,
# development, and testing purposes.
#
# The script allows users to control the execution mode via a command-line argument
# (either 'dev' or 'ci'). In 'ci' mode, the output is suppressed to avoid clutter.
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Exit Immediately if a Command Fails
# -----------------------------------------------------------------------------------
# Set the script to exit on the first error. This ensures that if any command fails,
# the script will stop and prevent further execution with potentially broken state.
# The `pipefail` option ensures that if a command in a pipeline fails, the whole pipeline
# will return a non-zero exit status.
set -eo pipefail

# -----------------------------------------------------------------------------------
# Constants and Default Values
# -----------------------------------------------------------------------------------

# Default execution mode is 'dev', which shows full output.
DEFAULT_SCRIPT_MODE="dev"

# -----------------------------------------------------------------------------------
# Function: run_quietly_if_ci
# Purpose: Run a command, suppressing stdout if in CI mode.
# Arguments:
#   $@ - The command and its arguments to execute.
# -----------------------------------------------------------------------------------
run_quietly_if_ci() {
    if [ "${SCRIPT_MODE}" = "ci" ]; then
        "$@" >/dev/null 2>&1  # Suppress both stdout and stderr in CI mode.
    else
        "$@"  # Run the command normally if not in CI mode.
    fi
}

# -----------------------------------------------------------------------------------
# Function: parse_arguments
# Purpose: Parse command-line arguments and set global variables.
# Arguments:
#   $@ - Command-line arguments
# -----------------------------------------------------------------------------------
parse_arguments() {
    SCRIPT_MODE="${1:-$DEFAULT_SCRIPT_MODE}"  # Default to 'dev' if no argument is provided.
}

# -----------------------------------------------------------------------------------
# Third-Party Docker Image Repositories and Tags
# -----------------------------------------------------------------------------------
CYPRESS_REPO="cypress/included"
CYPRESS_TAG="13.13.1"
FIREFOX_REPO="jlesage/firefox"
FIREFOX_TAG="v24.11.1"
MARIADB_REPO="mariadb"
MARIADB_TAG="11.4.4"
VNC_REPO="theasp/novnc"
VNC_TAG="latest"
REDIS_REPO="redis"
REDIS_TAG="latest"
MEMCACHED_REPO="memcached"
MEMCACHED_TAG="1.6.18"
RCLONE_REPO="rclone/rclone"
RCLONE_TAG="latest"
COLLABORA_REPO="collabora/code"
COLLABORA_TAG="latest"
WOPISERVER_REPO="cs3org/wopiserver"
WOPISERVER_TAG="latest"
SEAFILE_MC_REPO="seafileltd/seafile-mc"
SEAFILE_MC_TAG="11.0.5"
KEYCLOAK_REPO="quay.io/keycloak/keycloak"
KEYCLOAK_TAG="latest"

# -----------------------------------------------------------------------------------
# Parse Command-Line Arguments
# -----------------------------------------------------------------------------------
parse_arguments "$@"  # Parse any arguments passed to the script.

# -----------------------------------------------------------------------------------
# Pull Third-Party Docker Images
# -----------------------------------------------------------------------------------
run_quietly_if_ci echo "Pulling third-party Docker images..."

# Use run_quietly_if_ci to suppress output in CI mode
run_quietly_if_ci docker pull "${REDIS_REPO}:${REDIS_TAG}"
run_quietly_if_ci docker pull "${MEMCACHED_REPO}:${MEMCACHED_TAG}"
run_quietly_if_ci docker pull "${RCLONE_REPO}:${RCLONE_TAG}"
run_quietly_if_ci docker pull "${COLLABORA_REPO}:${COLLABORA_TAG}"
run_quietly_if_ci docker pull "${VNC_REPO}:${VNC_TAG}"
run_quietly_if_ci docker pull "${CYPRESS_REPO}:${CYPRESS_TAG}"
run_quietly_if_ci docker pull "${MARIADB_REPO}:${MARIADB_TAG}"
run_quietly_if_ci docker pull "${FIREFOX_REPO}:${FIREFOX_TAG}"
run_quietly_if_ci docker pull "${WOPISERVER_REPO}:${WOPISERVER_TAG}"
run_quietly_if_ci docker pull "${SEAFILE_MC_REPO}:${SEAFILE_MC_TAG}"
run_quietly_if_ci docker pull "${KEYCLOAK_REPO}:${KEYCLOAK_TAG}"

# -----------------------------------------------------------------------------------
# Pull PonderSource-Specific Docker Images
# -----------------------------------------------------------------------------------
run_quietly_if_ci echo "Pulling PonderSource-specific Docker images..."

run_quietly_if_ci docker pull pondersource/revad:latest
run_quietly_if_ci docker pull pondersource/ocmstub:latest
run_quietly_if_ci docker pull pondersource/ocmstub:v1.0.0

# Nextcloud: Pull multiple versions of the Nextcloud Docker image.
run_quietly_if_ci docker pull pondersource/nextcloud-base:latest
nextcloud_versions=("latest" "v30.0.2" "v29.0.10" "v28.0.14" "v27.1.11")
for version in "${nextcloud_versions[@]}"; do
    run_quietly_if_ci docker pull "pondersource/nextcloud:${version}"
done

# ownCloud: Pull multiple versions of the ownCloud Docker image.
run_quietly_if_ci docker pull pondersource/owncloud-base:latest
owncloud_versions=("latest" "v10.15.0")
for version in "${owncloud_versions[@]}"; do
    run_quietly_if_ci docker pull "pondersource/owncloud:${version}"
done

# -----------------------------------------------------------------------------------
# End of Docker Pulls
# -----------------------------------------------------------------------------------
run_quietly_if_ci echo "Docker pull completed successfully."
