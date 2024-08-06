FROM pondersource/dev-stock-owncloud:latest

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource ownCloud OCM Test Suite Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

USER www-data

ARG REPO_CUSTOM_GROUPS=https://github.com/owncloud/customgroups
ARG BRANCH_CUSTOM_GROUPS=master

ARG REPO_OCM=https://github.com/pondersource/oc-opencloudmesh
ARG BRANCH_OCM=main

ARG REPO_SCIENCEMESH=https://github.com/sciencemesh/nc-sciencemesh
ARG BRANCH_SCIENCEMESH=owncloud

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .
# $RANDOM returns random number each time.
ARG CACHEBUST="default"
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

RUN git clone                           \
    --depth 1                           \
    --branch ${BRANCH_SCIENCEMESH}      \
    ${REPO_SCIENCEMESH}                 \
    apps/sciencemesh

RUN cd apps/sciencemesh && git pull
RUN cd apps/sciencemesh && make
RUN cd apps && ln --symbolic --force oc-opencloudmesh/opencloudmesh

# this file can be overrided in docker run or docker compose.yaml. 
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init/owncloud-sm-ocm.sh /init.sh

USER root
CMD /usr/sbin/apache2ctl -DFOREGROUND & tail --follow /var/log/apache2/access.log & tail --follow /var/log/apache2/error.log & tail --follow data/owncloud.log
