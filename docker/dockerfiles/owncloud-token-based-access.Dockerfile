FROM pondersource/dev-stock-owncloud

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource ownCloud Token Based Access Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

USER www-data

ARG REPO_TOKEN_BASED_ACCESS=https://github.com/pondersource/surf-token-based-access
ARG BRANCH_TOKEN_BASED_ACCESS=main
# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .
# $RANDOM returns random number each time.
ARG CACHEBUST="default"
RUN git clone                                       \
    --depth 1                                       \
    --branch ${BRANCH_TOKEN_BASED_ACCESS}           \
    ${REPO_TOKEN_BASED_ACCESS}                      \
    apps/token-based-access

RUN cd apps && ln --symbolic --force token-based-access/tokenbaseddav

# this file can be overrided in docker run or docker compose.yaml. 
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init-owncloud-token-based-access.sh /init.sh

USER root
