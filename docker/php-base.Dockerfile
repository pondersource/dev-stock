FROM ubuntu:22.04

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="Pondersource Base PHP Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

# set timezone.
ENV TZ=UTC
RUN ln --symbolic --no-dereference --force /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV DEBIAN_FRONTEND noninteractive

RUN apt update --yes

# install dependencies.
RUN apt install --yes               \
    git                             \
    curl                            \
    wget                            \
    libxml2                         \
    apt-utils                       \
    libxml2-dev                     \
    lsb-release                     \
    build-essential                 \
    ca-certificates                 \
    apt-transport-https             \
    software-properties-common   

# add the Ondrej PPA, which contains all versions of PHP packages for Ubuntu systems.
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/apache2

RUN apt update --yes

RUN apt install --yes apache2

# install php versions
RUN apt install --yes       \
    php8.2                  \
    php8.2-gd               \
    php8.2-xml              \
    php8.2-zip              \
    php8.2-curl             \
    php8.2-intl             \
    php8.2-mysql            \
    php8.2-xdebug           \
    php8.2-opcache          \
    php8.2-sqlite3          \
    php8.2-mbstring

RUN apt install --yes       \
    php7.4                  \
    php7.4-gd               \
    php7.4-xml              \
    php7.4-zip              \
    php7.4-curl             \
    php7.4-intl             \
    php7.4-json             \
    php7.4-mysql            \
    php7.4-xdebug           \
    php7.4-opcache          \
    php7.4-sqlite3          \
    php7.4-mbstring

# version management.
RUN ln --symbolic --force /usr/bin/php8.2 /usr/bin/php.default
RUN update-alternatives --install /usr/bin/php php /usr/bin/php.default 100

# PHP switcher script.
COPY switch-php.sh /usr/bin/switch-php.sh 
RUN chmod +x /usr/bin/switch-php.sh 

# xdebug configurations.
COPY 20-xdebug.ini /etc/php/7.4/cli/conf.d/20-xdebug.ini
COPY 20-xdebug.ini /etc/php/8.2/cli/conf.d/20-xdebug.ini

# apache config.
COPY site.conf /etc/apache2/sites-enabled/000-default.conf

# trust all the certificates:
ADD tls /tls
RUN cp /tls/*.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates
RUN a2enmod ssl

# app directory.
WORKDIR /var/www
RUN chown www-data:www-data .

EXPOSE 443
CMD ["/usr/sbin/apache2ctl", "-DFOREGROUND"]