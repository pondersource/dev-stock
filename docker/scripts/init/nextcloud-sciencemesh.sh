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

# hack sciencemesh version :=)
sed -i -e 's/min-version="28"/min-version="27"/g'   "${APP_TARGET}/appinfo/info.xml"

php console.php app:enable sciencemesh
