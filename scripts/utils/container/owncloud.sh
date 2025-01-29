#!/usr/bin/env bash

# Create an ownCloud container with MariaDB backend
create_owncloud() {
    local number="${1}"
    local user="${2}"
    local password="${3}"
    local image="${4}"
    local tag="${5}"

    run_quietly_if_ci echo "Creating EFSS instance: owncloud ${number}"

    # Start MariaDB container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="mariaowncloud${number}.docker" \
        -e MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD}" \
        "${MARIADB_REPO}":"${MARIADB_TAG}" \
        --transaction-isolation=READ-COMMITTED \
        --log-bin=binlog \
        --binlog-format=ROW \
        --innodb-file-per-table=1 \
        --skip-innodb-read-only-compressed || error_exit "Failed to start MariaDB container for owncloud ${number}."

    # Wait for MariaDB port to open
    wait_for_port "mariaowncloud${number}.docker" 3306

    # Start EFSS container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="owncloud${number}.docker" \
        --add-host "host.docker.internal:host-gateway" \
        -e HOST="owncloud${number}" \
        -e OWNCLOUD_HOST="owncloud${number}.docker" \
        -e OWNCLOUD_TRUSTED_DOMAINS="owncloud${number}.docker" \
        -e OWNCLOUD_ADMIN_USER="${user}" \
        -e OWNCLOUD_ADMIN_PASSWORD="${password}" \
        -e OWNCLOUD_APACHE_LOGLEVEL="warn" \
        -e MYSQL_HOST="mariaowncloud${number}.docker" \
        -e MYSQL_DATABASE="efss" \
        -e MYSQL_USER="root" \
        -e MYSQL_PASSWORD="${MARIADB_ROOT_PASSWORD}" \
        "${image}:${tag}" || error_exit "Failed to start EFSS container for owncloud ${number}."

    # Wait for EFSS port to open
    run_quietly_if_ci wait_for_port "owncloud${number}.docker" 443
}
