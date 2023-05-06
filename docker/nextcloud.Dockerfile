FROM pondersource/dev-stock-php-base

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="Pondersource Nextcloud Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

RUN rm --recursive --force /var/www/html
USER www-data

ARG REPO_NEXTCLOUD=https://github.com/nextcloud/server.git
ARG BRANCH_NEXTCLOUD=v26.0.1
# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="$(date +%s)" .
# $RANDOM returns random number each time.
ARG CACHEBUST="$(echo $RANDOM)"
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

USER www-data
# this file can be overrided in docker run or docker compose.yaml. 
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init-nextcloud.sh /init.sh
RUN mkdir --parents data ; touch data/nextcloud.log

USER root
CMD /usr/sbin/apache2ctl -DFOREGROUND & tail --follow /var/log/apache2/error.log & tail --follow data/nextcloud.log
