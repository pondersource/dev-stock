#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Nextcloud Container Creation Utilities
#
# This script provides functions for creating Nextcloud containers with MariaDB
# backend, supporting both standard and development configurations with volume
# mounting capabilities.
#
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Function: _create_nextcloud_base
# Purpose: Internal helper function to create a Nextcloud container with common configuration
#
# Arguments:
#   $1: Container number/ID
#   $2: Admin username
#   $3: Admin password
#   $4: Docker image
#   $5: Docker tag
#   $6: Volume mount arguments (optional, format: "-v path:path")
#   $7: Extra env values for the container (optional, format "-e env=value")
#
# Environment Variables Used:
#   DOCKER_NETWORK: Network for container communication
#   MARIADB_ROOT_PASSWORD: Root password for MariaDB
#   MARIADB_REPO: MariaDB Docker image repository
#   MARIADB_TAG: MariaDB Docker image tag
# ------------------------------------------------------------------------------
_create_nextcloud_base() {
    local number="${1}"
    local user="${2}"
    local password="${3}"
    local image="${4}"
    local tag="${5}"
    local volume_args="${6:-}"
    local extra_env="${7:-}"

    run_quietly_if_ci echo "Creating Nextcloud instance ${number} with MariaDB backend"

    # Start MariaDB container with optimized configuration
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="marianextcloud${number}.docker" \
        -e MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD}" \
        "${MARIADB_REPO}":"${MARIADB_TAG}" \
        --transaction-isolation=READ-COMMITTED \
        --log-bin=binlog \
        --binlog-format=ROW \
        --innodb-file-per-table=1 \
        --skip-innodb-read-only-compressed || error_exit "Failed to start MariaDB container for nextcloud ${number}."

    # Ensure MariaDB is ready before proceeding
    wait_for_port "marianextcloud${number}.docker" 3306

    # Start Nextcloud container with provided configuration
    # shellcheck disable=SC2086
    run_docker_container --detach --network="${DOCKER_NETWORK}" \
        --name="nextcloud${number}.docker" \
        --add-host "host.docker.internal:host-gateway" \
        ${volume_args} \
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
        -e USE_CI_IMAGE="${USE_CI_IMAGE}" \
        ${extra_env} \
        "${image}:${tag}" || error_exit "Failed to start Nextcloud container ${number}."

    # Ensure Nextcloud is ready to accept connections
    run_quietly_if_ci wait_for_port "nextcloud${number}.docker" 443
}

# ------------------------------------------------------------------------------
# Function: create_nextcloud
# Purpose: Creates a standard Nextcloud container with MariaDB backend
#
# Arguments:
#   $1: Container number/ID
#   $2: Admin username
#   $3: Admin password
#   $4: Docker image
#   $5: Docker tag
#   $6: Extra env
#
# Example:
#   create_nextcloud 1 "admin" "password" "pondersource/nextcloud" "v30.0.2" "-e funny=true -e bugs=bunny"
# ------------------------------------------------------------------------------
create_nextcloud() {
    _create_nextcloud_base "$1" "$2" "$3" "$4" "$5" "" "$6"
}

# ------------------------------------------------------------------------------
# Function: create_nextcloud_dev
# Purpose: Creates a Nextcloud container with volume mounts for development
#
# This function extends create_nextcloud with volume mounting capabilities,
# useful for development scenarios where you need to mount local directories
# into the container.
#
# Arguments:
#   $1: Container number/ID
#   $2: Admin username
#   $3: Admin password
#   $4: Docker image
#   $5: Docker tag
#   $6: Comma-separated list of volume mounts
#      Format: "src:/dest,src2:/dest2"
#      Example: "apps:/var/www/html/apps,config:/var/www/html/config"
#
# Example:
#   create_nextcloud_dev 1 "admin" "password" "pondersource/nextcloud" "v30.0.2" \
#       "apps:/var/www/html/apps,config:/var/www/html/config"
# ------------------------------------------------------------------------------
create_nextcloud_dev() {
    local number="${1}"
    local user="${2}"
    local password="${3}"
    local image="${4}"
    local tag="${5}"
    local volumes="${6}"
    local volume_args=""

    # Convert comma-separated volume string to Docker volume arguments
    if [[ -n "${volumes}" ]]; then
        IFS=',' read -ra VOLUME_ARRAY <<< "${volumes}"
        for volume in "${VOLUME_ARRAY[@]}"; do
            volume_args="${volume_args} -v ${volume}"
        done
    fi

    _create_nextcloud_base "${number}" "${user}" "${password}" "${image}" "${tag}" "${volume_args}"
}
