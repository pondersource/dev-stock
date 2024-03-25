#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

# clear terminal:   yes, no. default is yes.
CLEAR_TERMINAL=${1:-"yes"}

running=$(docker ps -q)
# we actually need globbing and word spliting in this case.
# shellcheck disable=SC2086
[ -z "$running" ] || docker kill $running   >/dev/null 2>&1

existing=$(docker ps -qa)
# we actually need globbing and word spliting in this case.
# shellcheck disable=SC2086
[ -z "$existing" ] || docker rm $existing   >/dev/null 2>&1

docker network remove testnet || true       >/dev/null 2>&1
docker network create testnet               >/dev/null 2>&1

# I want a clean terminal xD
if [ "${CLEAR_TERMINAL}" = "yes" ]; then
    clear
fi
