#!/usr/bin/env bash

create_meshdir() {
    local image="${1}"
    local tag="${2}"

    # Start Mesh Directory
    run_quietly_if_ci echo "Starting Mesh Directory..."

    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="meshdir.docker" \
        -e HOST="meshdir" \
        "${image}:${tag}" || error_exit "Failed to start meshdir."

    # Wait for EFSS port to open
    run_quietly_if_ci wait_for_port "meshdir.docker" 443
}
