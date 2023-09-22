FROM pondersource/dev-stock-owncloud

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource ownCloud token-based-access Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

USER www-data

ARG REPO_DAV_TOKEN=https://github.com/pondersource/dav-token-access
ARG BRANCH_DAV_TOKEN=master
# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .
# $RANDOM returns random number each time.
ARG CACHEBUST="default"
RUN git clone                           \
    --depth 1                           \
    --branch ${BRANCH_DAV_TOKEN}        \
    ${REPO_DAV_TOKEN}                   \
    apps/token-based-access

RUN cd apps && ln --symbolic --force token-based-access/tokenbasedav

# this file can be overrided in docker run or docker compose.yaml. 
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init-owncloud-token-based-access.sh /init.sh

USER root
