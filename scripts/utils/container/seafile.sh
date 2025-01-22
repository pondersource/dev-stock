#!/usr/bin/env bash

# Create a Seafile container with MariaDB and Memcached backends
create_seafile() {
    local number="${1}"
    local user="${2}"
    local password="${3}"
    local image="${4}"
    local tag="${5}"
    local remote_ocm_server="${6}"

    run_quietly_if_ci echo "Creating EFSS instance: seafile ${number}"

    # Start Memcached container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="memcacheseafile${number}.docker" \
        "${MEMCACHED_REPO}:${MEMCACHED_TAG}" \
        memcached -m 256 || error_exit "Failed to start Memcached container for seafile ${number}."

    # Start MariaDB container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="mariaseafile${number}.docker" \
        -e MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD}" \
        "${MARIADB_REPO}:${MARIADB_TAG}" \
        --transaction-isolation=READ-COMMITTED \
        --log-bin=binlog \
        --binlog-format=ROW \
        --innodb-file-per-table=1 \
        --skip-innodb-read-only-compressed || error_exit "Failed to start MariaDB container for seafile ${number}."

    # Wait for MariaDB port to open
    wait_for_port "mariaseafile${number}.docker" 3306

    # Start EFSS container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="seafile${number}.docker" \
        -e TIME_ZONE="Etc/UTC" \
        -e DB_HOST="mariaseafile${number}.docker" \
        -e DB_ROOT_PASSWD="${MARIADB_ROOT_PASSWORD}" \
        -e SEAFILE_ADMIN_EMAIL="${user}" \
        -e SEAFILE_ADMIN_PASSWORD="${password}" \
        -e SEAFILE_SERVER_LETSENCRYPT=false \
        -e FORCE_HTTPS_IN_CONF=false \
        -e SEAFILE_SERVER_HOSTNAME="seafile${number}.docker" \
        -e SEAFILE_MEMCACHE_HOST="memcacheseafile${number}.docker" \
        -e SEAFILE_MEMCACHE_PORT=11211 \
        -v "${TLS_CA_DIR}:/certificate-authority" \
        -v "${TLS_CERT_DIR}:/certificates" \
        -v "${TLS_CERT_DIR}/seafile${number}.crt:/shared/ssl/seafile${number}.docker.crt" \
        -v "${TLS_CERT_DIR}/seafile${number}.key:/shared/ssl/seafile${number}.docker.key" \
        -v "${DOCKER_SCRIPTS_DIR}/seafile/seafile.sh:/init.sh" \
        "${image}:${tag#v}" || error_exit "Failed to start EFSS container for seafile ${number}."
    
    # Wait for EFSS port to open
    # TODO @MahdiBaghbani: we might need custom images with ss installed.
    # run_quietly_if_ci wait_for_port "seafile${number}.docker" 443

    # seafile needs time to bootstrap itself.
    sleep 5

    # run init script inside seafile.
    run_quietly_if_ci docker exec -e remote_ocm_server="${remote_ocm_server}" "seafile${number}.docker" bash -c "chmod +x /init.sh && /init.sh ${remote_ocm_server}"

    # restart seafile to apply our changes.
    sleep 2
    run_quietly_if_ci docker restart "seafile${number}.docker"
    sleep 2

    # Wait for EFSS port to open
    # TODO @MahdiBaghbani: we might need custom images with ss installed.
    # run_quietly_if_ci wait_for_port "seafile${number}.docker" 443
}
