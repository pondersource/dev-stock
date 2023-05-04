FROM pondersource/dev-stock-owncloud-opencloudmesh

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="Pondersource ownCloud rd-sram Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

USER www-data

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="$(date +%s)" .
ARG CACHEBUST=1
RUN cd apps && git clone --depth=1 https://github.com/SURFnet/rd-sram-integration
RUN cd apps && ln --symbolic rd-sram-integration/federatedgroups

# this file can be overrided in docker run or docker compose.yaml. 
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init-owncloud-rd-sram.sh /init.sh

USER root
