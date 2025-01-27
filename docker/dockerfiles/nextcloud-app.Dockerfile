ARG NEXTCLOUD_VERSION=latest
FROM pondersource/nextcloud:${NEXTCLOUD_VERSION}

# App installation arguments
ARG APP_NAME
ARG APP_REPO
ARG APP_BRANCH=main
ARG APP_BUILD_CMD=""
ARG APP_SOURCE_DIR="/ponder/apps"
ARG INIT_SCRIPT=""

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource Nextcloud with ${APP_NAME}"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"
LABEL org.opencontainers.image.description="Nextcloud image with ${APP_NAME} pre-installed"

USER root

RUN set -ex; \
    \
    apt-get update; \
    apt-get install --no-install-recommends --assume-yes \
    git

RUN mkdir -p ${APP_SOURCE_DIR}; \
    chown -R www-data:root ${APP_SOURCE_DIR}; \
    chmod -R g=u ${APP_SOURCE_DIR}

USER www-data

# Install the app
RUN set -ex; \
    if [ -z "${APP_NAME}" ] || [ -z "${APP_REPO}" ]; then \
        echo "Error: APP_NAME and APP_REPO must be provided"; \
        exit 1; \
    fi; \
    # Clone the app repository
    git clone \
        --depth 1 \
        --branch ${APP_BRANCH} \
        ${APP_REPO} \
        ${APP_SOURCE_DIR}/${APP_NAME}; \
    # Update to latest commit
    cd ${APP_SOURCE_DIR}/${APP_NAME} && git pull; \
    # Build if build command is provided
    if [ -n "${APP_BUILD_CMD}" ]; then \
        ${APP_BUILD_CMD}; \
    fi

USER root

# After cloning, `git` is no longer needed at runtime, so remove it to reduce image size.
RUN apt-get purge -y git && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*


# Copy init script if provided  
COPY ${INIT_SCRIPT} "/docker-entrypoint-hooks.d/before-starting/${APP_NAME}.sh"
RUN chmod +x /docker-entrypoint-hooks.d/before-starting/${APP_NAME}.sh
