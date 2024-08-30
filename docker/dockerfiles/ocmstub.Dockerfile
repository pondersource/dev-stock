FROM node

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource OCM Stub Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

WORKDIR /ocmstub

COPY ./scripts/ocmstub/index.js                                           index.js

# trust all the certificates:
COPY ./tls/certificates/meshdir.crt                                       /tls/meshdir.crt
COPY ./tls/certificates/meshdir.key                                       /tls/meshdir.key

# run the app
EXPOSE 443/tcp
CMD NODE_TLS_REJECT_UNAUTHORIZED=0 node stub.js