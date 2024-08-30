FROM pondersource/php-base:8.3

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource Nextcloud Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

# remove html directory and recreate it with correct permissions
RUN rm -rf /var/www/html && mkdir /var/www/html
RUN chown -R www-data:www-data /var/www/html
RUN chmod -R 775 /var/www/html

WORKDIR /var/www/html

USER www-data

ARG REPO_NEXTCLOUD=https://github.com/nextcloud/server
ARG BRANCH_NEXTCLOUD=v28.0.7
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
    .

USER root

ENV PHP_MEMORY_LIMIT="512M"

RUN curl --silent --show-error https://getcomposer.org/installer -o /root/composer-setup.php
RUN php /root/composer-setup.php --install-dir=/usr/local/bin --filename=composer

USER www-data
# this file can be overrided in docker run or docker compose.yaml.
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init/nextcloud.sh /init.sh
RUN mkdir -p data; touch data/nextcloud.log

USER root
CMD /usr/sbin/httpd -DFOREGROUND & tail -f /var/log/apache2/access.log & tail -f /var/log/apache2/error.log & tail -f data/nextcloud.log
