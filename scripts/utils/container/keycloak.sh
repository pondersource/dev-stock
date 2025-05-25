#!/usr/bin/env bash

function create_idp_keycloak() {
    local image="${1}"
    local tag="${2}"

    run_quietly_if_ci echo "Creating Keycloak instance: idp"

    # Start Reva container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="idp.docker" \
        -e KC_BOOTSTRAP_ADMIN_USERNAME="admin" \
        -e KC_BOOTSTRAP_ADMIN_PASSWORD="admin" \
        -e KC_HOSTNAME="idp.docker" \
        -e KC_HTTPS_CERTIFICATE_FILE="/tls/idp.crt" \
        -e KC_HTTPS_CERTIFICATE_KEY_FILE="/tls/idp.key" \
        -e KC_HTTPS_PORT="443" \
        "${image}:${tag}" || error_exit "Failed to start Keycloak container for idp."

    # Keycloak has long warm up time
    sleep 15
}

# ------------------------------------------------------------------------------
# Function: delete_idp_keycloak
# Purpose : Stop and remove singleton Keycloak container
#
# Example:
#   delete_idp_keycloak
#
# Notes:
#   • Anonymous volumes are removed automatically with `docker rm -v`.
#   • Named volumes are detected via `docker inspect` and removed explicitly.
#   • Bind-mounts on the host are intentionally not touched.
# ------------------------------------------------------------------------------
delete_idp_keycloak() {
    local idp="idp.docker"

    run_quietly_if_ci echo "Deleting Keycloak instance …"

    # Stop containers if they exist (ignore errors if already gone/stopped)
    run_quietly_if_ci docker stop "${idp}" || true

    # Collect any **named** volumes attached to either container
    local volumes
    volumes="$(
        {
            docker inspect -f '{{ range .Mounts }}{{ if eq .Type "volume" }}{{ .Name }} {{ end }}{{ end }}' "${idp}" 2>/dev/null || true
        } | xargs -r echo
    )"

    # Remove containers (+ anonymous volumes with -v)
    run_quietly_if_ci docker rm -fv "${idp}" || true

    # Remove any named volumes we discovered
    if [[ -n "${volumes}" ]]; then
        run_quietly_if_ci echo "Removing volumes: ${volumes}"
        run_quietly_if_ci docker volume rm -f ${volumes} || true
    fi

    run_quietly_if_ci echo "Keycloak removed."
}
