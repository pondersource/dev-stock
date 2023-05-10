FROM node:lts-hydrogen

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="Pondersource OCM Stub Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

# set timezone.
ENV TZ=UTC
RUN ln --symbolic --no-dereference --force /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV DEBIAN_FRONTEND noninteractive

RUN apt update --yes

# install dependencies.
RUN apt install --yes               \
    vim                             

# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="$(date +%s)" .
# $RANDOM returns random number each time.
ARG CACHEBUST="$(echo $RANDOM)"
RUN git clone --depth 1 --branch main https://github.com/pondersource/ocm-stub

WORKDIR /ocm-stub

# Trust all the certificates:
ADD ./tls /tls
RUN cp /tls/*.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

RUN npm install

CMD ["NODE_TLS_REJECT_UNAUTHORIZED=0", "node", "stub.js"]
