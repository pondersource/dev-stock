FROM cypress/included:13.13.1@sha256:e9bb8aa3e4cca25867c1bdb09bd0a334957fc26ec25239534e6909697efb297e

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource Cypress Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

# Copy test suite files
COPY cypress/ocm-test-suite/ /ocm
