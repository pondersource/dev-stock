#!/usr/bin/env bash

set -e

echo "Log in as pondersource"
docker login

docker push pondersource/dev-stock-owncloud-token-based-access:latest
