#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

FILE="/usr/bin/php${1}"

if [[ -n "${1}" ]]; then
    if [[ -f "${FILE}" ]]; then
        update-alternatives --set php           "/usr/bin/php${1}"
        update-alternatives --set phar          "/usr/bin/phar${1}"
        update-alternatives --set phar.phar     "/usr/bin/phar.phar${1}"

        A2MODPHP=$(ls /etc/apache2/mods-enabled/php*.load)
        a2dismod "${A2MODPHP:26:6}"
        a2enmod "php${1}"
    else
        echo "This version is not available in this system."
    fi
else
   echo "You didn't provide any version number!"
fi
