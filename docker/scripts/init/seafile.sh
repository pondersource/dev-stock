#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

uuid=$(cat /proc/sys/kernel/random/uuid)

# not the best way to do this, I know.
remote_server_1=${1-seafile}

cat >> /opt/seafile/conf/seahub_settings.py <<EOL

# Enable OCM
ENABLE_OCM = True
OCM_PROVIDER_ID = "${uuid}" # the unique id of this server
OCM_REMOTE_SERVERS = [
    {
        "server_name": "${remote_server_1}",
        "server_url": "http://${remote_server_1}.docker/", # should end with '/'
    },
]
EOL

sed -i "s/.*'LOCATION': 'memcached:11211',*/'        LOCATION': '${SEAFILE_MEMCACHE_HOST}:${SEAFILE_MEMCACHE_PORT}',/" /opt/seafile/conf/seahub_settings.py
