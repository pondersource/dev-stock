#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Docker Push Script for PonderSource Development Images
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# -----------------------------------------------------------------------------------
# This script pushes various Docker images for the PonderSource development environment,
# including both third-party and PonderSource-specific images. It ensures that necessary
# Docker images are pushed from specified repositories for continuous integration,
# development, and testing purposes.
#
# The script allows users to control the execution mode via a command-line argument
# (either 'dev' or 'ci'). In 'ci' mode, the output is suppressed to avoid clutter.
# -----------------------------------------------------------------------------------

# -----------------------------------------------------------------------------------
# Exit Immediately if a Command Fails
# -----------------------------------------------------------------------------------
# Exit on error. If any command fails, the script stops execution to avoid issues
# with potentially broken states. The `pipefail` option ensures that if any command 
# in a pipeline fails, the entire pipeline returns a non-zero exit status.
set -eo pipefail

# -----------------------------------------------------------------------------------
# Constants and Default Values
# -----------------------------------------------------------------------------------

# Default execution mode is 'dev', which shows full output. 'ci' mode suppresses output.
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
# Parse Command-Line Arguments
# -----------------------------------------------------------------------------------
parse_arguments "$@"  # Parse any arguments passed to the script.

# Ensure successful login to Docker before pushing images.
echo "Logging in to Docker as pondersource..."
if ! docker login -u pondersource; then
    echo "Docker login failed. Exiting."
    exit 1
fi

# -----------------------------------------------------------------------------------
# Push PonderSource-Specific Docker Images
# -----------------------------------------------------------------------------------
run_quietly_if_ci echo "Pushing PonderSource-specific Docker images..."

# Push the core PonderSource images.
run_quietly_if_ci docker push pondersource/revad:latest

# OcmStub: push multiple versions of the OcmStub Docker image.
ocmstub_versions=("latest" "v1.0.0")
for version in "${ocmstub_versions[@]}"; do
    run_quietly_if_ci docker push "pondersource/ocmstub:${version}"
done

# Nextcloud: push multiple versions of the Nextcloud Docker image.
run_quietly_if_ci docker push pondersource/nextcloud-base:latest
nextcloud_versions=("latest" "v30.0.2" "v29.0.10" "v28.0.14" "v27.1.11")
for version in "${nextcloud_versions[@]}"; do
    run_quietly_if_ci docker push "pondersource/nextcloud:${version}"
done

run_quietly_if_ci docker push pondersource/nextcloud:v27.1.11-sm

# ownCloud: push multiple versions of the ownCloud Docker image.
run_quietly_if_ci docker push pondersource/owncloud-base:latest
owncloud_versions=("latest" "v10.15.0")
for version in "${owncloud_versions[@]}"; do
    run_quietly_if_ci docker push "pondersource/owncloud:${version}"
done

run_quietly_if_ci docker push pondersource/owncloud:v10.15.0-sm

# -----------------------------------------------------------------------------------
# End of Docker Push
# -----------------------------------------------------------------------------------
run_quietly_if_ci echo "Docker push completed successfully."
