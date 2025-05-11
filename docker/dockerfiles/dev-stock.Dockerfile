FROM ubuntu:24.04@sha256:72297848456d5d37d1262630108ab308d3e9ec7ed1c3286a32fe09856619a782

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource Dev-Stock Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    jq \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /dev-stock

# Copy test suite files and maintain dev-stock directory structure
COPY dev/ocm-test-suite.sh ./dev/ocm-test-suite.sh
COPY dev/ocm-test-suite/ ./dev/ocm-test-suite/
COPY cypress/ocm-test-suite/ ./cypress/ocm-test-suite/
COPY scripts ./scripts/
COPY docker/configs ./docker/configs/
COPY docker/scripts ./docker/scripts/
COPY docker/tls ./docker/tls/

# Make all scripts executable
RUN find ./dev -type f -name "*.sh" -exec chmod +x {} \; && \
    find ./scripts -type f -name "*.sh" -exec chmod +x {} \; && \
    find ./docker/scripts -type f -name "*.sh" -exec chmod +x {} \;

# Put the scripts on the PATH
RUN ln -s /dev-stock/dev/ocm-test-suite.sh /usr/local/bin/ocm-test-suite
ENTRYPOINT ["/usr/local/bin/ocm-test-suite"]

# Keep the container alive by default, but allow override
# either via --entrypoint or directly invoking
CMD ["sleep", "infinity"]
