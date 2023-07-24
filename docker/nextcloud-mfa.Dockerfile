FROM pondersource/dev-stock-php-base

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource Nextcloud MFA Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

ARG NEXTCLOUD_SERVER=https://download.nextcloud.com/.customers/server/26.0.1-21154162/nextcloud-26.0.1-enterprise.zip
ARG NEXTCLOUD_PATCH=https://sunet.drive.sunet.se/index.php/s/4erRieGXp8rCKdM/download/mfa_verified.patch
ARG FILE_ACCESS_CONTROL=https://github.com/nextcloud-releases/files_accesscontrol/releases/download/v1.16.0/files_accesscontrol-v1.16.0.tar.gz
ARG MFA_ZONES=https://github.com/pondersource/mfazones/blob/main/release/mfazones.tar.gz?raw=true

RUN rm --recursive --force /var/www/html
USER www-data

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .
# $RANDOM returns random number each time.
ARG CACHEBUST="default"

RUN wget --quiet "${NEXTCLOUD_SERVER}"
RUN wget --quiet "${NEXTCLOUD_PATCH}"

RUN unzip -qq nextcloud-26.0.1-enterprise.zip
RUN mv nextcloud html
RUN cd html && patch -p1 < ../mfa_verified.patch

WORKDIR /var/www/html/apps

RUN wget --quiet "${FILE_ACCESS_CONTROL}"
RUN wget --quiet "${MFA_ZONES}"
RUN tar -xvzf ./files_accesscontrol-v1.16.0.tar.gz && rm ./files_accesscontrol-v1.16.0.tar.gz
RUN tar -xvzf ./mfazones.tar.gz?raw=true && rm ./mfazones.tar.gz?raw=true

USER root
WORKDIR /var/www/html

# switch php version for Nextloud.
RUN switch-php.sh 8.2

ENV PHP_MEMORY_LIMIT="512M"

USER www-data
# this file can be overrided in docker run or docker compose.yaml. 
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init-nextcloud-mfa.sh /init.sh
RUN mkdir --parents data ; touch data/nextcloud.log

USER root
CMD /usr/sbin/apache2ctl -DFOREGROUND & tail --follow /var/log/apache2/error.log & tail --follow data/nextcloud.log
