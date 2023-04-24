FROM node
RUN apt update && apt install -y vim
RUN git clone https://github.com/pondersource/ocm-stub
WORKDIR /ocm-stub
RUN git checkout main
# Trust all the certificates:
ADD ./tls /tls
RUN cp /tls/*.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates
RUN npm install
CMD NODE_TLS_REJECT_UNAUTHORIZED=0 node stub.js