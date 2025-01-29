#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

# Target paths
APP_SOURCE="/ponder/apps/sciencemesh"
APP_TARGET="/var/www/html/apps/sciencemesh"

# Remove existing directory or symlink if it exists
if [ -e "${APP_TARGET}" ] || [ -L "${APP_TARGET}" ]; then
    rm -rf "${APP_TARGET}"
fi

# Create new symlink
ln -sf "${APP_SOURCE}" "${APP_TARGET}"

php console.php app:enable sciencemesh

sed -i "3 i\  'sharing.managerFactory' => 'OCA\\\\ScienceMesh\\\\ScienceMeshProviderFactory'," /var/www/html/config/config.php
sed -i "4 i\  'sharing.remoteShareesSearch' => 'OCA\\\\ScienceMesh\\\\Plugins\\\\ScienceMeshSearchPlugin'," /var/www/html/config/config.php
