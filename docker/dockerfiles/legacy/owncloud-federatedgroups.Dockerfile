FROM pondersource/owncloud-opencloudmesh:latest

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource ownCloud federatedgroups Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

USER www-data

ARG REPO_RD_SRAM=https://github.com/SURFnet/rd-sram-integration
ARG BRANCH_RD_SRAM=main
# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .
# $RANDOM returns random number each time.
ARG CACHEBUST="default"
RUN git clone                           \
    --depth 1                           \
    --branch ${BRANCH_RD_SRAM}          \
    ${REPO_RD_SRAM}                     \
    apps/federatedgroups-git-repo

RUN cd apps && ln --symbolic --force federatedgroups-git-repo/federatedgroups federatedgroups

COPY ./scripts/federatedgroups /curls

# this file can be overrided in docker run or docker compose.yaml.
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init/owncloud-federatedgroups.sh /init.sh

USER root
