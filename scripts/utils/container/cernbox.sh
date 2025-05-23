#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Function: create_cernbox
# Purpose : Spin up a matched pair of CERNBox services (Reva + Nginx) that belong
#           to the same logical instance number.
# Arguments:
#   $1 - Instance number.
#   $2 - Nginx image.
#   $3 - Nginx tag.
#   $4 - Reva image.
#   $5 - Reva tag.
#   $6 - Disabled Reva configs (optional, space-separated list).
# -----------------------------------------------------------------------------------
create_cernbox() {
    local number="${1}"
    local nginx_image="${2}"
    local nginx_tag="${3}"
    local reva_image="${4}"
    local reva_tag="${5}"
    local reva_disabled_configs="${6:-}"

    create_cernbox_reva  "${number}" "${reva_image}"  "${reva_tag}"  "${reva_disabled_configs}"
    create_cernbox_nginx "${number}" "${nginx_image}" "${nginx_tag}"
}

# -----------------------------------------------------------------------------------
# Function: create_cernbox_nginx
# Purpose : Launch the Nginx front-end container for a CERNBox instance.
# Arguments:
#   $1 - Instance number.
#   $2 - Nginx image.
#   $3 - Nginx tag.
# -----------------------------------------------------------------------------------
create_cernbox_nginx() {
    local number="${1}"
    local image="${2}"
    local tag="${3}"

    run_quietly_if_ci echo "Creating CERNBox Nginx instance: cernbox ${number}"

    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="cernbox${number}.docker" \
        -e HOST="cernbox${number}" \
        -e REVAD="revacernbox${number}.docker" \
        -e CERNBOX="cernbox${number}.docker" \
        "${image}:${tag}" \
        || error_exit "Failed to start Nginx container for cernbox ${number}."
}

# -----------------------------------------------------------------------------------
# Function: create_cernbox_reva
# Purpose : Launch the Reva back-end container for a CERNBox instance.
# Arguments:
#   $1 - Instance number.
#   $2 - Reva image.
#   $3 - Reva tag.
#   $4 - Disabled configs (optional, space-separated list of config files to disable).
# -----------------------------------------------------------------------------------
create_cernbox_reva() {
    local number="${1}"
    local image="${2}"
    local tag="${3}"
    local disabled_configs="${4:-}"

    run_quietly_if_ci echo "Creating CERNBox Reva instance: revacernbox ${number}"

    # Start Reva container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="revacernbox${number}.docker" \
        -e HOST="revacernbox${number}" \
        -e DISABLED_CONFIGS="${disabled_configs}" \
        "${image}:${tag}" || error_exit "Failed to start Reva container for revacernbox ${number}."

    # Wait for Reva port to open (assuming Reva uses port 19000)
    wait_for_port "revacernbox${number}.docker" 19000
}

# -----------------------------------------------------------------------------------
# Function: delete_cernbox_nginx
# Purpose : Cleanly stop and remove the Nginx container for a CERNBox instance,
#           deleting any named volumes that belong exclusively to it.
# Arguments:
#   $1 - Instance number.
# -----------------------------------------------------------------------------------
delete_cernbox_nginx() {
    local number="${1}"
    local nginx="cernbox${number}.docker"

    run_quietly_if_ci echo "Deleting cernbox instance ${number} (Nginx) …"

    # Stop (ignore errors if already stopped)
    run_quietly_if_ci docker stop "${nginx}" || true

    # Gather named volumes
    local volumes
    volumes="$(
        docker inspect -f '{{ range .Mounts }}{{ if eq .Type "volume" }}{{ .Name }} {{ end }}{{ end }}' "${nginx}" 2>/dev/null || true
    )"

    # Remove container and anonymous volumes
    run_quietly_if_ci docker rm -fv "${nginx}" || true

    # Remove any named volumes
    if [[ -n "${volumes}" ]]; then
        run_quietly_if_ci echo "Removing volumes: ${volumes}"
        run_quietly_if_ci docker volume rm -f ${volumes} || true
    fi

    run_quietly_if_ci echo "cernbox instance ${number} (Nginx) removed."
}

# -----------------------------------------------------------------------------------
# Function: delete_cernbox_reva
# Purpose : Cleanly stop and remove the Reva container for a CERNBox instance,
#           deleting any named volumes that belong exclusively to it.
# Arguments:
#   $1 - Instance number.
# -----------------------------------------------------------------------------------
delete_cernbox_reva() {
    local number="${1}"
    local reva="revacernbox${number}.docker"

    run_quietly_if_ci echo "Deleting revacernbox instance ${number} …"

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

    run_quietly_if_ci echo "revacernbox instance ${number} removed."
}

# -----------------------------------------------------------------------------------
# Function: delete_cernbox
# Purpose : Convenience helper that tears down both Reva and Nginx containers (and
#           their volumes) for a given CERNBox instance number.
# Arguments:
#   $1 - Instance number.
# -----------------------------------------------------------------------------------
delete_cernbox() {
    local number="${1}"

    delete_cernbox_nginx "${number}"
    delete_cernbox_reva  "${number}"
}
