FROM pondersource/dev-stock-nextcloud

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource Nextcloud Solid Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

USER www-data

ARG REPO_SOLID=https://github.com/pondersource/mfazones
ARG BRANCH_SOLID=main
RUN git clone                     \
    --depth 1                     \
    --branch ${BRANCH_SOLID}      \
    ${REPO_SOLID}                 \
    apps/mfazones
# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .
# $RANDOM returns random number each time.
ARG CACHEBUST="default"
RUN cd apps/mfazones && git pull
    
# this file can be overrided in docker run or docker compose.yaml. 
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init-nextcloud-sunet.sh /init.sh

USER root
