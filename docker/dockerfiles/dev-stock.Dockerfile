FROM ubuntu:24.04@sha256:72297848456d5d37d1262630108ab308d3e9ec7ed1c3286a32fe09856619a782

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

# Make all scripts executable
RUN find ./dev -type f -name "*.sh" -exec chmod +x {} \; && \
    find ./scripts -type f -name "*.sh" -exec chmod +x {} \; && \
    find ./docker/scripts -type f -name "*.sh" -exec chmod +x {} \;

# Set entrypoint
ENTRYPOINT ["/dev-stock/dev/ocm-test-suite.sh"] 
