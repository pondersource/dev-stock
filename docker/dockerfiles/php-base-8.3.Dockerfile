FROM php:8.3.10-zts-alpine3.20

# Setup apache and php
RUN apk --no-cache --update add                         \
    git                                                 \
    curl                                                \
    apache2                                             \
    apache2-ssl
