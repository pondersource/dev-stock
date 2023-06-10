#!/usr/bin/env bash

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="$(date +%s)" .

set -e

cd docker

echo Building pondersource/dev-stock-nextcloud-solid
docker build --build-arg CACHEBUST="$(date +%s)" --file ./nextcloud-solid.Dockerfile --tag pondersource/dev-stock-nextcloud-solid .
