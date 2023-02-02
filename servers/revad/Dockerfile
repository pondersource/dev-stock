FROM ubuntu:22.04
# FROM revadbase as base
# COPY --from=base /etc/ssl/certs/ /etc/ssl/certs/
# COPY --from=base /usr/bin/revad /usr/bin/revad
RUN apt update && apt install -y openssl build-essential wget git vim
RUN wget https://golang.org/dl/go1.19.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf go1.19.linux-amd64.tar.gz
RUN git clone --depth=1 --branch=ocmd-error-messages-backport https://github.com/cs3org/reva
WORKDIR /reva
RUN PATH=$PATH:/usr/local/go/bin make deps
RUN PATH=$PATH:/usr/local/go/bin make build
# see https://github.com/moby/moby/issues/1996#issuecomment-185872769
ARG CACHEBUST=1
RUN git pull
RUN PATH=$PATH:/usr/local/go/bin go mod vendor
RUN PATH=$PATH:/usr/local/go/bin make deps
RUN PATH=$PATH:/usr/local/go/bin make build
# RUN PATH=$PATH:/usr/local/go/bin make test
ADD . /etc/revad
WORKDIR /etc/revad
# RUN openssl req -new -x509 -days 365 -nodes \
#   -out ./server.cert \
#   -keyout ./server.key \
#   -subj "/C=RO/ST=Bucharest/L=Bucharest/O=IT/CN=www.example.ro" \
#   -addext "subjectAltName = DNS:localhost"

# Trust all the certificates:
RUN cp ./tls/*.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates
RUN mkdir -p /var/tmp/reva/
# see https://github.com/golang/go/issues/22846#issuecomment-380809416
RUN echo "hosts: files dns" > /etc/nsswitch.conf
CMD echo "127.0.0.1 $HOST.docker" >> /etc/hosts && /reva/cmd/revad/revad -c /etc/revad/$HOST.toml
