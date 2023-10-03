#!/usr/bin/env bash
set -e

/opt/keycloak/bin/kc.sh import --file /opt/keycloak_import/keycloak.json
