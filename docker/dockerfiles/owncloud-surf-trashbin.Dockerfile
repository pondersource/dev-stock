FROM pondersource/dev-stock-owncloud:latest

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource ownCloud SURF Trashbin Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

USER www-data

ARG REPO_SURF_TRASHBIN=https://github.com/pondersource/surf-trashbin-app
ARG BRANCH_SURF_TRASHBIN=master
# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .
# $RANDOM returns random number each time.
ARG CACHEBUST="default"
RUN git clone                           \
    --depth 1                           \
    --branch ${BRANCH_SURF_TRASHBIN}    \
    ${REPO_SURF_TRASHBIN}               \
    apps/surf-trashbin-app

RUN cd apps && ln --symbolic --force surf-trashbin-app/surf_trashbin

# this file can be overrided in docker run or docker compose.yaml. 
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init-owncloud-surf-trashbin.sh /init.sh

USER root
