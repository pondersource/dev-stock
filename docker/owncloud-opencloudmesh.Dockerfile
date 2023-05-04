FROM pondersource/dev-stock-owncloud

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="Pondersource ownCloud OpenCloud Mesh Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

USER www-data

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="$(date +%s)" .
# $RANDOM returns random number each time.
ARG CACHEBUST="$(echo $RANDOM)"
RUN cd apps && git clone --depth=1 https://github.com/owncloud/customgroups
RUN cd apps/customgroups && composer install --no-dev
RUN cd apps/customgroups && yarn install
RUN cd apps/customgroups && yarn build
RUN cd apps && git clone --depth=1 https://github.com/pondersource/oc-opencloudmesh
RUN cd apps && ln --symbolic oc-opencloudmesh/opencloudmesh

# this file can be overrided in docker run or docker compose.yaml. 
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init-owncloud-opencloudmesh.sh /init.sh

USER root
