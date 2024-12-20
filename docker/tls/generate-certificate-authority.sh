#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Certificate Authority Generation Script
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# -----------------------------------------------------------------------------------

# Description:
#   This script generates a private key and a self-signed certificate for a custom
#   Certificate Authority (CA) in a Docker-based development environment. The resulting
#   CA files (private key and certificate) can be used to sign certificates for various
#   services within the environment, enabling secure, trusted TLS communication.
#
# Requirements:
#   - OpenSSL must be installed and available in PATH.
#
# Notes:
#   - The CA private key and certificate are stored in the "certificate-authority" directory.
#   - The certificate is set to expire in ~100 years (36500 days), which is convenient
#     for long-lived development environments without worrying about frequent renewals.
#
# Example:
#   ./generate-ca.sh
#
# Exit Codes:
#   0 - Success
#   1 - Failure due to inability to generate keys, certificates, or navigate directories.
#
# -----------------------------------------------------------------------------------

# Halt on errors and treat pipeline failures as errors
set -e
set -o pipefail

# -----------------------------------------------------------------------------------
# Function: get_script_dir
# Purpose: Resolve the directory where the script is located, even if it is a symlink.
# Returns: The absolute path to the script's directory.
# -----------------------------------------------------------------------------------
get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [[ -L "${source}" ]]; do
        local dir
        dir="$(cd -P "$(dirname "${source}")" >/dev/null 2>&1 && pwd)"
        source="$(readlink "${source}")"
        [[ "${source}" != /* ]] && source="${dir}/${source}"
    done
    cd -P "$(dirname "${source}")" >/dev/null 2>&1 && pwd
}

# -----------------------------------------------------------------------------------
# Initialize Environment Variables
# -----------------------------------------------------------------------------------
DIR=$(get_script_dir)
cd "${DIR}" || { echo "Error: Unable to navigate to script directory." >&2; exit 1; }
ENV_ROOT=$(pwd)
export ENV_ROOT

# Directory for storing CA files
CA_DIR="${ENV_ROOT}/certificate-authority"

# -----------------------------------------------------------------------------------
# Function: generate_ca
# Purpose: Generate the Certificate Authority private key and self-signed certificate.
# Behavior:
#   1. Ensures the CA directory exists.
#   2. Generates a 2048-bit RSA private key.
#   3. Creates a self-signed certificate valid for 36500 days (~100 years).
#
# On Error:
#   - Prints an error message and exits with code 1.
# -----------------------------------------------------------------------------------
generate_ca() {
    # Ensure the CA directory exists
    mkdir -p "${CA_DIR}"

    # Check that openssl is available
    if ! command -v openssl >/dev/null 2>&1; then
        echo "Error: OpenSSL is not installed or not in PATH." >&2
        exit 1
    fi

    # Generate the CA private key
    printf "Generating Certificate Authority private key...\n"
    if ! openssl genrsa -out "${CA_DIR}/dev-stock.key" 2048; then
        echo "Error: Failed to generate CA private key." >&2
        exit 1
    fi

    # Generate the self-signed CA certificate
    printf "Generating self-signed Certificate Authority certificate...\n"
    if ! openssl req -new -x509 \
        -days 36500 \
        -key "${CA_DIR}/dev-stock.key" \
        -out "${CA_DIR}/dev-stock.crt" \
        -subj "/C=RO/ST=Bucharest/L=Bucharest/O=IT/CN=dev-stock"; then
        echo "Error: Failed to generate CA certificate." >&2
        exit 1
    fi

    # Print success message with file locations
    printf "\nCertificate Authority setup complete.\n"
    printf "Private Key: %s/dev-stock.key\n" "${CA_DIR}"
    printf "Certificate: %s/dev-stock.crt\n" "${CA_DIR}"
}

# -----------------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------------

# Start the CA generation process
generate_ca
