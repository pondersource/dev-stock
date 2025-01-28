#!/usr/bin/env bash

# Create an OCIS container
create_ocis() {
    local number="${1}"
    local image="${2}"
    local tag="${3}"

    run_quietly_if_ci echo "Creating EFSS instance: ocis ${number}"

    # Start EFSS container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="ocis${number}.docker" \
        -e OCIS_LOG_LEVEL=info \
        -e OCIS_LOG_COLOR=true \
        -e OCIS_LOG_PRETTY=true \
        -e PROXY_HTTP_ADDR=0.0.0.0:443 \
        -e OCIS_URL="https://ocis${number}.docker" \
        -e OCIS_INSECURE=true \
        -e PROXY_TRANSPORT_TLS_KEY="/certificates/ocis${number}.key" \
        -e PROXY_TRANSPORT_TLS_CERT="/certificates/ocis${number}.crt" \
        -e PROXY_ENABLE_BASIC_AUTH=true \
        -e IDM_ADMIN_PASSWORD=admin \
        -e IDM_CREATE_DEMO_USERS=true \
        -e FRONTEND_OCS_INCLUDE_OCM_SHAREES=true \
        -e FRONTEND_OCS_LIST_OCM_SHARES=true \
        -e FRONTEND_ENABLE_FEDERATED_SHARING_INCOMING=true \
        -e FRONTEND_ENABLE_FEDERATED_SHARING_OUTGOING=true \
        -e OCIS_ADD_RUN_SERVICES=ocm \
        -e OCM_OCM_PROVIDER_AUTHORIZER_PROVIDERS_FILE=/dev-stock/ocmproviders.json \
        -e GRAPH_INCLUDE_OCM_SHAREES=true \
		-e OCM_OCM_INVITE_MANAGER_INSECURE=true \
        -e OCM_OCM_SHARE_PROVIDER_INSECURE=true \
        -e OCM_OCM_STORAGE_PROVIDER_INSECURE=true \
        -e WEB_UI_CONFIG_FILE=/dev-stock/web-ui-config.json \
        -v "${TEMP_DIR}/ocis:/dev-stock" \
        -v "${TLS_CERT_DIR}:/certificates" \
        -v "${TLS_CA_DIR}:/certificate-authority" \
        --entrypoint /bin/sh \
        "${image}:${tag#v}" \
        -c "ocis init || true; ocis server" || error_exit "Failed to start EFSS container for ocis ${number}."

    # Wait for EFSS port to open
    # TODO @MahdiBaghbani: we might need custom images with ss installed.
    # run_quietly_if_ci wait_for_port "ocis${number}.docker" 443
}

# -----------------------------------------------------------------------------------
# Function: prepare_ocis_environment
# Purpose : Prepare the environment for oCIS instances
# Arguments:
#   $1 - First instance configuration (optional)
#   $2 - Second instance configuration (optional)
# -----------------------------------------------------------------------------------
prepare_ocis_environment() {
    local instance1_config="${1:-}"
    local instance2_config="${2:-}"

    # copy init files.
    cp -fr "${ENV_ROOT}/docker/configs/ocis" "${TEMP_DIR}/ocis"

    # Configure OCM providers
    configure_ocm_providers "${instance1_config}" "${instance2_config}"
}

# -----------------------------------------------------------------------------------
# Function: configure_ocm_providers
# Purpose : Configure OCM providers for oCIS instances
# Arguments:
#   $1 - First instance configuration (e.g., "ocis1.docker,ocis1.docker,dav/")
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
    local instance1_config="${1:-ocis1.docker,ocis1.docker,dav/}"
    local instance2_config="${2:-ocis2.docker,ocis2.docker,dav/}"

    # Parse instance1 configuration
    IFS=',' read -r ocm1_domain webdav1_domain webdav1_path <<< "${instance1_config}"
    
    # Parse instance2 configuration
    IFS=',' read -r ocm2_domain webdav2_domain webdav2_path <<< "${instance2_config}"

    # Configure instance1
    changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance1--domain--|"        "${ocm1_domain}"
    changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance1--homepage--|"      "${ocm1_domain}"
    changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance1--ocm--|"           "${ocm1_domain}"
    changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance1--ocm--path--|"     "${ocm1_domain}/ocm/"
    changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance1--ocm--host--|"     "${ocm1_domain}"
    changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance1--webdav--|"        "${webdav1_domain}"
    changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance1--webdav--path--|"  "${webdav1_domain}/${webdav1_path}"
    changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance1--webdav--host--|"  "${webdav1_domain}"

    # Configure instance2
    changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance2--domain--|"        "${ocm2_domain}"
    changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance2--homepage--|"      "${ocm2_domain}"
    changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance2--ocm--|"           "${ocm2_domain}"
    changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance2--ocm--path--|"     "${ocm2_domain}/ocm/"
    changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance2--ocm--host--|"     "${ocm2_domain}"
    changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance2--webdav--|"        "${webdav2_domain}"
    changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance2--webdav--path--|"  "${webdav2_domain}/${webdav2_path}"
    changeInFile "${ENV_ROOT}/temp/ocis/ocmproviders.json" "|--instance2--webdav--host--|"  "${webdav2_domain}"
}

function changeInFile() {
  local file_path="${1}"
  local original="${2}"
  local replacement="${3}"

  sed -i "s#${original}#${replacement}#g" "${file_path}"
}
