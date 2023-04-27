FROM php-base

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="Pondersource ownCloud Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

RUN rm --recursive --force /var/www/html

USER www-data
RUN git clone --depth=1 --recursive --shallow-submodules --branch ocm-via-sciencemesh https://github.com/pondersource/core.git html

USER root
WORKDIR /var/www/html

# switch php version for ownCloud.
RUN switch-php.sh 7.4

RUN curl -sS https://getcomposer.org/installer -o /root/composer-setup.php
RUN php /root/composer-setup.php --install-dir=/usr/local/bin --filename=composer

# install nodejs and yarn.
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN apt install nodejs
RUN npm install --global yarn

USER www-data

RUN composer install --no-dev
RUN make install-nodejs-deps

ENV PHP_MEMORY_LIMIT="512M"

ADD init-owncloud.sh /init.sh
RUN mkdir --parent data ; touch data/owncloud.log

USER root
CMD /usr/sbin/apache2ctl -DFOREGROUND & tail --follow /var/log/apache2/error.log & tail --follow data/owncloud.log
