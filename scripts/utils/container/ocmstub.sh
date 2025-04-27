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
        -e HOST="ocmstub${number}" \
        -v "${TLS_CERT_DIR}:/certificates" \
        -v "${TLS_CA_DIR}:/certificate-authority" \
        "${image}:${tag}" || error_exit "Failed to start EFSS container for ocmstub ${number}."

    # Wait for EFSS port to open
    run_quietly_if_ci wait_for_port "ocmstub${number}.docker" 443
}

delete_ocmstub() {
    local number="${1}"
    local os="ocmstub${number}.docker"

    run_quietly_if_ci echo "Deleting OcmStub instance ${number} …"

    # Stop containers if they exist (ignore errors if already gone/stopped)
    run_quietly_if_ci docker stop "${os}" || true

    # Collect any **named** volumes attached to either container
    local volumes
    volumes="$(
        {
            docker inspect -f '{{ range .Mounts }}{{ if eq .Type "volume" }}{{ .Name }} {{ end }}{{ end }}' "${os}" 2>/dev/null || true
        } | xargs -r echo
    )"

    # Remove containers (+ anonymous volumes with -v)
    run_quietly_if_ci docker rm -fv "${os}" || true

    # Remove any named volumes we discovered
    if [[ -n "${volumes}" ]]; then
        run_quietly_if_ci echo "Removing volumes: ${volumes}"
        run_quietly_if_ci docker volume rm -f ${volumes} || true
    fi

    run_quietly_if_ci echo "OcmStub instance ${number} removed."
}
