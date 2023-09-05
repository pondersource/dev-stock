FROM pondersource/dev-stock-php-base

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource Nextcloud Sciencemesh Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

RUN rm --recursive --force /var/www/html
USER www-data

ARG REPO_NEXTCLOUD=https://github.com/nextcloud/server
ARG BRANCH_NEXTCLOUD=fix/noid/ocm-controller
# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .
# $RANDOM returns random number each time.
ARG CACHEBUST="default"
RUN git clone                       \
    --depth 1                       \
    --recursive                     \
    --shallow-submodules            \
    --branch ${BRANCH_NEXTCLOUD}    \
    ${REPO_NEXTCLOUD}               \
    html

USER root
WORKDIR /var/www/html

# switch php version for Nextloud.
RUN switch-php.sh 8.2

ENV PHP_MEMORY_LIMIT="512M"

RUN curl --silent --show-error https://getcomposer.org/installer -o /root/composer-setup.php
RUN php /root/composer-setup.php --install-dir=/usr/local/bin --filename=composer

USER www-data

ARG REPO_SCIENCEMESH=https://github.com/pondersource/nc-sciencemesh
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
COPY ./scripts/init-nextcloud-sciencemesh.sh /init.sh
RUN mkdir -p data ; touch data/nextcloud.log

USER root
