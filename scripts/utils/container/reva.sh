#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Function: create_reva
# Purpose: Create a Reva container for the specified EFSS platform and instance.
# Arguments:
#   $1 - EFSS platform (e.g., nextcloud).
#   $2 - Instance number.
#   $3 - Reva image.
#   $4 - Reva tag.
# -----------------------------------------------------------------------------------
create_reva() {
    local platform="${1}"
    local number="${2}"
    local image="${3}"
    local tag="${4}"

    run_quietly_if_ci echo "Creating Reva instance: ${platform} ${number}"

    # Start Reva container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="reva${platform}${number}.docker" \
        -e HOST="reva${platform}${number}" \
        "${image}:${tag}" || error_exit "Failed to start Reva container for ${platform} ${number}."

    # Wait for Reva port to open (assuming Reva uses port 19000)
    wait_for_port "reva${platform}${number}.docker" 19000
}
