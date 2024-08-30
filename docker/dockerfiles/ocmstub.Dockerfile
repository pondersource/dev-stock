FROM node

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource OCM Stub Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

RUN apt update
RUN apt install -yq iproute2

RUN git clone https://github.com/michielbdejong/ocm-stub /ocmstub
WORKDIR /ocmstub

RUN npm install

# run the app
EXPOSE 443/tcp
CMD NODE_TLS_REJECT_UNAUTHORIZED=0 node stub.js