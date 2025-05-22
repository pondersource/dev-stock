#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Certificate Generation Script for Development Environments
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# -----------------------------------------------------------------------------------

# Description:
#   This script generates self-signed certificates for various services in a Docker-based
#   development environment. The certificates are signed using a custom Certificate
#   Authority (CA) provided in the "certificate-authority" directory. It supports
#   generating certificates for multiple EFSS (Enterprise File Synchronization and Sharing)
#   instances and associated services (Reva, WOPI), as well as standalone services like
#   mesh directories and identity providers (idp).
#
# Requirements:
#   - OpenSSL must be installed and available in PATH.
#   - A custom CA must be present in the "certificate-authority" directory.
#     Files required: "dev-stock.crt" and "dev-stock.key".
#
# Behavior:
#   - The script removes and recreates the "certificates" directory at each run, ensuring a
#     clean state.
#   - Certificates are generated with a 100-year validity (36500 days) for convenience in
#     long-term development environments.
#   - Ownership of "idp" certificates is adjusted to user "1000:root" to meet specific service
#     requirements.
#
# Notes:
#   - The script assumes a ".docker" domain is used for all services (e.g., "idp.docker",
#     "owncloud1.docker").
#   - Add or remove services or EFSS instances by modifying the arrays and loops below.
#
# Example:
#   ./generate-certificates.sh
#
# Exit Codes:
#   0 - Success
#   1 - Failure due to missing directories, CA files, or certificate signing issues.

# -----------------------------------------------------------------------------------
# Safety and Error Handling
# -----------------------------------------------------------------------------------

# Halt on any errors and treat pipeline failures as errors
set -e
set -o pipefail

# -----------------------------------------------------------------------------------
# Function to Resolve Script Location
# -----------------------------------------------------------------------------------
# Resolves the directory where the script is located, even if it is a symlink.
get_script_dir() {
    local source=${BASH_SOURCE[0]}
    while [[ -L "${source}" ]]; do
        local dir; dir=$(cd -P "$(dirname "${source}")" >/dev/null 2>&1 && pwd)
        source=$(readlink "${source}")
        [[ "${source}" != /* ]] && source="${dir}/${source}" # Resolve relative symlinks
    done
    cd -P "$(dirname "${source}")" >/dev/null 2>&1 && pwd
}

# Set the environment root to the directory containing this script
DIR=$(get_script_dir)
cd "${DIR}" || { echo "Error: Unable to navigate to script directory." >&2; exit 1; }
ENV_ROOT=$(pwd)
export ENV_ROOT

# -----------------------------------------------------------------------------------
# Function to Generate Certificates
# -----------------------------------------------------------------------------------
# This function generates a self-signed certificate and private key for a given hostname.
#
# Arguments:
#   1. Hostname (e.g., "idp", "owncloud1")
#
# Process:
#   - Generates a private key and CSR (Certificate Signing Request) for the given hostname.
#   - Creates a configuration file specifying subjectAltName for the hostname.
#   - Uses the CA (dev-stock.crt and dev-stock.key) to sign the CSR, producing a .crt file.
#   - If the hostname is "idp", adjusts ownership of the generated files.
create_certificate() {
    local hostname=$1
    printf "Generating key and CSR for %s.docker\n" "${hostname}"

    # Ensure the certificates directory exists
    mkdir -p "${ENV_ROOT}/certificates"

    # Check if CA files exist
    if [[ ! -f "${ENV_ROOT}/certificate-authority/dev-stock.crt" || ! -f "${ENV_ROOT}/certificate-authority/dev-stock.key" ]]; then
        printf "Error: CA files not found. Expected dev-stock.crt and dev-stock.key in certificate-authority.\n" >&2
        exit 1
    fi

    # Generate the private key and CSR
    openssl req -new -nodes \
        -out "${ENV_ROOT}/certificates/${hostname}.csr" \
        -keyout "${ENV_ROOT}/certificates/${hostname}.key" \
        -subj "/C=RO/ST=Bucharest/L=Bucharest/O=IT/CN=${hostname}.docker"

    # Create a configuration file for subjectAltName
    printf "Creating extfile for %s.docker\n" "${hostname}"
    cat > "${ENV_ROOT}/certificates/${hostname}.cnf" <<EOF
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${hostname}.docker
EOF

    # Sign the CSR using the custom CA
    printf "Signing CSR for %s.docker, creating certificate.\n" "${hostname}"
    if ! openssl x509 -req \
        -days 36500 \
        -in "${ENV_ROOT}/certificates/${hostname}.csr" \
        -CA "${ENV_ROOT}/certificate-authority/dev-stock.crt" \
        -CAkey "${ENV_ROOT}/certificate-authority/dev-stock.key" \
        -CAcreateserial \
        -out "${ENV_ROOT}/certificates/${hostname}.crt" \
        -extfile "${ENV_ROOT}/certificates/${hostname}.cnf"; then
        printf "Error: Failed to sign certificate for %s.\n" "${hostname}" >&2
        exit 1
    fi

    # Adjust ownership of generated files for "idp"
    if [[ "${hostname}" == "idp" ]]; then
        printf "Changing ownership for %s certificates.\n" "${hostname}"
        sudo chown 1000:root "${ENV_ROOT}/certificates/${hostname}."*
    fi
}

# -----------------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------------

# Clean up and recreate the certificates directory
rm -rf "${ENV_ROOT}/certificates"
mkdir -p "${ENV_ROOT}/certificates"

# Generate certificates for standalone services
create_certificate idp
create_certificate meshdir
create_certificate revad1
create_certificate revad2

# Generate certificates for multiple EFSS (Enterprise File Sync and Share) instances
efss_list=("owncloud" "nextcloud" "cernbox")
for efss in "${efss_list[@]}"; do
    for i in {1..4}; do
        create_certificate "${efss}${i}"     # EFSS instance
        create_certificate "reva${efss}${i}" # Reva service for EFSS
        create_certificate "wopi${efss}${i}" # WOPI service for EFSS
    done
done

# Generate certificates for additional EFSS instances
additional_efss=("seafile" "ocis" "opencloud" "ocmstub")
for efss in "${additional_efss[@]}"; do
    for i in {1..4}; do
        create_certificate "${efss}${i}"
    done
done

printf "All certificates generated successfully.\n"
