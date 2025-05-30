ARG REVA_BRANCH=v1.28.0

FROM pondersource/revad-base:${REVA_BRANCH}

# ----------------------------------------------------------------------------
# OCI Image Metadata
# ----------------------------------------------------------------------------
# Provide metadata that describes this image, its source, and authorship.
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.title="Pondersource Revad CERNBox Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

# Copy configuration files for revad into the container.
# These configurations will control revad behavior at runtime.
COPY ./configs/cernbox /configs/revad


# the following is a workaround for the reva localfs storage driver, 
# which currently expects this path, taken from Giuseppe @glpatcern:
# https://github.com/sciencemesh/dev-stock/blob/b5a1bf263105faf9d2e6d967a2fa78c6b354004a/sciencemesh/scripts/testing-sciencemesh.sh#L144

RUN mkdir /revashares

RUN mkdir -p /revalocalstorage/data/marie/marie
RUN mkdir -p /revalocalstorage/data/einstein/einstein
