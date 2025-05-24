ARG REVA_BRANCH=v1.28.0

FROM pondersource/revad-base:${REVA_BRANCH}

# ----------------------------------------------------------------------------
# OCI Image Metadata
# ----------------------------------------------------------------------------
# Provide metadata that describes this image, its source, and authorship.
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.title="Pondersource Revad Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

# Copy configuration files for revad into the container.
# These configurations will control revad behavior at runtime.
COPY ./configs/revad /configs/revad
