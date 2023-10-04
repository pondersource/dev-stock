FROM pondersource/dev-stock-php-base

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource Nextcloud SUNET Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

RUN rm --recursive --force /var/www/html
USER www-data

ARG REPO_NEXTCLOUD=https://github.com/pondersource/server.git
ARG BRANCH_NEXTCLOUD=sunet-dev
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

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
# master branch is currently only for NC 28
RUN git clone https://github.com/nextcloud/files_accesscontrol --depth 1 --branch master apps/files_accesscontrol
RUN composer install --working-dir=/var/www/html/apps/files_accesscontrol --no-dev --prefer-dist

RUN git clone https://github.com/nextcloud/user_saml --depth 1 --branch master apps/user_saml
RUN composer install --working-dir=/var/www/html/apps/user_saml --no-dev --prefer-dist

ARG REPO_SOLID=https://github.com/pondersource/mfazones
ARG BRANCH_SOLID=main
RUN git clone                     \
    --depth 1                     \
    --branch ${BRANCH_SOLID}      \
    ${REPO_SOLID}                 \
    apps/mfazones
# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .
# $RANDOM returns random number each time.
ARG CACHEBUST="default"
RUN cd apps/mfazones && git pull
RUN composer install --working-dir=/var/www/html/apps/mfazones --no-dev --prefer-dist
    
# this file can be overrided in docker run or docker compose.yaml. 
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init-nextcloud-sunet.sh /init.sh


RUN mkdir -p data ; touch data/nextcloud.log

USER root
CMD /usr/sbin/apache2ctl -DFOREGROUND & tail --follow /var/log/apache2/access.log & tail --follow /var/log/apache2/error.log & tail --follow data/nextcloud.log