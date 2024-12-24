#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Script to Automate the Release of Sciencemesh Application for ownCloud
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# -----------------------------------------------------------------------------------

# Description:
#   This script automates the process of preparing and releasing the Sciencemesh application for ownCloud.
#   It handles Docker container setup, builds the application, signs it, and uploads the release tarball to GitHub.

# Usage:
#   ./sciencemesh-owncloud.sh

# Prerequisites:
#   - Docker must be installed and accessible.
#   - GitHub repository must be accessible with an API token stored in the environment variable `GITHUB_TOKEN`.
#   - Required repositories, keys, and scripts must be available.
#   - User must have sufficient permissions to execute Docker and modify required files.
#   - Ensure that `jq` is installed for JSON parsing.

# Exit immediately on any error, treat unset variables as an error, and catch errors in pipelines.
set -euo pipefail

# -----------------------------------------------------------------------------------
# Constants and Configuration
# -----------------------------------------------------------------------------------

# Repository and branch for the ownCloud Sciencemesh app
REPO_OWNCLOUD_APP="https://github.com/sciencemesh/nc-sciencemesh"
BRANCH_OWNCLOUD_APP="owncloud"

# Docker images
MARIADB_IMAGE="mariadb:11.4.2"
OC_IMAGE="pondersource/owncloud-sciencemesh"
COMPOSER_IMAGE="pondersource/dev-stock-oc1-sciencemesh"

# Paths and filenames
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="${REPO_ROOT}/temp"
OC_RELEASE_DIR="${REPO_ROOT}/oc-sciencemesh-release"
INIT_SCRIPT_SOURCE="${REPO_ROOT}/docker/scripts/init/owncloud-sciencemesh.sh"
INIT_SCRIPT_DEST="${TEMP_DIR}/oc.sh"
TARBALL_DIR="${OC_RELEASE_DIR}/release"
TARBALL_NAME="sciencemesh.tar.gz"
TARBALL_PATH="${TARBALL_DIR}/${TARBALL_NAME}"

# GitHub release details
GITHUB_REPO="sciencemesh/nc-sciencemesh" # Update to your GitHub repository

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
# Functions
# -----------------------------------------------------------------------------------

# Function: Print an error message to stderr and exit with failure code.
print_error() {
    local message="$1"
    printf "Error: %s\n" "$message" >&2
    exit 1
}

# Function: Ensure a directory exists; create it if it does not.
ensure_directory_exists() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || print_error "Failed to create directory '$dir'."
    fi
}

# Function: Clean up temporary resources.
run_cleanup() {
    printf "Cleaning up resources...\n"
    if [ -x "${REPO_ROOT}/scripts/clean.sh" ]; then
        "${REPO_ROOT}/scripts/clean.sh"
    fi
    sudo chown -R "$(whoami):$(whoami)" "${OC_RELEASE_DIR}" 2>/dev/null || true
    sudo rm -rf "${OC_RELEASE_DIR}" 2>/dev/null || true
    sudo rm -rf "${TEMP_DIR}" 2>/dev/null || true
}

# Function: Create a GitHub release and upload the tarball.
create_github_release() {
    local repo="$1"
    local tag="$2"
    local name="$3"
    local file_path="$4"

    # Check for the required GitHub token.
    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        print_error "GITHUB_TOKEN environment variable is not set. It is required to create a GitHub release."
    fi

    # Step 1: Create the release.
    printf "Creating GitHub release '%s' with tag '%s'...\n" "${name}" "${tag}"
    local release_response
    release_response=$(curl -s -X POST "https://api.github.com/repos/${repo}/releases" \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
            --arg tag_name "$tag" \
            --arg name "$name" \
            --arg body "Automated release of the Sciencemesh application for ownCloud." \
            '{ tag_name: $tag_name, name: $name, body: $body, draft: false, prerelease: false }')")

    # Extract the upload URL from the release response.
    local upload_url
    upload_url=$(echo "${release_response}" | jq -r '.upload_url' | sed -e "s/{?name,label}//")
    if [[ -z "${upload_url}" || "${upload_url}" == "null" ]]; then
        print_error "Failed to create GitHub release. Response: ${release_response}"
    fi

    # Step 2: Upload the tarball to the release.
    printf "Uploading tarball '%s' to GitHub release...\n" "${file_path}"
    local upload_response
    upload_response=$(curl -s --data-binary @"${file_path}" \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Content-Type: application/gzip" \
        "${upload_url}?name=$(basename "${file_path}")")

    # Check if the upload was successful.
    if [[ $(echo "${upload_response}" | jq -r '.id') == "null" ]]; then
        print_error "Failed to upload tarball. Response: ${upload_response}"
    fi

    printf "Release '%s' created and tarball uploaded successfully.\n" "${name}"
}

# Function: Check if a command exists.
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function: Get the latest Git tag from the repository.
get_latest_git_tag() {
    local repo_dir="$1"
    local latest_tag

    cd "$repo_dir" || print_error "Failed to access directory '$repo_dir'."

    # Fetch all tags from the remote repository.
    git fetch --tags || print_error "Failed to fetch tags from the remote repository."

    # Get the latest tag based on version sort.
    latest_tag=$(git tag | sort -V | tail -n1)

    if [[ -z "$latest_tag" ]]; then
        print_error "No tags found in the repository."
    fi

    printf "%s" "$latest_tag"
}

# -----------------------------------------------------------------------------------
# Main script logic encapsulated in a function.
# -----------------------------------------------------------------------------------
main() {
    # Ensure required commands are available.
    for cmd in docker git curl jq; do
        if ! command_exists "$cmd"; then
            print_error "Required command '$cmd' is not available. Please install it and try again."
        fi
    done

    # Trap to ensure cleanup is run on script exit.
    trap run_cleanup EXIT

    # Step 1: Run the cleanup script at the beginning.
    if [ -x "${REPO_ROOT}/scripts/clean.sh" ]; then
        "${REPO_ROOT}/scripts/clean.sh"
    else
        print_error "Cleanup script not found or not executable at '${REPO_ROOT}/scripts/clean.sh'."
    fi

    # Step 2: Create the temporary directory.
    ensure_directory_exists "${TEMP_DIR}"

    # Step 3: Copy the initialization file to the temp directory.
    if [ -f "${INIT_SCRIPT_SOURCE}" ]; then
        cp -f "${INIT_SCRIPT_SOURCE}" "${INIT_SCRIPT_DEST}"
    else
        print_error "Initialization script not found at '${INIT_SCRIPT_SOURCE}'."
    fi

    # Step 4: Tag the Docker image.
    printf "Tagging Docker image '%s' as '%s'...\n" "${OC_IMAGE}" "${COMPOSER_IMAGE}"
    docker tag "${OC_IMAGE}" "${COMPOSER_IMAGE}" || print_error "Failed to tag Docker image."

    # Step 5: Clone the Sciencemesh source code repository if not already present.
    if [ ! -d "${OC_RELEASE_DIR}" ]; then
        printf "Cloning Sciencemesh repository...\n"
        git clone --branch "${BRANCH_OWNCLOUD_APP}" "${REPO_OWNCLOUD_APP}" "${OC_RELEASE_DIR}" || print_error "Failed to clone repository."

        # Navigate to the cloned repository directory.
        cd "${OC_RELEASE_DIR}" || print_error "Failed to access directory '${OC_RELEASE_DIR}'."

        # Run `composer` using the composer Docker image.
        printf "Running 'composer' inside Docker to build the application...\n"
        docker run --rm \
            -v "${OC_RELEASE_DIR}:/var/www/html/apps/sciencemesh" \
            --workdir /var/www/html/apps/sciencemesh \
            "${COMPOSER_IMAGE}" \
            make composer || print_error "Failed to run 'composer' inside Docker."
    fi

    # Step 6: Tag the release using a Python script.
    if [ -x "${REPO_ROOT}/release/tag-release.py" ]; then
        printf "Tagging the release using the Python script...\n"
        "${REPO_ROOT}/release/tag-release.py" oc "${RELEASE_TAG}" "${OC_RELEASE_DIR}" || print_error "Failed to tag the release."
    else
        print_error "Tagging script not found or not executable at '${REPO_ROOT}/release/tag-release.py'."
    fi

    # Fetch all tags to ensure they are available.
    git fetch --tags || print_error "Failed to fetch tags from the repository."

    # Step 7: Get the latest Git tag from the repository.
    RELEASE_TAG=$(get_latest_git_tag "${OC_RELEASE_DIR}")
    RELEASE_NAME="ownCloud Sciencemesh Release ${RELEASE_TAG}"

    printf "Latest Git tag obtained: '%s'\n" "${RELEASE_TAG}"

    # Step 8: Set up the MariaDB container.
    docker run --detach --network=testnet \
        --name=maria1.docker \
        -e MARIADB_ROOT_PASSWORD="eilohtho9oTahsuongeeTh7reedahPo1Ohwi3aek" \
        "${MARIADB_IMAGE}" \
        --transaction-isolation=READ-COMMITTED \
        --binlog-format=ROW \
        --innodb-file-per-table=1 \
        --skip-innodb-read-only-compressed

    # Step 9: Set up the ownCloud container.
    docker run --detach --network=testnet \
        --name=oc-release.docker \
        -e HOST="oc1" \
        -e DBHOST="maria1.docker" \
        -e USER="einstein" \
        -e PASS="relativity" \
        -v "${REPO_ROOT}/temp/oc.sh:/oc-init.sh" \
        -v "${REPO_ROOT}/oc-sciencemesh-release:/var/www/html/apps/sciencemesh" \
        -v "${REPO_ROOT}/release/sciencemesh.key:/var/www/sciencemesh.key" \
        "${OC_IMAGE}"

    # Step 10: Adjust file permissions inside the container.
    docker exec --user root oc-release.docker bash -c \
        "chown www-data:www-data -R /var/www/html/apps/sciencemesh && \
         chown www-data:www-data /var/www/sciencemesh.key"

    # Step 11: Build and sign the Sciencemesh app inside the container.
    docker exec --user www-data oc-release.docker bash -c \
        "cd /var/www/html/apps/sciencemesh && \
         mkdir -p build/sciencemesh && \
         rm -rf build/sciencemesh/* && \
         cp -r appinfo css img js lib templates composer.* build/sciencemesh/ && \
         cd build/sciencemesh && \
         composer install && \
         cd /var/www/html && \
         ./occ integrity:sign-app \
         --privateKey=/var/www/sciencemesh.key \
         --certificate=apps/sciencemesh/sciencemesh.crt \
         --path=apps/sciencemesh/build/sciencemesh && \
         cd apps/sciencemesh/build && \
         tar -cf sciencemesh.tar sciencemesh"

    # Step 12: Compress and move the tarball.
    docker exec --user root oc-release.docker bash -c \
        "mkdir -p /var/www/html/apps/sciencemesh/release && \
         cd /var/www/html/apps/sciencemesh/release && \
         mv ../build/sciencemesh.tar . && \
         rm -f -- sciencemesh.tar.gz && \
         gzip sciencemesh.tar"

    # Step 13: Build and compress the application tarball inside Docker.
    printf "Building and compressing the application tarball inside Docker...\n"
    # Ensure the container is running
    if ! docker ps --format '{{.Names}}' | grep -q "^oc-release.docker$"; then
        print_error "Docker container 'oc-release.docker' is not running."
    fi

    docker exec --user root oc-release.docker bash -c \
        "cd /var/www/html/apps/sciencemesh/release && \
         mv ../build/sciencemesh.tar . && \
         rm -f -- sciencemesh.tar.gz && \
         gzip sciencemesh.tar" || print_error "Failed to build and compress the tarball."

    # Step 14: Verify the tarball exists.
    if [ ! -f "${TARBALL_PATH}" ]; then
        print_error "Tarball not found at '${TARBALL_PATH}'."
    fi

    # Step 15: Upload the tarball to GitHub as a release.
    create_github_release "${GITHUB_REPO}" "${RELEASE_TAG}" "${RELEASE_NAME}" "${TARBALL_PATH}"

    # Step 16: Clean up resources.
    run_cleanup
}

# -----------------------------------------------------------------------------------
# Execute the main function
# -----------------------------------------------------------------------------------
main "$@"
