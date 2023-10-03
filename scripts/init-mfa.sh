#!/usr/bin/env bash
set -e

# add additional tagging for docker images.
docker tag pondersource/dev-stock-nextcloud-mfa pondersource/dev-stock-nc1-mfa
docker tag pondersource/dev-stock-nextcloud-mfa pondersource/dev-stock-nc2-mfa

docker network inspect testnet >/dev/null 2>&1 || docker network create testnet
