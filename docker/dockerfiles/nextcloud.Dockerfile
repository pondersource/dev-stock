FROM pondersource/nextcloud-base:latest

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource Nextcloud Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

ARG NEXTCLOUD_REPO=https://github.com/nextcloud/server
ARG NEXTCLOUD_BRANCH=v30.0.10

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .
# $RANDOM returns random number each time.
ARG CACHEBUST="default"
RUN set -ex; \
    cd /usr/src/; \
    git clone \
    --depth 1 \
    --recursive \
    --shallow-submodules \
    --branch ${NEXTCLOUD_BRANCH} \
    ${NEXTCLOUD_REPO} \
    nextcloud; \
    rm -rf /usr/src/nextcloud/.git; \
    mkdir -p /usr/src/nextcloud/data; \
    mkdir -p /usr/src/nextcloud/custom_apps; \
    chmod +x /usr/src/nextcloud/occ

# After cloning, `git` is no longer needed at runtime, so remove it to reduce image size.
RUN apt-get purge -y git && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY ./scripts/nextcloud/*.sh /
COPY ./scripts/nextcloud/upgrade.exclude /
COPY ./configs/nextcloud/* /usr/src/nextcloud/config/

SHELL ["/bin/bash", "-c"]
ENTRYPOINT ["/entrypoint.sh"]
CMD apache2ctl -DFOREGROUND & tail --follow /var/log/apache2/access.log & tail --follow /var/log/apache2/error.log & tail --follow /var/www/html/data/nextcloud.log
