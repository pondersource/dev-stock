# stage 1: build stage
FROM golang:1.22.1-bookworm@sha256:d996c645c9934e770e64f05fc2bc103755197b43fd999b3aa5419142e1ee6d78 AS build

ENV CGO_ENABLED=1

RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --assume-yes         \
    git                                                                                         \
    bash                                                                                        \
    make                                                                                        \
    build-essential                                                                             \
    libsqlite3-dev

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
FROM debian:bookworm@sha256:aadf411dc9ed5199bc7dab48b3e6ce18f8bbee4f170127f5ff1b75cd8035eb36

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="Pondersource Revad Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

# set the timezone and install CA certificates.
RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --assume-yes         \
    bash                                                                                        \
    curl                                                                                        \
    tzdata                                                                                      \
    iproute2                                                                                    \
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
