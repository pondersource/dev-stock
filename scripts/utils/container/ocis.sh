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
        -e OCIS_INSECURE=true\
        -e PROXY_TRANSPORT_TLS_KEY="/certificates/ocis${number}.key"                                                            
        -e PROXY_TRANSPORT_TLS_CERT="/certificates/ocis${number}.crt"                                                           
        -e PROXY_ENABLE_BASIC_AUTH=true \                                                                                        
        -e IDM_ADMIN_PASSWORD=admin \
        -e IDM_CREATE_DEMO_USERS=true \
        -v "${ENV_ROOT}/temp/certificates:/certificates" \
        -v "${ENV_ROOT}/temp/certificate-authority:/certificate-authority" \
        --entrypoint /bin/sh \
        "${image}:${tag#v}" \
        -c "ocis init || true; ocis server" || error_exit "Failed to start EFSS container for ocis ${number}."

    # Wait for EFSS port to open
    run_quietly_if_ci wait_for_port "ocis${number}.docker" 9200
}
