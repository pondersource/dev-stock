FROM node

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource OCM Stub Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

RUN apt update
RUN apt install -yq iproute2 git

ARG REPO_OCMSTUB=https://github.com/pondersource/ocm-stub
ARG BRANCH_OCMSTUB=mahdi/fix-grants
# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .
# $RANDOM returns random number each time.
ARG CACHEBUST="default"
RUN git clone                       \
    --depth 1                       \
    --recursive                     \
    --shallow-submodules            \
    --branch ${BRANCH_OCMSTUB}      \
    ${REPO_OCMSTUB}                 \
    /ocmstub

WORKDIR /ocmstub

RUN npm install

# run the app
EXPOSE 443/tcp
CMD NODE_TLS_REJECT_UNAUTHORIZED=0 node stub.js