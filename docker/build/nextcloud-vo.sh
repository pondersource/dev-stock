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
#   6. Build context path (optional, defaults to '.')
build_docker_image() {
    local dockerfile="${1}"
    local image_name="${2}"
    local tags="${3}"
    local cache_bust="${4}"
    local build_args="${5:-}"
    local context_path="${6:-.}"

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
        "${context_path}"; then
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
    # Build Nextcloud Image with VO federation features
    repo="https://github.com/publicplan/nextcloud-server"
    version="v31.0.0beta5-1278-g28adcc3d33a"

    build_docker_image \
        nextcloud.Dockerfile \
        pondersource/nextcloud \
        "${version}" \
        DEFAULT \
        "--build-arg NEXTCLOUD_REPO=${repo} \
        --build-arg NEXTCLOUD_BRANCH=${version}"
    
    # Build Nextcloud VO Federation App Image using git
    app_repo="https://github.com/nextcloud/vo_federation"
    app_version="v0.5.0"

    build_nextcloud_app_image \
        "vo_federation" \
        "git" \
        "${app_repo}" \
        "${app_version}" \
        "" \
        "./scripts/init/nextcloud-vo_federation.sh" \
        "${version}" \
        "vo-${app_version}" \
        DEFAULT

    echo "All builds attempted."
    echo "Check the above output for any build failures or errors."
}

# -----------------------------------------------------------------------------------
# Execute the main function and pass all script arguments.
# -----------------------------------------------------------------------------------
main "$@"
