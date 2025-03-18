FROM pondersource/nextcloud-base:latest

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource Nextcloud CI Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

# Copy configuration files and scripts
COPY ./scripts/nextcloud/*.sh /
COPY ./scripts/nextcloud/upgrade.exclude /
COPY ./configs/nextcloud/* /usr/src/nextcloud/config/

# Make scripts executable
RUN chmod +x /*.sh

SHELL ["/bin/bash", "-c"]
ENTRYPOINT ["/entrypoint.sh"]
CMD apache2ctl -DFOREGROUND & tail --follow /var/log/apache2/access.log & tail --follow /var/log/apache2/error.log & tail --follow /var/www/html/data/nextcloud.log
