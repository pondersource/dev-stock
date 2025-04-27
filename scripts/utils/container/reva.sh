#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Function: create_reva
# Purpose: Create a Reva container for the specified EFSS platform and instance.
# Arguments:
#   $1 - EFSS platform (e.g., nextcloud).
#   $2 - Instance number.
#   $3 - Reva image.
#   $4 - Reva tag.
#   $5 - Disabled configs (optional, space-separated list of config files to disable).
# -----------------------------------------------------------------------------------
create_reva() {
    local platform="${1}"
    local number="${2}"
    local image="${3}"
    local tag="${4}"
    local disabled_configs="${5:-}"

    run_quietly_if_ci echo "Creating Reva instance: ${platform} ${number}"

    # Start Reva container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="reva${platform}${number}.docker" \
        -e HOST="reva${platform}${number}" \
        -e DISABLED_CONFIGS="${disabled_configs}" \
        "${image}:${tag}" || error_exit "Failed to start Reva container for ${platform} ${number}."

    # Wait for Reva port to open (assuming Reva uses port 19000)
    wait_for_port "reva${platform}${number}.docker" 19000
}

delete_reva() {
    local platform="${1}"
    local number="${2}"
    local reva="reva${platform}${number}.docker"

    run_quietly_if_ci echo "Deleting reva${platform} instance ${number} …"

    # Stop containers if they exist (ignore errors if already gone/stopped)
    run_quietly_if_ci docker stop "${reva}" || true

    # Collect any **named** volumes attached to either container
    local volumes
    volumes="$(
        {
            docker inspect -f '{{ range .Mounts }}{{ if eq .Type "volume" }}{{ .Name }} {{ end }}{{ end }}' "${reva}" 2>/dev/null || true
        } | xargs -r echo
    )"

    # Remove containers (+ anonymous volumes with -v)
    run_quietly_if_ci docker rm -fv "${reva}" || true

    # Remove any named volumes we discovered
    if [[ -n "${volumes}" ]]; then
        run_quietly_if_ci echo "Removing volumes: ${volumes}"
        run_quietly_if_ci docker volume rm -f ${volumes} || true
    fi

    run_quietly_if_ci echo "reva${platform} instance ${number} removed."
}
