#!/usr/bin/env bash

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .

set -e

# delete all containers including its volumes.
docker rm -vf $(docker ps -aq) >/dev/null 2>&1 || true

# delete all images.
docker rmi -f $(docker images -aq) >/dev/null 2>&1 || true

docker system prune --force
docker volume prune --force
