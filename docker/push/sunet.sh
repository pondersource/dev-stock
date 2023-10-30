#!/usr/bin/env bash

set -e

echo "Log in as pondersource"
docker login

docker push pondersource/dev-stock-nextcloud-sunet
docker push pondersource/dev-stock-simple-saml-php
