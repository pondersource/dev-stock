#!/usr/bin/env bash

# Run a Docker container with provided arguments
run_docker_container() {
    run_quietly_if_ci docker run "$@" || error_exit "Failed to start Docker container: $*"
}

# Prepare Docker environment (network, cleanup)
prepare_environment() {
    # Prepare temporary directories and copy necessary files
    remove_directory "${TEMP_DIR}"
    mkdir -p "${TEMP_DIR}"

    # Skip cleanup when CI_ENVIRONMENT=true or NO_CLEANING=true
    if [[ "${CI_ENVIRONMENT}" != "true" && "${NO_CLEANING}" != "true" ]]; then
        # Clean up previous resources (if the cleanup script is available)
        # WARNING: this is probably going to make real mess of your system and 
        # cause tremendous pain on ci jobs based on docker, since it will NUKE
        # everything related to docker and WIPE it clean.
        # I (@MahdiBaghbani) should delete this, but the use of it is really needed on gitpod,
        # or in isolated dev envs, so there are env variables to disable this functionality.
        if [ -x "${ENV_ROOT}/scripts/clean.sh" ]; then
            "${ENV_ROOT}/scripts/clean.sh" "no"
        else
            print_error "Cleanup script not found or not executable at '${ENV_ROOT}/scripts/clean.sh'. Continuing without cleanup."
        fi
    else
        run_quietly_if_ci echo "Skipping cleanup because CI_ENVIRONMENT or NO_CLEANING is set to true."
    fi

    # Ensure Docker network exists
    if ! docker network inspect "${DOCKER_NETWORK}" >/dev/null 2>&1; then
        docker network create "${DOCKER_NETWORK}" >/dev/null 2>&1 ||
            error_exit "Failed to create Docker network '${DOCKER_NETWORK}'."
    fi
}
