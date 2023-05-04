FROM pondersource/dev-stock-nextcloud

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="Pondersource Nextcloud Sciencemesh Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

USER www-data

ARG REPO_SCIENCEMESH=https://github.com/pondersource/nc-sciencemesh
ARG BRANCH_SCIENCEMESH=main
# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="$(date +%s)" .
ARG CACHEBUST=1
RUN git clone                           \
    --depth=1                           \
    --branch ${BRANCH_SCIENCEMESH}      \
    ${REPO_SCIENCEMESH}                 \
    apps/sciencemesh

RUN cd apps/sciencemesh && git pull
RUN cd apps/sciencemesh && make

# this file can be overrided in docker run or docker compose.yaml. 
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init-nextcloud-sciencemesh.sh /init.sh

USER root
