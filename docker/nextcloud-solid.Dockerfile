FROM pondersource/dev-stock-nextcloud

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="Pondersource Nextcloud Solid Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

USER www-data

ARG REPO_SOLID=https://github.com/pdsinterop/solid-nextcloud
ARG BRANCH_SOLID=main
RUN git clone                     \
    --depth 1                     \
    --branch ${BRANCH_SOLID}      \
    ${REPO_SOLID}                 \
    apps/solid-nextcloud
RUN cd apps/ && ln -s solid-nextcloud/solid
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="$(date +%s)" .
# $RANDOM returns random number each time.
ARG CACHEBUST="$(echo $RANDOM)"
RUN cd apps/solid-nextcloud && git pull
RUN composer install --working-dir=/var/www/html/apps/solid --no-dev --prefer-dist
    
# this file can be overrided in docker run or docker compose.yaml. 
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init-nextcloud-solid.sh /nc-init.sh

USER root
