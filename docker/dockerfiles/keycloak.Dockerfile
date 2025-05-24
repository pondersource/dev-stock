ARG KEYCLOAK_TAG=26.2.4

FROM quay.io/keycloak/keycloak:${KEYCLOAK_TAG} AS builder

COPY ./configs/cernbox/keycloak.json /tmp/keycloak.json

# Import the realm non-interactive
RUN /opt/keycloak/bin/kc.sh import --file /tmp/keycloak.json --override true
# Pre-compile
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:${KEYCLOAK_TAG}

# Bring in the built /opt/keycloak directory
COPY --from=builder /opt/keycloak /opt/keycloak

# Copy TLS certificates from the host and trust them.
# This ensures Keycloak can serve HTTPS or verify other services.
COPY ./tls/certificates/idp* /tls/
COPY ./tls/certificate-authority/* /tls/

# Default command: already contains myrealm; no more flags needed
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start","--optimized","--verbose"]
