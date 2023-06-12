#!/usr/bin/env bash

set -e

echo "Log in as pondersource"
docker login pondersource

docker push pondersource/dev-stock-nextcloud-mfa
