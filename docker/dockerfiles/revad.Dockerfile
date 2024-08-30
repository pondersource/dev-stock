# stage 1: build stage
FROM golang:1.22.1-alpine AS build

# install build dependencies.
RUN apk --no-cache add git make bash

# go to root directory.
WORKDIR /

# fetch revad from source.
ARG REPO_REVA=https://github.com/cs3org/reva
ARG BRANCH_REVA=v1.28.0
# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .
# $RANDOM returns random number each time.
ARG CACHEBUST="default"
RUN git clone                       \
    --depth 1                       \
    --branch ${BRANCH_REVA}         \
    ${REPO_REVA}                    \
    reva-git

# change directory to reva git.
WORKDIR /reva-git

# copy and download dependencies.
RUN go mod download

# only build revad, leave out reva and test and lint and docs.
RUN make revad

# stage 2: app image.
FROM alpine:3.19.1

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="Pondersource Revad Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

# set the timezone and install CA certificates.
RUN apk --no-cache add                                          \
    bash                                                        \
    curl                                                        \
    tzdata                                                      \
    ca-certificates

ENV TZ=Etc/UTC

# copy the binary from the build stage.
COPY --from=build /reva-git/cmd                                 /reva-git/cmd

# copy the reva config files from host.
COPY ./configs/revad                                            /configs/revad

# trust all the certificates:
COPY ./tls/certificates/reva*                                   /tls/
COPY ./tls/certificate-authority/*                              /tls/
RUN ln -sf /tls/*.crt                                           /usr/local/share/ca-certificates
RUN update-ca-certificates

RUN mkdir -p /var/tmp/reva/

# update path to include revad bin directory.
ENV PATH="${PATH}:/reva/cmd/revad"

COPY ./scripts/reva/*                                           /usr/bin/

RUN chmod +x /usr/bin/run.sh && chmod +x /usr/bin/kill.sh && chmod +x /usr/bin/entrypoint.sh

ENTRYPOINT ["/usr/bin/entrypoint.sh"]

# keep Docker Container Running for Debugging.
CMD tail -F /var/log/revad.log
