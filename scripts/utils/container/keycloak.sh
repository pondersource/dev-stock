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
