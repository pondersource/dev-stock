FROM pondersource/dev-stock-nextcloud:v27.1.11

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource Nextcloud ScienceMesh Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

USER www-data

ARG REPO_SCIENCEMESH=https://github.com/sciencemesh/nc-sciencemesh
ARG BRANCH_SCIENCEMESH=nextcloud
# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .
# $RANDOM returns random number each time.
ARG CACHEBUST="default"
RUN git clone                           \
    --depth 1                           \
    --branch ${BRANCH_SCIENCEMESH}      \
    ${REPO_SCIENCEMESH}                 \
    apps/sciencemesh

RUN cd apps/sciencemesh && git pull
RUN cd apps/sciencemesh && make

# this file can be overrided in docker run or docker compose.yaml.
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init/nextcloud-sciencemesh.sh /init.sh
RUN mkdir -p data; touch data/nextcloud.log

USER root
