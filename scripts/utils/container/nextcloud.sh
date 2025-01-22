#!/usr/bin/env bash

# Create a Nextcloud container with MariaDB backend
create_nextcloud() {
    local number="${1}"
    local user="${2}"
    local password="${3}"
    local image="${4}"
    local tag="${5}"

    run_quietly_if_ci echo "Creating EFSS instance: nextcloud ${number}"

    # Start MariaDB container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="marianextcloud${number}.docker" \
        -e MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD}" \
        "${MARIADB_REPO}":"${MARIADB_TAG}" \
        --transaction-isolation=READ-COMMITTED \
        --log-bin=binlog \
        --binlog-format=ROW \
        --innodb-file-per-table=1 \
        --skip-innodb-read-only-compressed || error_exit "Failed to start MariaDB container for nextcloud ${number}."

    # Wait for MariaDB port to open
    wait_for_port "marianextcloud${number}.docker" 3306

    # Start EFSS container
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="nextcloud${number}.docker" \
        --add-host "host.docker.internal:host-gateway" \
        -e HOST="nextcloud${number}" \
        -e NEXTCLOUD_HOST="nextcloud${number}.docker" \
        -e NEXTCLOUD_TRUSTED_DOMAINS="nextcloud${number}.docker" \
        -e NEXTCLOUD_ADMIN_USER="${user}" \
        -e NEXTCLOUD_ADMIN_PASSWORD="${password}" \
        -e NEXTCLOUD_APACHE_LOGLEVEL="warn" \
        -e MYSQL_HOST="marianextcloud${number}.docker" \
        -e MYSQL_DATABASE="efss" \
        -e MYSQL_USER="root" \
        -e MYSQL_PASSWORD="${MARIADB_ROOT_PASSWORD}" \
        "${image}:${tag}" || error_exit "Failed to start EFSS container for nextcloud ${number}."

    # Wait for EFSS port to open
    run_quietly_if_ci wait_for_port "nextcloud${number}.docker" 443
}
