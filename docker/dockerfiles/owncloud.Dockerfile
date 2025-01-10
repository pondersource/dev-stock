FROM pondersource/owncloud-base:latest

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource ownCloud Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

ARG OWNCLOUD_REPO=https://github.com/owncloud/core
ARG OWNCLOUD_BRANCH=v10.15.0

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
    --branch ${OWNCLOUD_BRANCH} \
    ${OWNCLOUD_REPO} \
    owncloud; \
    rm -rf /usr/src/owncloud/.git; \
    mkdir -p /usr/src/owncloud/data; \
    mkdir -p /usr/src/owncloud/custom_apps; \
    chmod +x /usr/src/owncloud/occ

RUN cd /usr/src/owncloud; \
    composer install --no-dev; \
    make install-nodejs-deps

# After cloning, `git` is no longer needed at runtime, so remove it to reduce image size.
RUN apt-get purge -y git && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY ./scripts/owncloud/*.sh /
COPY ./scripts/owncloud/upgrade.exclude /
COPY ./configs/owncloud/* /usr/src/owncloud/config/

SHELL ["/bin/bash", "-c"]
ENTRYPOINT ["/entrypoint.sh"]
CMD apache2ctl -DFOREGROUND & tail --follow /var/log/apache2/access.log & tail --follow /var/log/apache2/error.log & tail --follow /var/www/html/data/owncloud.log
