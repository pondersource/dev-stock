#!/usr/bin/env bash

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="$(date +%s)" .

set -e

# delete all containers including its volumes.
docker rm -vf $(docker ps -aq) || true

# delete all images.
docker rmi -f $(docker images -aq) || true

docker-push-mfa.sh
