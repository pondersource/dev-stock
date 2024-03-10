FROM php:8.2-fpm-alpine3.19

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource Base Nextcloud PHP 8.2 FPM Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

# entrypoint.sh and cron.sh dependencies.
RUN set -ex; apk add --no-cache                                                                 \
    git                                                                                         \
    imagemagick                                                                                 \
    rsync                                                                                       \
    ;                                                                                           \
                                                                                                \
    rm /var/spool/cron/crontabs/root;                                                           \
    echo "*/5 * * * * php -f /var/www/html/cron.php" > /var/spool/cron/crontabs/www-data

# install the PHP extensions we need
# see https://docs.nextcloud.com/server/stable/admin_manual/installation/source_installation.html
RUN set -ex; apk add --no-cache --virtual .build-deps                                           \
        $PHPIZE_DEPS                                                                            \
        autoconf                                                                                \
        curl                                                                                    \
        ca-certificates                                                                         \
        freetype-dev                                                                            \
        gmp-dev                                                                                 \
        icu-dev                                                                                 \
        imagemagick-dev                                                                         \
        libevent-dev                                                                            \
        libjpeg-turbo-dev                                                                       \
        libmcrypt-dev                                                                           \
        libmemcached-dev                                                                        \
        libpng-dev                                                                              \
        libwebp-dev                                                                             \
        libxml2-dev                                                                             \
        libzip-dev                                                                              \
        openldap-dev                                                                            \
        pcre-dev                                                                                \
        postgresql-dev                                                                          \
        tzdata                                                                                  \
    ;                                                                                           \
                                                                                                \
    docker-php-ext-configure ftp --with-openssl-dir=/usr;                                       \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp;                        \
    docker-php-ext-configure ldap;                                                              \
    docker-php-ext-install -j "$(nproc)"                                                        \
        bcmath                                                                                  \
        exif                                                                                    \
        ftp                                                                                     \ 
        gd                                                                                      \
        gmp                                                                                     \
        intl                                                                                    \
        ldap                                                                                    \
        opcache                                                                                 \
        pcntl                                                                                   \
        pdo_mysql                                                                               \
        pdo_pgsql                                                                               \
        sysvsem                                                                                 \
        zip                                                                                     \
    ;                                                                                           \
                                                                                                \
    # pecl will claim success even if one install fails, so we need to perform each install separately
    pecl install APCu-5.1.23;                                                                   \
    pecl install imagick-3.7.0;                                                                 \
    pecl install memcached-3.2.0;                                                               \
    pecl install redis-6.0.2;                                                                   \
                                                                                                \
    docker-php-ext-enable                                                                       \
        apcu                                                                                    \
        imagick                                                                                 \
        memcached                                                                               \
        redis                                                                                   \
    ;                                                                                           \
    rm -r /tmp/pear;                                                                            \
                                                                                                \
    runDeps="$(                                                                                 \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions   \
            | tr ',' '\n'                                                                       \
            | sort -u                                                                           \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }'     \
    )";                                                                                         \
    apk add --no-network --virtual .nextcloud-phpext-rundeps $runDeps;                          \
    apk del --no-network .build-deps

# set recommended PHP.ini settings
# see https://docs.nextcloud.com/server/latest/admin_manual/installation/server_tuning.html#enable-php-opcache
ENV PHP_MEMORY_LIMIT 512M
ENV PHP_UPLOAD_LIMIT 512M
RUN {                                                                                           \
        echo 'opcache.enable=1';                                                                \
        echo 'opcache.interned_strings_buffer=32';                                              \
        echo 'opcache.max_accelerated_files=10000';                                             \
        echo 'opcache.memory_consumption=128';                                                  \
        echo 'opcache.save_comments=1';                                                         \
        echo 'opcache.revalidate_freq=60';                                                      \
        echo 'opcache.jit=1255';                                                                \
        echo 'opcache.jit_buffer_size=128M';                                                    \
    } > "${PHP_INI_DIR}/conf.d/opcache-recommended.ini";                                        \
                                                                                                \
    echo 'apc.enable_cli=1' >> "${PHP_INI_DIR}/conf.d/docker-php-ext-apcu.ini";                 \
                                                                                                \
    {                                                                                           \
        echo 'memory_limit=${PHP_MEMORY_LIMIT}';                                                \
        echo 'upload_max_filesize=${PHP_UPLOAD_LIMIT}';                                         \
        echo 'post_max_size=${PHP_UPLOAD_LIMIT}';                                               \
    } > "${PHP_INI_DIR}/conf.d/nextcloud.ini";                                                  \
                                                                                                \
    mkdir /var/www/data;                                                                        \
    mkdir -p /docker-entrypoint-hooks.d/pre-installation                                        \
             /docker-entrypoint-hooks.d/post-installation                                       \
             /docker-entrypoint-hooks.d/pre-upgrade                                             \
             /docker-entrypoint-hooks.d/post-upgrade                                            \
             /docker-entrypoint-hooks.d/before-starting;                                        \
    chown -R www-data:root /var/www;                                                            \
    chmod -R g=u /var/www

ENV TZ=Etc/UTC

VOLUME /var/www/html

# trust all the certificates:
COPY ./tls/certificates/*                                       /tls/
COPY ./tls/certificate-authority/*                              /tls/
RUN ln -sf /tls/*.crt                                           /usr/local/share/ca-certificates
RUN update-ca-certificates

CMD ["php-fpm"]
