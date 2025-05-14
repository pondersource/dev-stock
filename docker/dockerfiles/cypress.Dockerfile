FROM cypress/included:14.3.3@sha256:a33b6befcef4ce52056acd312461eabf6c3288a2fc24efb544054d306bc598de

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource Cypress Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

# Copy test suite files
COPY cypress/ocm-test-suite/ /ocm
