#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Docker Build Script for PonderSource Development Images
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# -----------------------------------------------------------------------------------

# Description:
#   This script automates the building of various Docker images used in the PonderSource
#   development environment. It supports enabling Docker BuildKit and incorporates a
#   cache-busting mechanism for pulling fresh source code during builds.
#
# Requirements:
#   - Docker must be installed and accessible.
#   - The script should be placed in a directory that has a 'dockerfiles' subdirectory,
#     which contains the respective Dockerfiles for each image.
#
# Usage:
#   ./all.sh [USE_BUILDKIT]
#
# Arguments:
#   USE_BUILDKIT (optional): Set to 0 or 1 to disable or enable BuildKit.
#                            Defaults to 1 (enabled).
#
# Notes:
#   - The script changes the working directory to the parent directory of the script's
#     location. Ensure that 'dockerfiles' is accessible from there.
#   - CACHEBUST is used to force Docker to re-pull or rebuild layers as needed.
#   - Each build is attempted, and if any image fails to build, the script moves on
#     to the next image after printing an error message.
#
# Example:
#   ./all.sh            # Enable BuildKit (default)
#   ./all.sh 0          # Disable BuildKit
# -----------------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status,
# a variable is used but not defined, or a command in a pipeline fails
set -eo pipefail

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
    cd "$script_dir/.." || error_exit "Failed to change directory to script root."
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
# Function: print_error
# Purpose: Print an error message to stderr.
# Arguments:
#   $1 - The error message to display.
# -----------------------------------------------------------------------------------
print_error() {
    local message="${1}"
    printf "Error: %s\n" "$message" >&2
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
# Docker Build Functions
# -----------------------------------------------------------------------------------
# A helper function to streamline the Docker build process.
# Arguments:
#   1. Dockerfile path (relative to the current working directory)
#   2. Image name
#   3. Tags (space-separated string of tags)
#   4. Cache Bust to force rebuild.
#   5. Additional build arguments (optional)
build_docker_image() {
    local dockerfile="${1}"
    local image_name="${2}"
    local tags="${3}"
    local cache_bust="${4}"
    local build_args="${5}"

    # Validate that the Dockerfile exists
    if [[ ! -f "./dockerfiles/${dockerfile}" ]]; then
        print_error "Dockerfile not found at '${dockerfile}'. Skipping build of ${image_name}."
        return 1
    fi

    echo "Building image: ${image_name} from Dockerfile: ${dockerfile}"
    if ! docker build \
        --build-arg CACHEBUST="${cache_bust}" ${build_args} \
        --file "./dockerfiles/${dockerfile}" \
        $(for tag in ${tags}; do printf -- "--tag ${image_name}:%s " "${tag}"; done) \
        .; then
        print_error "Failed to build image ${image_name}."
        return 1
    fi

    echo "Successfully built: ${image_name}"
    echo
}

# -----------------------------------------------------------------------------------
# Function: build_nextcloud_app_image
# Purpose: Build a Nextcloud image with a specific app installed
# Arguments:
#   1. app_name - Name of the app (e.g., "sciencemesh")
#   2. install_method - Installation method ("git" or "tarball")
#   3. source - Git repository URL or tarball URL
#   4. app_branch - Git branch (default: "main", ignored for tarball)
#   5. app_build_cmd - Build command if required (optional)
#   6. init_script - Path to initialization script (optional)
#   7. nextcloud_version - Nextcloud version to use as base
#   8. image_tag_suffix - Suffix for the image tag (optional)
#   9. cache_bust - Cache bust value (optional, defaults to "DEFAULT")
# -----------------------------------------------------------------------------------
build_nextcloud_app_image() {
    local app_name="${1}"
    local install_method="${2:-git}"
    local source="${3}"
    local app_branch="${4:-master}"
    local app_build_cmd="${5:-}"
    local init_script="${6:-}"
    local nextcloud_version="${7}"
    local image_tag_suffix="${8:-${app_name}}"
    local cache_bust="${9:-DEFAULT}"
    
    local build_args=""
    
    # Construct build arguments string
    build_args="--build-arg NEXTCLOUD_VERSION=${nextcloud_version}"
    build_args="${build_args} --build-arg APP_NAME=${app_name}"
    build_args="${build_args} --build-arg INSTALL_METHOD=${install_method}"
    build_args="${build_args} --build-arg CACHEBUST=${cache_bust}"
    
    # Add source-specific arguments based on installation method
    if [[ "${install_method}" == "git" ]]; then
        build_args="${build_args} --build-arg APP_REPO=${source}"
        build_args="${build_args} --build-arg APP_BRANCH=${app_branch}"
    else
        build_args="${build_args} --build-arg TARBALL_URL=${source}"
    fi
    
    # Add optional build arguments if provided
    [[ -n "${app_build_cmd}" ]] && build_args="${build_args} --build-arg APP_BUILD_CMD=${app_build_cmd}"
    [[ -n "${init_script}" ]] && build_args="${build_args} --build-arg INIT_SCRIPT=${init_script}"
    
    # Construct the image tag
    local image_tag="${nextcloud_version}-${image_tag_suffix}"
    
    echo "Building Nextcloud app image: ${app_name} (${image_tag}) using ${install_method} method"
    if ! docker build \
        ${build_args} \
        --file "./dockerfiles/nextcloud-app.Dockerfile" \
        --tag "pondersource/nextcloud:${image_tag}" \
        .; then
        print_error "Failed to build Nextcloud app image: ${app_name}"
        return 1
    fi
    
    echo "Successfully built Nextcloud app image: ${app_name}"
    echo
}

# -----------------------------------------------------------------------------------
# Function: build_owncloud_app_image
# Purpose: Build an ownCloud image with a specific app installed
# Arguments:
#   1. app_name - Name of the app (e.g., "sciencemesh")
#   2. install_method - Installation method ("git" or "tarball")
#   3. source - Git repository URL or tarball URL
#   4. app_branch - Git branch (default: "main", ignored for tarball)
#   5. app_build_cmd - Build command if required (optional)
#   6. init_script - Path to initialization script (optional)
#   7. owncloud_version - ownCloud version to use as base
#   8. image_tag_suffix - Suffix for the image tag (optional)
#   9. cache_bust - Cache bust value (optional, defaults to "DEFAULT")
# -----------------------------------------------------------------------------------
build_owncloud_app_image() {
    local app_name="${1}"
    local install_method="${2:-git}"
    local source="${3}"
    local app_branch="${4:-master}"
    local app_build_cmd="${5:-}"
    local init_script="${6:-}"
    local owncloud_version="${7}"
    local image_tag_suffix="${8:-${app_name}}"
    local cache_bust="${9:-DEFAULT}"
    
    local build_args=""
    
    # Construct build arguments string
    build_args="--build-arg OWNCLOUD_VERSION=${owncloud_version}"
    build_args="${build_args} --build-arg APP_NAME=${app_name}"
    build_args="${build_args} --build-arg INSTALL_METHOD=${install_method}"
    build_args="${build_args} --build-arg CACHEBUST=${cache_bust}"
    
    # Add source-specific arguments based on installation method
    if [[ "${install_method}" == "git" ]]; then
        build_args="${build_args} --build-arg APP_REPO=${source}"
        build_args="${build_args} --build-arg APP_BRANCH=${app_branch}"
    else
        build_args="${build_args} --build-arg TARBALL_URL=${source}"
    fi
    
    # Add optional build arguments if provided
    [[ -n "${app_build_cmd}" ]] && build_args="${build_args} --build-arg APP_BUILD_CMD=${app_build_cmd}"
    [[ -n "${init_script}" ]] && build_args="${build_args} --build-arg INIT_SCRIPT=${init_script}"
    
    # Construct the image tag
    local image_tag="${owncloud_version}-${image_tag_suffix}"
    
    echo "Building ownCloud app image: ${app_name} (${image_tag}) using ${install_method} method"
    if ! docker build \
        ${build_args} \
        --file "./dockerfiles/owncloud-app.Dockerfile" \
        --tag "pondersource/owncloud:${image_tag}" \
        .; then
        print_error "Failed to build ownCloud app image: ${app_name}"
        return 1
    fi
    
    echo "Successfully built ownCloud app image: ${app_name}"
    echo
}

# -----------------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------------
main() {
    # Initialize environment and source utilities
    initialize_environment

    # Enable Docker BuildKit (Optional)
    USE_BUILDKIT=${1:-1}
    export DOCKER_BUILDKIT="${USE_BUILDKIT}"

    # export BUILDKIT_PROGRESS=plain

    # -----------------------------------------------------------------------------------
    # Build Images
    # -----------------------------------------------------------------------------------
    # OCM Stub
    build_docker_image ocmstub.Dockerfile           pondersource/ocmstub            "v1.0.0 latest"     DEFAULT

    # Revad
    build_docker_image revad.Dockerfile             pondersource/revad               "latest"           DEFAULT

    # Nextcloud Base
    build_docker_image nextcloud-base.Dockerfile    pondersource/nextcloud-base     "latest"           DEFAULT

    # Nextcloud Versions
    # The first element in this array is considered the "latest".
    nextcloud_versions=("v30.0.2" "v29.0.10" "v28.0.14" "v27.1.11")

    # Define contacts app versions for each Nextcloud version
    declare -A contacts_versions=(
        ["v30.0.2"]="v6.1.3"
        ["v29.0.10"]="v6.0.2"
        ["v28.0.14"]="v5.5.3"
        ["v27.1.11"]="v5.5.3"
    )

    # shellcheck disable=SC2207
    # TODO @MahdiBaghbani: Decide that if we want to do this automatically or manually. 
    # Automatically get latest images
    # nextcloud_versions=($(curl -s https://api.github.com/repos/nextcloud/server/releases?per_page=100 | \
    #     jq -r '.[].tag_name' | \
    #     grep -E '^v(2[7-9]|[3-9][0-9])\.[0-9]+\.[0-9]+$' | \
    #     sort --version-sort -r | \ awk -F '.' '!seen[$1]++'))

    # Iterate over the array of versions
    for i in "${!nextcloud_versions[@]}"; do
        version="${nextcloud_versions[i]}"
        tags="${version}"
        # If this is the first element (index 0), also add the "latest" tag
        [[ "$i" -eq 0 ]] && tags="${version} latest"

        build_docker_image \
            nextcloud.Dockerfile \
            pondersource/nextcloud \
            "${tags}" \
            DEFAULT \
            "--build-arg NEXTCLOUD_BRANCH=${version}"
    done
    
    # Build Nextcloud App Variants
    # ScienceMesh using git
    build_nextcloud_app_image \
        "sciencemesh" \
        "git" \
        "https://github.com/sciencemesh/nc-sciencemesh" \
        "nextcloud" \
        "make" \
        "./scripts/init/nextcloud-sciencemesh.sh" \
        "v27.1.11" \
        "sm" \
        DEFAULT

    # Get latest stable contacts app release
    echo "Fetching latest stable contacts app release..."
    CONTACTS_RELEASE=$(curl -s https://api.github.com/repos/nextcloud-releases/contacts/releases/latest)
    CONTACTS_VERSION=$(echo "${CONTACTS_RELEASE}" | grep -oP '"tag_name": "\K[^"]+')
    CONTACTS_FILENAME=$(echo "${CONTACTS_RELEASE}" | grep -oP '"name": "contacts-[^"]+\.tar\.gz"' | grep -oP 'contacts-[^"]+\.tar\.gz')
    if [ -z "${CONTACTS_VERSION}" ] || [ -z "${CONTACTS_FILENAME}" ]; then
        print_error "Failed to fetch latest contacts app version or filename"
        return 1
    fi
    echo "Latest stable contacts app version: ${CONTACTS_VERSION}"
    echo "Contacts app filename: ${CONTACTS_FILENAME}"

    # Build contacts app variant for each supported Nextcloud version
    for version in "${nextcloud_versions[@]}"; do
        echo "Building contacts app for Nextcloud ${version}..."
        
        # Get the corresponding contacts app version
        contacts_version="${contacts_versions[${version}]}"
        if [ -z "${contacts_version}" ]; then
            print_error "No compatible contacts app version defined for Nextcloud ${version}"
            continue
        fi

        # Construct the filename and URL
        contacts_filename="contacts-${contacts_version}.tar.gz"
        contacts_url="https://github.com/nextcloud-releases/contacts/releases/download/${contacts_version}/${contacts_filename}"

        echo "Using contacts app version: ${contacts_version}"
        echo "Contacts app filename: ${contacts_filename}"
        echo "Download URL: ${contacts_url}"

        build_nextcloud_app_image \
            "contacts" \
            "tarball" \
            "${contacts_url}" \
            "" \
            "" \
            "./scripts/init/nextcloud-contacts.sh" \
            "${version}" \
            "contacts" \
            DEFAULT
    done

    # ownCloud Base
    build_docker_image owncloud-base.Dockerfile     pondersource/owncloud-base     "latest"           DEFAULT

    # ownCloud Versions
    # The first element in this array is considered the "latest".
    owncloud_versions=("v10.15.0")

    # Iterate over the array of versions
    for i in "${!owncloud_versions[@]}"; do
        version="${owncloud_versions[i]}"
        tags="${version}"
        [[ "$i" -eq 0 ]] && tags="${version} latest"

        build_docker_image \
            owncloud.Dockerfile \
            pondersource/owncloud \
            "${tags}" \
            DEFAULT \
            "--build-arg OWNCLOUD_BRANCH=${version}"
    done

    # Build ownCloud App Variants
    # ScienceMesh using git
    build_owncloud_app_image \
        "sciencemesh" \
        "git" \
        "https://github.com/sciencemesh/nc-sciencemesh" \
        "owncloud" \
        "make" \
        "./scripts/init/owncloud-sciencemesh.sh" \
        "v10.15.0" \
        "sm" \
        DEFAULT

    echo "All builds attempted."
    echo "Check the above output for any build failures or errors."
}

# -----------------------------------------------------------------------------------
# Execute the main function and pass all script arguments.
# -----------------------------------------------------------------------------------
main "$@"
