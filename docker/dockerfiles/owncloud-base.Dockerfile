FROM php:7.4.33-apache-bullseye@sha256:c9d7e608f73832673479770d66aacc8100011ec751d1905ff63fae3fe2e0ca6d

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource ownCloud Base Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Michiel B. de Jong,Mohammad Mahdi Baghbani Pourvahid"

# entrypoint.sh and cron.sh dependencies
RUN set -ex; \
    \
    apt-get update; \
    apt-get install --no-install-recommends --assume-yes \
    git \
    vim \
    curl\
    bzip2 \
    rsync \
    iproute2 \
    busybox-static \
    libldap-common \
    ca-certificates \
    libapache2-mod-security2 \
    libmagickcore-6.q16-6-extra \
    ; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# install the PHP extensions we need
ENV PHP_MEMORY_LIMIT 512M
ENV PHP_UPLOAD_LIMIT 512M
RUN set -ex; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    \
    apt-get update; \
    apt-get install --no-install-recommends --assume-yes \
    libcurl4-openssl-dev \
    libevent-dev \
    libfreetype6-dev \
    libgmp-dev \
    libicu-dev \
    libjpeg-dev \
    libldap2-dev \
    libmagickwand-dev \
    libmcrypt-dev \
    libmemcached-dev \
    libpng-dev \
    libpq-dev \
    libwebp-dev \
    libxml2-dev \
    libzip-dev \
    ; \
    \
    debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-configure ldap --with-libdir="lib/$debMultiarch"; \
    docker-php-ext-install -j "$(nproc)" \
    bcmath \
    exif \
    gd \
    gmp \
    intl \
    ldap \
    opcache \
    pcntl \
    pdo_mysql \
    pdo_pgsql \
    sysvsem \
    zip \
    ; \
    \
    # pecl will claim success even if one install fails, so we need to perform each install separately
    pecl install APCu-5.1.24; \
    pecl install imagick-3.7.0; \
    pecl install memcached-3.3.0; \
    pecl install redis-6.1.0; \
    \
    docker-php-ext-enable \
    apcu \
    imagick \
    memcached \
    redis \
    ; \
    rm -r /tmp/pear; \
    \
    # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
    | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | xargs -rt apt-mark manual; \
    \
    apt-get purge --assume-yes --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

RUN { \
    echo 'SecStatusEngine Off'; \
    echo 'SecRuleEngine On'; \
    echo 'SecAuditEngine On'; \
    echo 'SecAuditLog /var/log/apache2/modsec_audit.log'; \
    echo 'SecRequestBodyAccess on'; \
    echo 'SecResponseBodyAccess On'; \
    echo 'SecAuditLogParts ABIJEFHZ'; \
    } > "/etc/modsecurity/modsecurity.conf";

# set recommended PHP.ini settings
RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.interned_strings_buffer=32'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.save_comments=1'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.jit=1255'; \
    echo 'opcache.jit_buffer_size=128M'; \
    } > "${PHP_INI_DIR}/conf.d/opcache-recommended.ini"; \
    \
    echo 'apc.enable_cli=1' >> "${PHP_INI_DIR}/conf.d/docker-php-ext-apcu.ini"; \
    \
    { \
    echo 'memory_limit=${PHP_MEMORY_LIMIT}'; \
    echo 'upload_max_filesize=${PHP_UPLOAD_LIMIT}'; \
    echo 'post_max_size=${PHP_UPLOAD_LIMIT}'; \
    } > "${PHP_INI_DIR}/conf.d/owncloud.ini"; \
    \
    mkdir /var/www/data; \
    mkdir -p /docker-entrypoint-hooks.d/pre-installation \
    /docker-entrypoint-hooks.d/post-installation \
    /docker-entrypoint-hooks.d/pre-upgrade \
    /docker-entrypoint-hooks.d/post-upgrade \
    /docker-entrypoint-hooks.d/before-starting; \
    chown -R www-data:root /var/www; \
    chmod -R g=u /var/www

VOLUME /var/www/html

COPY ./tls/certificates/* /tls/
COPY ./tls/certificate-authority/* /tls/
RUN ln --symbolic --force /tls/*.crt /usr/local/share/ca-certificates; \
    update-ca-certificates

COPY ./configs/owncloud/apache.conf /etc/apache2/sites-enabled/000-default.conf

RUN a2enmod headers rewrite remoteip ssl log_forensic; \
    { \
    echo 'RemoteIPHeader X-Real-IP'; \
    echo 'RemoteIPInternalProxy 10.0.0.0/8'; \
    echo 'RemoteIPInternalProxy 172.16.0.0/12'; \
    echo 'RemoteIPInternalProxy 192.168.0.0/16'; \
    } > /etc/apache2/conf-available/remoteip.conf; \
    a2enconf remoteip; \
    chown -R www-data:root /var/log/apache2; \
    chmod -R g=u /var/log/apache2

# set apache config LimitRequestBody
ENV APACHE_BODY_LIMIT 1073741824
RUN { \
    echo 'LimitRequestBody ${APACHE_BODY_LIMIT}'; \
    } > /etc/apache2/conf-available/apache-limits.conf; \
    a2enconf apache-limits

RUN curl --silent --show-error https://getcomposer.org/installer -o /root/composer-setup.php
RUN php /root/composer-setup.php --install-dir=/usr/local/bin --filename=composer

# install nodejs and yarn.
RUN curl --silent --location https://deb.nodesource.com/setup_18.x | bash -; \
    apt-get install --no-install-recommends --assume-yes nodejs; \
    npm install --global yarn \
    ; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*
