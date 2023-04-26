#!/usr/bin/env bash

set -e

FILE="/usr/bin/php${1}"

if [[ -n "${1}" ]]; then
    if [[ -f "${FILE}" ]]; then
        sudo rm --force /usr/bin/php.default
        sudo ln --symbolic "${FILE}" /usr/bin/php.default
    else
        echo "This version is not available in this system."
    fi
else
   echo "You didn't provide any version number!"
fi


