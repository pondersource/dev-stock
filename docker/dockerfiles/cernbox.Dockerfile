FROM alpine:3.21.3@sha256:a8560b36e8b8210634f77d9f7f9efd7ffa463e380b75e2e74aff4511df3ef88c AS builder

WORKDIR /build

# Tools needed only during build
RUN apk add --no-cache ca-certificates sed gzip tar

# Copy the combined web/cernbox bundle
COPY ./configs/cernbox/nginx/cernbox-web-bundle.tgz .

# Copy host‑provided trust anchors
COPY tls/certificates/cernbox* tls/certificate-authority/* /usr/local/share/ca-certificates/

# Update CA trust store
RUN update-ca-certificates

# Extract bundle, patch resource URLs, and re‑compress optimised artefacts
RUN tar -xzf cernbox-web-bundle.tgz \
 && cd web/js \
 && sed -i 's|sciencemesh\.cesnet\.cz/iop|meshdir.docker|' web-app-science*mjs \
 && rm web-app-science*mjs.gz \
 && gzip web-app-science*mjs

FROM nginx:1.27.5-alpine3.21-slim@sha256:b947b2630c97622793113555e13332eec85bdc7a0ac6ab697159af78942bb856

# ----------------------------------------------------------------------------
# OCI Image Metadata
# ----------------------------------------------------------------------------
# Provide metadata that describes this image, its source, and authorship.
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.title="Pondersource CERNBox Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

# Copy TLS certificates from the host and trust them.
# This ensures revad can serve HTTPS or verify other services.
COPY --chown=nginx:nginx ./tls/certificates/cernbox* /tls/
COPY --chown=nginx:nginx ./tls/certificate-authority/* /tls/

# Trust the CA bundle produced in the build stage
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Static assets from the extracted bundle
COPY --from=builder --chown=nginx:nginx /build/web /var/www/web
COPY --from=builder --chown=nginx:nginx /build/cernbox /var/www/cernbox

# Web‑UI runtime configuration
COPY --chown=nginx:nginx ./configs/cernbox/nginx/web-ui-config.json /var/www/web/config.json

# nginx config template
COPY --chown=nginx:nginx ./configs/cernbox/nginx/mime.types /etc/nginx/mime.types
COPY --chown=nginx:nginx ./configs/cernbox/nginx/nginx.conf /etc/nginx/templates/cernbox.conf.template
COPY --chown=nginx:nginx ./configs/cernbox/nginx/cernbox.sh /docker-entrypoint.d/cernbox.sh
