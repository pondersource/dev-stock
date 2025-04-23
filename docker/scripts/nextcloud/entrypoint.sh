#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Docker Initialization Script for TLS Certificates
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# -----------------------------------------------------------------------------------

# Description:
#   This script runs inside a Docker container to set up TLS certificates for a given
#   host. It copies certificates and keys from a specified directory, validates their
#   presence, and creates symbolic links for easy reference by the main service.
#   Finally, it executes the provided command (e.g., the container's CMD).
#
# Requirements:
#   - The HOST environment variable must be set.
#   - The /certificates directory should contain .crt and .key files matching the HOST.
#
# Usage:
#   In a Dockerfile:
#     COPY entrypoint.sh /entrypoint.sh
#     ENTRYPOINT ["/entrypoint.sh"]
#
#   The container's CMD will be executed by this script once TLS setup is complete.
#
# Notes:
#   - If HOST is "example.com", then the script expects to find "example.com.crt" and
#     "example.com.key" inside the /tls directory after copying from /certificates.
#   - The script creates /tls directory if it doesn't exist.
#   - Symbolic links are created:
#     /tls/server.crt -> /tls/${HOST}.crt
#     /tls/server.key -> /tls/${HOST}.key
#
# Example:
#   HOST=example.com docker run --rm -e HOST=example.com myimage:latest
#
# Exit Codes:
#   0 - Success
#   1 - Failure due to missing HOST, missing certificates, or command execution issues.

# -----------------------------------------------------------------------------------
# Safety and Error Handling
# -----------------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status,
# a variable is used but not defined, or a command in a pipeline fails
set -euo pipefail

# Define a trap to clean up resources on script exit or error.
# This ensures the /tls directory is removed if something goes wrong.

# @MahdiBaghbani: We don't need this, honestly, maybe we need it but I don't know
# under what circumstances would it become necessary, I'll leave it here.
# trap 'rm -rf /tls' EXIT

# -----------------------------------------------------------------------------------
# CI Environment Check
# -----------------------------------------------------------------------------------

# Log CI-specific variables when we appear to be running in CI
#   We consider it a CI context when we have a repo URL and either
#   - a commit hash (current build)  OR
#   - a tag        (stable build).
# -----------------------------------------------------------------------------
if [[ -n ${NEXTCLOUD_REPO_URL:-} && ( -n ${NEXTCLOUD_COMMIT_HASH:-} || -n ${NEXTCLOUD_TAG:-} ) ]]; then
    echo "CI environment detected:"
    echo "  NEXTCLOUD_REPO_URL : ${NEXTCLOUD_REPO_URL}"

    # Log whichever identifier is present
    [[ -n ${NEXTCLOUD_BRANCH:-}      ]] && echo "  NEXTCLOUD_BRANCH    : ${NEXTCLOUD_BRANCH}"
    [[ -n ${NEXTCLOUD_COMMIT_HASH:-} ]] && echo "  NEXTCLOUD_COMMIT_HASH: ${NEXTCLOUD_COMMIT_HASH}"
    [[ -n ${NEXTCLOUD_TAG:-}         ]] && echo "  NEXTCLOUD_TAG       : ${NEXTCLOUD_TAG}"
fi


# -----------------------------------------------------------------------------------
# Directory and Certificate Setup
# -----------------------------------------------------------------------------------

# Ensure the /tls directory exists
mkdir -p /tls

# If the /certificates directory exists, copy .crt and .key files to /tls
if [[ -d "/certificates" ]]; then
    printf "Copying certificates and keys to /tls...\n"
    # Copy .crt files
    find /certificates -type f -name "*.crt" -exec cp -f {} /tls/ \;

    # Copy .key files
    find /certificates -type f -name "*.key" -exec cp -f {} /tls/ \;

    printf "Certificate and key files copied successfully.\n"
else
    printf "Warning: /certificates directory does not exist. Skipping certificate copy.\n" >&2
fi

# -----------------------------------------------------------------------------------
# Validate HOST Environment Variable
# -----------------------------------------------------------------------------------

# Ensure the HOST environment variable is set
if [[ -z "${HOST}" ]]; then
    printf "Error: HOST environment variable is not set. Aborting.\n" >&2
    exit 1
fi

# -----------------------------------------------------------------------------------
# Check for HOST-Specific Certificate and Key
# -----------------------------------------------------------------------------------
crt_path="/tls/${HOST}.crt"
key_path="/tls/${HOST}.key"

if [[ -f "${crt_path}" && -f "${key_path}" ]]; then
    printf "Creating symbolic links for certificates...\n"
    # Create symbolic links to /tls/server.crt and /tls/server.key
    ln --symbolic --force "${crt_path}" /tls/server.crt
    ln --symbolic --force "${key_path}" /tls/server.key

    printf "Symbolic links created successfully.\n"
else
    printf "Error: Certificate or key file for host '%s' not found in /tls.\n" "${HOST}" >&2
    exit 1
fi

# -----------------------------------------------------------------------------------
# Execute the Provided Command
# -----------------------------------------------------------------------------------

# Print the command that is about to be executed
printf "Executing command: /init.sh\n"

# Validate that /init.sh exists and is executable
if [[ ! -x "/init.sh" ]]; then
    printf "Error: /init.sh does not exist or is not executable. Aborting.\n" >&2
    exit 1
fi

# Execute init 
"/init.sh" "${3}"

# Print the command that is about to be executed
printf "Executing command: %s\n" "$*"

# Execute the command using 'exec' so that it becomes the main process in the container
exec "$@"
