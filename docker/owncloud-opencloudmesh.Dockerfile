FROM pondersource/dev-stock-owncloud

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="Pondersource ownCloud OpenCloud Mesh Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

USER www-data

ARG REPO_CUSTOM_GROUPS=https://github.com/owncloud/customgroups
ARG BRANCH_CUSTOM_GROUPS=master

ARG REPO_OCM=https://github.com/pondersource/oc-opencloudmesh
ARG BRANCH_OCM=main
# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="$(date +%s)" .
# $RANDOM returns random number each time.
ARG CACHEBUST="$(echo $RANDOM)"
RUN git clone                           \
    --depth 1                           \
    --branch ${BRANCH_CUSTOM_GROUPS}    \
    ${REPO_CUSTOM_GROUPS}               \
    apps/customgroups

RUN cd apps/customgroups &&             \
    composer install --no-dev &&        \
    yarn install &&                     \
    yarn build  

RUN git clone                           \
    --depth 1                           \
    --branch ${BRANCH_OCM}              \
    ${REPO_OCM}                         \
    apps/oc-opencloudmesh

RUN cd apps && ln --symbolic oc-opencloudmesh/opencloudmesh

# this file can be overrided in docker run or docker compose.yaml. 
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init-owncloud-opencloudmesh.sh /init.sh

USER root
