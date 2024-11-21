FROM php:8.3.13-zts-alpine3.20@sha256:e53b96684f35685cd2a2f2f5326187e9130cc56958757121b2e52149a1eebaf4

# Setup apache and php
RUN apk --no-cache --update add                         \
    git                                                 \
    curl                                                \
    apache2                                             \
    apache2-ssl
