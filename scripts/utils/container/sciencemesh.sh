#!/usr/bin/env bash

# -----------------------------------------------------------------------------------
# Function: configure_sciencemesh
# Purpose: Configure ScienceMesh settings for the EFSS platform.
# Arguments:
#   $1 - EFSS platform (e.g., nextcloud).
#   $2 - Instance number.
#   $3 - IOP URL.
#   $4 - Reva shared secret.
#   $5 - Mesh directory URL.
#   $6 - Invite manager API key.
# -----------------------------------------------------------------------------------
configure_sciencemesh() {
    local platform="${1}"
    local number="${2}"
    local iop_url="${3}"
    local reva_shared_secret="${4}"
    local mesh_directory_url="${5}"
    local invite_manager_apikey="${6}"

    run_quietly_if_ci echo "Configuring ScienceMesh for ${platform} ${number}"

    local mysql_cmd="docker exec maria${platform}${number}.docker mariadb -u root -p${MARIADB_ROOT_PASSWORD} efss"

    # Insert ScienceMesh configuration into the database
    run_quietly_if_ci $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'iopUrl', '${iop_url}');"
    run_quietly_if_ci $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'revaSharedSecret', '${reva_shared_secret}');"
    run_quietly_if_ci $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'meshDirectoryUrl', '${mesh_directory_url}');"
    run_quietly_if_ci $mysql_cmd -e "insert into oc_appconfig (appid, configkey, configvalue) values ('sciencemesh', 'inviteManagerApikey', '${invite_manager_apikey}');"
}
