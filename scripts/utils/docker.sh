#!/usr/bin/env bash

# Run a Docker container with provided arguments
run_docker_container() {
    run_quietly_if_ci docker run "$@" || error_exit "Failed to start Docker container: $*"
}

# Prepare Docker environment (network, cleanup)
prepare_environment() {
    # Prepare temporary directories and copy necessary files
    remove_directory "${ENV_ROOT}/${TEMP_DIR}" && mkdir -p "${ENV_ROOT}/${TEMP_DIR}"

    # Clean up previous resources (if the cleanup script is available)
    if [ -x "${ENV_ROOT}/scripts/clean.sh" ]; then
        "${ENV_ROOT}/scripts/clean.sh" "no"
    else
        print_error "Cleanup script not found or not executable at '${ENV_ROOT}/scripts/clean.sh'. Continuing without cleanup."
    fi

    # Ensure Docker network exists
    if ! docker network inspect "${DOCKER_NETWORK}" >/dev/null 2>&1; then
        docker network create "${DOCKER_NETWORK}" >/dev/null 2>&1 ||
            error_exit "Failed to create Docker network '${DOCKER_NETWORK}'."
    fi
}
