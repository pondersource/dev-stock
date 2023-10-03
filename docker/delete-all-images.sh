#!/usr/bin/env bash
set -e

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .

# delete all containers including its volumes.
docker rm -vf $(docker ps -aq) || true

# delete all images.
docker rmi -f $(docker images -aq) || true

docker system prune --force
docker volume prune --force
