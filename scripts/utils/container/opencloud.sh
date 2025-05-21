#!/usr/bin/env bash

# Create an Opencloud container
create_opencloud() {
    local number="${1}"
    local image="${2}"
    local tag="${3}"

    run_quietly_if_ci echo "Creating EFSS instance: opencloud ${number}"

    # Launch on the primary network (traefik-net)
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="opencloud${number}.docker" \
        -e OC_LOG_LEVEL=info \
        -e OC_LOG_COLOR=true \
        -e OC_LOG_PRETTY=true \
        -e PROXY_HTTP_ADDR=0.0.0.0:443 \
        -e OC_URL="https://opencloud${number}.docker" \
        -e OC_INSECURE=true \
        -e PROXY_TRANSPORT_TLS_KEY="/dev-stock/certificates/opencloud${number}.key" \
        -e PROXY_TRANSPORT_TLS_CERT="/dev-stock/certificates/opencloud${number}.crt" \
        -e PROXY_ENABLE_BASIC_AUTH=true \
        -e IDM_ADMIN_PASSWORD=admin \
        -e IDM_CREATE_DEMO_USERS=true \
        -e OC_ENABLE_OCM=true \
        -e OC_ADD_RUN_SERVICES="ocm" \
        -e OCM_OCM_PROVIDER_AUTHORIZER_PROVIDERS_FILE=/dev-stock/ocmproviders.json \
        -e GRAPH_INCLUDE_OCM_SHAREES=true \
		-e OCM_OCM_INVITE_MANAGER_INSECURE=true \
        -e OCM_OCM_SHARE_PROVIDER_INSECURE=true \
        -e OCM_OCM_STORAGE_PROVIDER_INSECURE=true \
        -e WEB_UI_CONFIG_FILE=/dev-stock/web-ui-config.json \
        -e GATEWAY_GRPC_ADDR="0.0.0.0:9142" \
        -e MICRO_REGISTRY_ADDRESS="127.0.0.1:9233" \
        -e NATS_NATS_HOST="0.0.0.0" \
        -e NATS_NATS_PORT="9233" \
        -e OC_SHOW_USER_EMAIL_IN_RESULTS="true" \
        -e OC_SHARING_PUBLIC_SHARE_MUST_HAVE_PASSWORD="false" \
        -v /etc/timezone:/etc/timezone:ro \
        -v /etc/localtime:/etc/localtime:ro \
        -v "${TEMP_DIR}/opencloud:/dev-stock" \
        --entrypoint /bin/sh \
        "${image}:${tag#v}" \
        -c "opencloud init || true; opencloud server" || error_exit "Failed to start EFSS container for opencloud ${number}."

    # Wait for EFSS port to open
    # TODO @MahdiBaghbani: we might need custom images with ss installed.
    # run_quietly_if_ci wait_for_port "opencloud${number}.docker" 443

    run_quietly_if_ci echo "Opencloud instance ${number} started."
}

# -----------------------------------------------------------------------------------
# Function: prepare_opencloud_environment
# Purpose : Prepare the environment for Opencloud instances
# Arguments:
#   $1 - First instance configuration (optional)
#   $2 - Second instance configuration (optional)
# -----------------------------------------------------------------------------------
prepare_opencloud_environment() {
    local instance1_config="${1:-}"
    local instance2_config="${2:-}"

    # copy init files.
    cp -fr "${ENV_ROOT}/docker/configs/opencloud"   "${TEMP_DIR}/opencloud"
    cp -fr "${TLS_CERT_DIR}"                        "${TEMP_DIR}/opencloud/certificates"
    cp -fr "${TLS_CA_DIR}"                          "${TEMP_DIR}/opencloud/certificate-authority"

    # make sure ownership is correct.
    sudo chown -R 1000:1000 "${TEMP_DIR}/opencloud/certificates"
    sudo chown -R 1000:1000 "${TEMP_DIR}/opencloud/certificate-authority"

    # Configure OCM providers
    configure_ocm_providers "${instance1_config}" "${instance2_config}"
}

# -----------------------------------------------------------------------------------
# Function: configure_ocm_providers
# Purpose : Configure OCM providers for Opencloud instances
# Arguments:
#   $1 - First instance configuration (e.g., "opencloud1.docker,opencloud1.docker,dav/")
#   $2 - Second instance configuration (e.g., "revanextcloud1.docker,nextcloud1.docker,remote.php/webdav/")
#
# Format for each instance configuration:
#   "ocm_domain,webdav_domain,webdav_path"
#   where:
#   - ocm_domain: domain for OCM-related endpoints
#   - webdav_domain: domain for WebDAV endpoints
#   - webdav_path: path for WebDAV endpoints
# -----------------------------------------------------------------------------------
configure_ocm_providers() {
    local instance1_config="${1:-opencloud1.docker,opencloud1.docker,dav/}"
    local instance2_config="${2:-opencloud2.docker,opencloud2.docker,dav/}"

    # Parse instance1 configuration
    IFS=',' read -r ocm1_domain webdav1_domain webdav1_path <<< "${instance1_config}"
    
    # Parse instance2 configuration
    IFS=',' read -r ocm2_domain webdav2_domain webdav2_path <<< "${instance2_config}"

    # Configure instance1
    changeInFile "${TEMP_DIR}/opencloud/ocmproviders.json" "|--instance1--domain--|"        "${ocm1_domain}"
    changeInFile "${TEMP_DIR}/opencloud/ocmproviders.json" "|--instance1--homepage--|"      "${ocm1_domain}"
    changeInFile "${TEMP_DIR}/opencloud/ocmproviders.json" "|--instance1--ocm--|"           "${ocm1_domain}"
    changeInFile "${TEMP_DIR}/opencloud/ocmproviders.json" "|--instance1--ocm--path--|"     "${ocm1_domain}/ocm/"
    changeInFile "${TEMP_DIR}/opencloud/ocmproviders.json" "|--instance1--ocm--host--|"     "${ocm1_domain}"
    changeInFile "${TEMP_DIR}/opencloud/ocmproviders.json" "|--instance1--webdav--|"        "${webdav1_domain}"
    changeInFile "${TEMP_DIR}/opencloud/ocmproviders.json" "|--instance1--webdav--path--|"  "${webdav1_domain}/${webdav1_path}"
    changeInFile "${TEMP_DIR}/opencloud/ocmproviders.json" "|--instance1--webdav--host--|"  "${webdav1_domain}"

    # Configure instance2
    changeInFile "${TEMP_DIR}/opencloud/ocmproviders.json" "|--instance2--domain--|"        "${ocm2_domain}"
    changeInFile "${TEMP_DIR}/opencloud/ocmproviders.json" "|--instance2--homepage--|"      "${ocm2_domain}"
    changeInFile "${TEMP_DIR}/opencloud/ocmproviders.json" "|--instance2--ocm--|"           "${ocm2_domain}"
    changeInFile "${TEMP_DIR}/opencloud/ocmproviders.json" "|--instance2--ocm--path--|"     "${ocm2_domain}/ocm/"
    changeInFile "${TEMP_DIR}/opencloud/ocmproviders.json" "|--instance2--ocm--host--|"     "${ocm2_domain}"
    changeInFile "${TEMP_DIR}/opencloud/ocmproviders.json" "|--instance2--webdav--|"        "${webdav2_domain}"
    changeInFile "${TEMP_DIR}/opencloud/ocmproviders.json" "|--instance2--webdav--path--|"  "${webdav2_domain}/${webdav2_path}"
    changeInFile "${TEMP_DIR}/opencloud/ocmproviders.json" "|--instance2--webdav--host--|"  "${webdav2_domain}"
}

function changeInFile() {
  local file_path="${1}"
  local original="${2}"
  local replacement="${3}"

  sed -i "s#${original}#${replacement}#g" "${file_path}"
}

delete_opencloud() {
    local number="${1}"
    local opencloud="opencloud${number}.docker"

    run_quietly_if_ci echo "Deleting Opencloud instance ${number} …"

    # Stop containers if they exist (ignore errors if already gone/stopped)
    run_quietly_if_ci docker stop "${opencloud}" || true

    # Collect any **named** volumes attached to either container
    local volumes
    volumes="$(
        {
            docker inspect -f '{{ range .Mounts }}{{ if eq .Type "volume" }}{{ .Name }} {{ end }}{{ end }}' "${opencloud}" 2>/dev/null || true
        } | xargs -r echo
    )"

    # Remove containers (+ anonymous volumes with -v)
    run_quietly_if_ci docker rm -fv "${opencloud}" || true

    # Remove any named volumes we discovered
    if [[ -n "${volumes}" ]]; then
        run_quietly_if_ci echo "Removing volumes: ${volumes}"
        run_quietly_if_ci docker volume rm -f ${volumes} || true
    fi

    run_quietly_if_ci rm -rf "${TEMP_DIR}/opencloud"

    run_quietly_if_ci echo "Opencloud instance ${number} removed."
}
