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
trap 'rm -rf /tls' EXIT

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

# Print the command about to be executed for clarity
printf "Executing command: %s\n" "$*"

# Execute the provided command with exec so that it becomes the container's main process
exec "$@"
