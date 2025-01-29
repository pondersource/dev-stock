#!/usr/bin/env bash

# Create Firefox container
create_firefox() {
    run_quietly_if_ci echo "Starting Firefox container..."

    run_docker_container --detach \
        --network="${DOCKER_NETWORK}" \
        --name="firefox" \
        -p 5800:5800 \
        --shm-size=2g \
        -e USER_ID="$(id -u)" \
        -e GROUP_ID="$(id -g)" \
        -e DARK_MODE=1 \
        -v "${ENV_ROOT}/docker/tls/browsers/firefox/cert9.db:/config/profile/cert9.db:rw" \
        -v "${ENV_ROOT}/docker/tls/browsers/firefox/cert_override.txt:/config/profile/cert_override.txt:rw" \
        "${FIREFOX_REPO}:${FIREFOX_TAG}" || error_exit "Failed to start Firefox."
}
