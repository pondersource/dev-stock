ARG OWNCLOUD_VERSION=latest
FROM pondersource/owncloud:${OWNCLOUD_VERSION}

# App installation arguments
ARG APP_NAME
ARG APP_REPO
ARG APP_BRANCH=master
ARG APP_BUILD_CMD=""
ARG APP_SOURCE_DIR="/ponder/apps"
ARG INIT_SCRIPT=""
ARG INSTALL_METHOD="git"  # Possible values: "git" or "tarball"
ARG TARBALL_URL=""

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource ownCloud with ${APP_NAME}"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"
LABEL org.opencontainers.image.description="ownCloud image with ${APP_NAME} pre-installed"

USER root

RUN set -ex; \
    \
    apt-get update; \
    apt-get install --no-install-recommends --assume-yes \
    git \
    wget \
    tar

RUN mkdir -p ${APP_SOURCE_DIR}; \
    chown -R www-data:root ${APP_SOURCE_DIR}; \
    chmod -R g=u ${APP_SOURCE_DIR}

USER www-data

# Install the app using either git or tarball method
RUN set -ex; \
    if [ -z "${APP_NAME}" ]; then \
        echo "Error: APP_NAME must be provided"; \
        exit 1; \
    fi; \
    \
    if [ "${INSTALL_METHOD}" = "git" ]; then \
        if [ -z "${APP_REPO}" ]; then \
            echo "Error: APP_REPO must be provided when using git installation method"; \
            exit 1; \
        fi; \
        # Clone the app repository \
        git clone \
            --depth 1 \
            --branch ${APP_BRANCH} \
            ${APP_REPO} \
            ${APP_SOURCE_DIR}/${APP_NAME}; \
        # Update to latest commit \
        cd ${APP_SOURCE_DIR}/${APP_NAME} && git pull; \
    elif [ "${INSTALL_METHOD}" = "tarball" ]; then \
        if [ -z "${TARBALL_URL}" ]; then \
            echo "Error: TARBALL_URL must be provided when using tarball installation method"; \
            exit 1; \
        fi; \
        # Create a temporary directory for extraction \
        mkdir -p ${APP_SOURCE_DIR}/temp && \
        cd ${APP_SOURCE_DIR}/temp && \
        # Download and extract the tarball \
        wget -O ${APP_NAME}.tar.gz ${TARBALL_URL} && \
        tar -xzf ${APP_NAME}.tar.gz && \
        rm ${APP_NAME}.tar.gz && \
        # Find the extracted directory (it should be the only one) \
        EXTRACTED_DIR=$(ls -d */ | head -n 1) && \
        # Move the contents to the correct location with APP_NAME \
        cd .. && \
        mv temp/${EXTRACTED_DIR%/} ${APP_NAME} && \
        rm -rf temp; \
    else \
        echo "Error: Invalid INSTALL_METHOD. Must be either 'git' or 'tarball'"; \
        exit 1; \
    fi; \
    \
    # Run build command if provided \
    if [ -n "${APP_BUILD_CMD}" ]; then \
        cd ${APP_SOURCE_DIR}/${APP_NAME} && \
        ${APP_BUILD_CMD}; \
    fi

USER root

# After installation, cleanup unnecessary packages
RUN apt-get purge -y git wget && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy init script if provided
COPY ${INIT_SCRIPT} "/docker-entrypoint-hooks.d/before-starting/${APP_NAME}.sh"
RUN chmod +x /docker-entrypoint-hooks.d/before-starting/${APP_NAME}.sh
