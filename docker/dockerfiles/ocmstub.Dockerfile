# ----------------------------------------------------------------------------
# Base Image
# ----------------------------------------------------------------------------
# Start from an official Node.js image based on Debian.
# Using a specific Node.js version for stability and reproducibility.
FROM node:23.4.0-bookworm@sha256:0b50ca11d81b5ed2622ff8770f040cdd4bd93a2561208c01c0c5db98bd65d551

# ----------------------------------------------------------------------------
# OCI Image Metadata
# ----------------------------------------------------------------------------
# Provide metadata that describes this image, its source, and authorship.
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.title="PonderSource OCM Stub Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

# ----------------------------------------------------------------------------
# Install Required Packages
# ----------------------------------------------------------------------------
# Update package list and install:
# - iproute2: for network utilities, may assist with debugging inside the container
# - git: required to clone the repository
# Use --no-install-recommends to avoid unnecessary packages and reduce image size.
RUN apt-get update && apt-get install --no-install-recommends --assume-yes \
    git \    
    iproute2 \
    ca-certificates; \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# Build Arguments
# ----------------------------------------------------------------------------
# These allow customizing which repository and branch to clone at build time.
# CACHEBUST is used to force rebuild steps when needed.
ARG OCMSTUB_REPO=https://github.com/cs3org/OCM-stub
ARG OCMSTUB_BRANCH=main
ARG CACHEBUST="default"

# ----------------------------------------------------------------------------
# Clone Repository
# ----------------------------------------------------------------------------
# Clone the specified branch of the OCM stub repository with minimal depth
# to reduce build time and image size. Also fetch submodules if present.
RUN git clone \
    --depth 1 \
    --recursive \
    --shallow-submodules \
    --branch ${OCMSTUB_BRANCH} \
    ${OCMSTUB_REPO} \
    /ocmstub; \
    rm -rf /ocmstub/.git

# After cloning, `git` is no longer needed at runtime, so remove it to reduce image size.
RUN apt-get purge -y git && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# Set Working Directory
# ----------------------------------------------------------------------------
# Set the working directory to the application directory.
WORKDIR /ocmstub

# ----------------------------------------------------------------------------
# Install Dependencies
# ----------------------------------------------------------------------------
# Use npm ci to install dependencies as listed in package-lock.json for reproducibility.
# --production ensures only production dependencies are installed, reducing size.
RUN npm ci --production

# ----------------------------------------------------------------------------
# Expose Ports
# ----------------------------------------------------------------------------
# The application listens on HTTPS port 443.
EXPOSE 443/tcp

# ----------------------------------------------------------------------------
# Runtime Configuration
# ----------------------------------------------------------------------------
# NODE_TLS_REJECT_UNAUTHORIZED=0 allows connections even to self-signed TLS certificates.
# This is helpful for local testing but should not be used in production environments.
ENV NODE_TLS_REJECT_UNAUTHORIZED=0

# ----------------------------------------------------------------------------
# Install TLS Certificates
# ----------------------------------------------------------------------------
# Copy self signed certificates and link them to OS cert directory and update 
# the systems trusted certificates
COPY ./tls/certificates/* /tls/
COPY ./tls/certificate-authority/* /tls/

# ----------------------------------------------------------------------------
# Switch to Non-Root User
# ----------------------------------------------------------------------------
# The base Node image provides a 'node' user. We'll run as 'node' for better security.
RUN chown -R node:root /ocmstub; \
    chmod -R g=u /ocmstub; \
    chown -R node:root /tls; \
    chmod -R g=u /tls; \
    ln --symbolic --force /tls/*.crt /usr/local/share/ca-certificates; \
    update-ca-certificates
USER node

# ----------------------------------------------------------------------------
# Healthcheck
# ----------------------------------------------------------------------------
# Check if the application responds on port 443. Using curl with -k to ignore TLS.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -k -f https://localhost:443 || exit 1


# ----------------------------------------------------------------------------
# Add required scripts
# ----------------------------------------------------------------------------
# Scripts such as entrypoint.sh
COPY ./scripts/ocmstub/*.sh /

# ----------------------------------------------------------------------------
# Startup Command
# ----------------------------------------------------------------------------
# Finally, run the Node.js application defined in stub.js.
ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", "stub.js"]
