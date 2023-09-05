FROM ubuntu:22.04

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="Pondersource Revad Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

# set timezone.
ENV TZ=UTC
RUN ln --symbolic --no-dereference --force /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV DEBIAN_FRONTEND noninteractive

RUN apt update --yes

# install dependencies.
RUN apt install --yes               \
    git                             \
    vim                             \
    curl                            \
    wget                            \
    openssl                         \ 
    build-essential                 \
    ca-certificates                  

# install Go compiler.
ARG GO_VERSION=1.21.0
RUN wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
RUN tar --directory=/usr/local --extract --gzip --file=go${GO_VERSION}.linux-amd64.tar.gz

# update path to include GO bin directory.
ENV PATH="${PATH}:/usr/local/go/bin"

# fetch revad from source.
ARG REPO_REVA=https://github.com/cs3org/reva
ARG BRANCH_REVA=v1.24.0
# CACHEBUST forces docker to clone fresh source codes from git.
# example: docker build -t your-image --build-arg CACHEBUST="default" .
# $RANDOM returns random number each time.
ARG CACHEBUST="default"
RUN git clone                       \
    --depth 1                       \
    --branch ${BRANCH_REVA}         \
    ${REPO_REVA}                    \
    reva

WORKDIR /reva

# build revad from source.
RUN go mod vendor
SHELL ["/bin/bash", "-c"]
# only build revad, leave out reva and test and lint and docs.
RUN make revad

COPY ./revad /etc/revad
WORKDIR /etc/revad

# trust all the certificates:
COPY ./tls /tls
RUN ln --symbolic --force /tls/*.crt /usr/local/share/ca-certificates
RUN update-ca-certificates

# create link for all the tls certificates in the revad tls directory.
RUN mkdir -p /etc/revad/tls
RUN ln --symbolic --force /tls/*.crt /etc/revad/tls
RUN ln --symbolic --force /tls/*.key /etc/revad/tls

RUN mkdir -p /var/tmp/reva/

# update path to include revad bin directory.
ENV PATH="${PATH}:/reva/cmd/revad"

COPY ./scripts/reva-run.sh /usr/bin/reva-run.sh
RUN chmod +x /usr/bin/reva-run.sh

COPY ./scripts/reva-kill.sh /usr/bin/reva-kill.sh
RUN chmod +x /usr/bin/reva-kill.sh

COPY ./scripts/reva-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# Keep Docker Container Running for Debugging.
CMD tail --follow /var/log/revad.log
