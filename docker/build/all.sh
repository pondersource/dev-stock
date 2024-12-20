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
# Docker Build Function
# -----------------------------------------------------------------------------------
# A helper function to streamline the Docker build process.
# Arguments:
#   1. Dockerfile path (relative to the current working directory)
#   2. Image name
#   3. Tags (space-separated string of tags)
#   4. Cache Bust to force rebuild.
#   5. Additional build arguments (optional)
#
# The function:
#   - Validates the Dockerfile existence.
#   - Prints a build message and runs 'docker build' with specified args.
#   - Applies a CACHEBUST build-arg by default to help with cache invalidation.
#   - Prints success or error messages accordingly.
build_docker_image() {
    local dockerfile="${1}"
    local image_name="${2}"
    local tags="${3}"
    local cache_bust="${4}"
    local build_args="${5}"

    # Validate that the Dockerfile exists
    if [[ ! -f "./dockerfiles/${dockerfile}" ]]; then
        printf "Error: Dockerfile not found at '%s'. Skipping build of %s.\n" "${dockerfile}" "${image_name}" >&2
        return 1
    fi

    printf "Building image: %s from Dockerfile: %s\n" "${image_name}" "${dockerfile}"
    if ! docker build \
        --build-arg CACHEBUST="${cache_bust}" ${build_args} \
        --file "./dockerfiles/${dockerfile}" \
        $(for tag in ${tags}; do printf -- "--tag ${image_name}:%s " "${tag}"; done) \
        .; then
        printf "Error: Failed to build image %s.\n" "${image_name}" >&2
        return 1
    fi

    printf "Successfully built: %s\n\n" "${image_name}"
}

# -----------------------------------------------------------------------------------
# Function: main
# Purpose: Main function to manage the flow of the script.
# -----------------------------------------------------------------------------------
main() {
    # Initialize environment.
    initialize_environment

    # -----------------------------------------------------------------------------------
    # Enable Docker BuildKit (Optional)
    # -----------------------------------------------------------------------------------
    # Allow enabling or disabling BuildKit via the first script argument.
    # Default: BuildKit enabled (value 1).
    USE_BUILDKIT=${1:-1}
    export DOCKER_BUILDKIT="${USE_BUILDKIT}"

    # export BUILDKIT_PROGRESS=plain

    # -----------------------------------------------------------------------------------
    # Build Images
    # -----------------------------------------------------------------------------------
    # Below is a list of images to build along with their Dockerfiles and tags.
    # Modify these as necessary to fit your environment and requirements.

    # OCM Stub
    build_docker_image ocmstub.Dockerfile           pondersource/ocmstub            "v1.0.0 latest"     DEFAULT

    # Revad
    build_docker_image revad.Dockerfile             pondersource/revad               "latest"           DEFAULT

    # PHP Base
    # build_docker_image php-base.Dockerfile          pondersource/php-base           "latest"           DEFAULT

    # Nextcloud Base
    build_docker_image nextcloud-base.Dockerfile    pondersource/nextcloud-base     "latest"           DEFAULT

    # Nextcloud Versions
    # The first element in this array is considered the "latest".
    nextcloud_versions=("v30.0.2" "v29.0.10" "v28.0.14" "v27.1.11")

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

        # If this is the first element (index 0), also add the "latest" tag
        if [[ "$i" -eq 0 ]]; then
            tags="${version} latest"
        else
            tags="${version}"
        fi

        # Build the Docker image with the determined tags and build-arg
        build_docker_image \
            nextcloud.Dockerfile \
            pondersource/nextcloud \
            "${tags}" \
            DEFAULT \
            "--build-arg NEXTCLOUD_BRANCH=${version}"
    done
    
    # nextcloud Variants
    # build_docker_image nextcloud-solid.Dockerfile               pondersource/nextcloud-solid              "latest"    DEFAULT
    # build_docker_image nextcloud-sciencemesh.Dockerfile         pondersource/nextcloud-sciencemesh        "latest"    DEFAULT

    # ownCloud Base
    build_docker_image owncloud-base.Dockerfile                 pondersource/owncloud-base                "latest"    DEFAULT

    # ownCloud Versions
    # The first element in this array is considered the "latest".
    owncloud_versions=("v10.15.0")

    # Iterate over the array of versions
    for i in "${!owncloud_versions[@]}"; do
        version="${owncloud_versions[i]}"

        # If this is the first element (index 0), also add the "latest" tag
        if [[ "$i" -eq 0 ]]; then
            tags="${version} latest"
        else
            tags="${version}"
        fi

        # Build the Docker image with the determined tags and build-arg
        build_docker_image \
            owncloud.Dockerfile \
            pondersource/owncloud \
            "${tags}" \
            DEFAULT \
            "--build-arg OWNCLOUD_BRANCH=${version}"
    done

    # OwnCloud Variants
    # build_docker_image owncloud-sciencemesh.Dockerfile          pondersource/owncloud-sciencemesh         "latest"    DEFAULT
    # build_docker_image owncloud-surf-trashbin.Dockerfile        pondersource/owncloud-surf-trashbin       "latest"    DEFAULT
    # build_docker_image owncloud-token-based-access.Dockerfile   pondersource/owncloud-token-based-access  "latest"    DEFAULT
    # build_docker_image owncloud-opencloudmesh.Dockerfile        pondersource/owncloud-opencloudmesh       "latest"    DEFAULT
    # build_docker_image owncloud-federatedgroups.Dockerfile      pondersource/owncloud-federatedgroups     "latest"    DEFAULT
    # build_docker_image owncloud-ocm-test-suite.Dockerfile       pondersource/owncloud-ocm-test-suite      "latest"    DEFAULT

    # -----------------------------------------------------------------------------------
    # Completion Message
    # -----------------------------------------------------------------------------------
    printf "All builds attempted.\n"
    printf "Check the above output for any build failures or errors.\n"
}

# -----------------------------------------------------------------------------------
# Execute the main function and pass all script arguments.
# -----------------------------------------------------------------------------------
main "$@"
