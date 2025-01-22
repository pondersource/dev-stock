#!/usr/bin/env bash

# Create Cypress container for development mode
create_cypress_dev() {
    run_quietly_if_ci echo "Starting Cypress container..."

    run_docker_container --detach \
        --network="${DOCKER_NETWORK}" \
        --name="cypress.docker" \
        -e DISPLAY="vnc-server:0.0" \
        -v "${ENV_ROOT}/cypress/ocm-test-suite:/ocm" \
        -v "${X11_SOCKET}:/tmp/.X11-unix" \
        -w /ocm \
        --entrypoint cypress \
        "${CYPRESS_REPO}:${CYPRESS_TAG}" \
        open --project . || error_exit "Failed to start Cypress."
}

# Create Cypress container for CI mode
create_cypress_ci() {
    local cypress_spec="${1}"

    if [[ -z "$cypress_spec" ]]; then
        error_exit "No Cypress spec provided. Usage: create_cypress_ci <spec-path>"
    fi

    run_quietly_if_ci echo "Running Cypress tests using spec: $cypress_spec"

    docker run --network="${DOCKER_NETWORK}" \
        --name="cypress.docker" \
        -v "${ENV_ROOT}/cypress/ocm-test-suite:/ocm" \
        -w /ocm \
        "${CYPRESS_REPO}:${CYPRESS_TAG}" \
        cypress run \
        --browser "${BROWSER_PLATFORM}" \
        --spec "${cypress_spec}" ||
        error_exit "Cypress tests failed."
}
