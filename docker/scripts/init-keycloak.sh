#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts
set -e

/opt/keycloak/bin/kc.sh import --file /opt/keycloak_import/keycloak.json
