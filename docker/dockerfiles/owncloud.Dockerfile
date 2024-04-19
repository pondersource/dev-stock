FROM pondersource/dev-stock-owncloud-base:latest

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource ownCloud Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

RUN curl --silent --show-error https://getcomposer.org/installer -o /root/composer-setup.php
RUN php /root/composer-setup.php --install-dir=/usr/local/bin --filename=composer && rm /root/composer-setup.php

ARG REPO_OWNCLOUD=https://github.com/owncloud/core
ARG BRANCH_OWNCLOUD=v10.14.0
# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .
# $RANDOM returns random number each time.
ARG CACHEBUST="default"

WORKDIR /var/www/source
RUN git clone                       \
    --depth 1                       \
    --recursive                     \
    --shallow-submodules            \
    --branch ${BRANCH_OWNCLOUD}     \
    ${REPO_OWNCLOUD}                \
    .

RUN find . -type d | grep -i "\.git" | xargs rm -rf
RUN cat /etc/ssl/certs/ca-certificates.crt >> /var/www/source/resources/config/ca-bundle.crt

RUN set -ex;                                                                                                \
    apk add --no-cache --update-cache --virtual .fetch-deps                                                 \
    --allow-untrusted --repository http://dl-cdn.alpinelinux.org/alpine/v3.16/main                          \
    bash                                                                                                    \
    make                                                                                                    \
    nodejs                                                                                                  \
    ;                                                                                                       \
                                                                                                            \
    composer install --no-dev && npm install -g yarn && make install-nodejs-deps                            \
    ;                                                                                                       \
                                                                                                            \                                                                                                       
    apk del --no-network .fetch-deps

WORKDIR /var/www/html

RUN chown -R www-data:root /var/www && chmod -R g=u /var/www
