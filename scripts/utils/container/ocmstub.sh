#!/usr/bin/env bash

# Create an OCMStub container
create_ocmstub() {
    local number="${1}"
    local image="${2}"
    local tag="${3}"

    run_quietly_if_ci echo "Creating EFSS instance: ocmstub ${number}"

    # Start EFSS container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="ocmstub${number}.docker" \
        -e HOST="ocmstub${number}.docker" \
        -v "${TLS_CERT_DIR}:/certificates" \
        -v "${TLS_CA_DIR}:/certificate-authority" \
        "${image}:${tag}" || error_exit "Failed to start EFSS container for ocmstub ${number}."

    # Wait for EFSS port to open
    run_quietly_if_ci wait_for_port "ocmstub${number}.docker" 443
}
