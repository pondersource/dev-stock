FROM php:8.2-rc-apache-bullseye

# keys for oci taken from:
# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.title="PonderSource SUNET Image"
LABEL org.opencontainers.image.source="https://github.com/pondersource/dev-stock"
LABEL org.opencontainers.image.authors="Mohammad Mahdi Baghbani Pourvahid"

# set timezone.
ENV TZ=UTC
RUN ln --symbolic --no-dereference --force /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV DEBIAN_FRONTEND noninteractive

# Set Nextcloud download url here
ARG nc_download_url=https://download.nextcloud.com/.customers/server/26.0.7-153512ec/nextcloud-26.0.7-enterprise.zip

# Set app versions here
ARG announcementcenter_version=6.6.2
ARG calendar_version=4.5.1
ARG checksum_version=1.2.2
ARG collectives_version=2.7.1
ARG contacts_version=5.4.2
ARG drive_email_template_version=1.0.0
ARG files_accesscontrol_version=1.16.2
ARG files_automatedtagging_version=1.16.1
ARG forms_version=3.3.1
ARG integration_excalidraw_version=2.0.3
ARG login_notes_version=1.2.0
ARG loginpagebutton_version=1.0.0
ARG maps_version=1.1.1
ARG polls_version=5.3.2
ARG richdocuments_version=8.0.4
ARG sciencemesh_version=0.5.0
ARG tasks_version=0.15.0
ARG theming_customcss_version=1.14.0
ARG twofactor_admin_version=4.3.0
ARG twofactor_webauthn_version=1.2.0
ARG user_saml_version=5.2.2

# Set environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_DOCUMENT_ROOT /var/www/html
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2

# Pre-requisites for the extensions
RUN set -ex; \
  apt-get -q update > /dev/null && apt-get -q install -y \
  build-essential \
  freetype* \
  libgmp* \
  libicu* \
  libldap* \
  libmagickwand* \
  libmemcached* \
  libpng* \
  libpq* \
  libweb* \
  libzip* \
  npm \
  zlib* \
  curl \
  gnupg2 \
  make \
  iproute2 \
  mariadb-client \
  npm \
  patch \
  redis-tools \
  ssl-cert \
  unzip \
  vim \
  wget > /dev/null

# PECL Modules
RUN pecl -q install apcu \
  imagick \
  memcached \
  redis > /dev/null

# Adjusting freetype message error
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp

# PHP Extensions needed
RUN docker-php-ext-install -j "$(nproc)" \
  bcmath \
  bz2 \
  exif \
  gd \
  gmp \
  intl \
  ldap \
  opcache \
  pcntl \
  pdo_mysql \
  pdo_pgsql \
  sysvsem \
  zip

# More extensions
RUN docker-php-ext-enable \
  imagick \
  apcu \
  memcached \
  redis

# Enabling Modules
RUN a2enmod dir env headers mime rewrite setenvif deflate ssl

# Adjusting PHP settings
RUN { \
  echo 'opcache.interned_strings_buffer=32'; \
  echo 'opcache.memory_consumption=256'; \
  echo 'opcache.save_comments=1'; \
  echo 'opcache.revalidate_freq=60'; \
  } > /usr/local/etc/php/conf.d/opcache-recommended.ini;

RUN { \
  echo 'extension=apcu.so'; \
  echo 'apc.enable_cli=1'; \
  } > /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini;

RUN { \
  echo 'memory_limit = 2G'; \
  echo 'upload_max_filesize=30G'; \
  echo 'post_max_size=30G'; \
  echo 'max_execution_time=86400'; \
  echo 'max_input_time=86400'; \
  } > /usr/local/etc/php/conf.d/nce.ini;

# Update apache configuration for ServerName
RUN echo "ServerName localhost" | tee /etc/apache2/conf-available/servername.conf \
  && a2enconf servername

RUN sed 's/^ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf
RUN sed 's/^ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf

# Set permissions to allow non-root user to access necessary folders
RUN chmod -R 777 ${APACHE_RUN_DIR} ${APACHE_LOCK_DIR} ${APACHE_LOG_DIR} ${APACHE_DOCUMENT_ROOT}

# Should be no need to modify beyond this point, unless you need to patch something or add more apps
RUN wget -q https://downloads.rclone.org/rclone-current-linux-amd64.deb \
  && dpkg -i ./rclone-current-linux-amd64.deb \
  && rm ./rclone-current-linux-amd64.deb && rm -rf /var/lib/apt/lists/*

COPY --chown=root:root ./sunet/000-default.conf /etc/apache2/sites-available/
COPY --chown=root:root ./sunet/cron.sh /cron.sh

## DONT ADD STUFF BETWEEN HERE
RUN wget -q ${nc_download_url} -O /tmp/nextcloud.zip && cd /tmp && unzip -qq /tmp/nextcloud.zip && cd /tmp/nextcloud \
  && mkdir -p /var/www/html/data && touch /var/www/html/data/.ocdata && mkdir /var/www/html/config \
  && cp -a /tmp/nextcloud/* /var/www/html && cp -a /tmp/nextcloud/.[^.]* /var/www/html \
  && chown -R www-data:root /var/www/html && chmod +x /var/www/html/occ && rm -rf /tmp/nextcloud
RUN php /var/www/html/occ integrity:check-core
## AND HERE, OR CODE INTEGRITY CHECK MIGHT FAIL, AND IMAGE WILL NOT BUILD

## VARIOUS PATCHES COMES HERE IF NEEDED

# This patch for the MFAVerified WorkFlow Check is no longer needed but the COPY dist lines below still are.
# See https://github.com/pondersource/nextcloud-mfa-awareness/issues/107#issuecomment-1882591600
# COPY ./sunet/40235.diff /var/www/html/40235.diff
# RUN cd /var/www/html/ && patch -p 1 < 40235.diff

COPY ./sunet/workflowengine-workflowengine.js /var/www/html/dist/workflowengine-workflowengine.js
COPY ./sunet/workflowengine-workflowengine.js.map /var/www/html/dist/workflowengine-workflowengine.js.map

COPY ./sunet/39411.diff /var/www/html/39411.diff
RUN cd /var/www/html/ && patch -p 1 < 39411.diff

COPY ./sunet/512b0a7c52640c9da8905e52fc906e72.patch /var/www/html
RUN cd /var/www/html/ && patch -p 1 < 512b0a7c52640c9da8905e52fc906e72.patch && rm 512b0a7c52640c9da8905e52fc906e72.patch 39411.diff

## INSTALL APPS
RUN mkdir /var/www/html/custom_apps
RUN wget -q https://github.com/nextcloud-releases/announcementcenter/releases/download/v${announcementcenter_version}/announcementcenter-v${announcementcenter_version}.tar.gz  -O /tmp/announcementcenter.tar.gz \
  && cd /tmp && tar xf /tmp/announcementcenter.tar.gz && mv /tmp/announcementcenter /var/www/html/custom_apps/
RUN wget -q https://github.com/nextcloud-releases/calendar/releases/download/v${calendar_version}/calendar-v${calendar_version}.tar.gz -O /tmp/calendar.tar.gz \
  && cd /tmp && tar xf /tmp/calendar.tar.gz && mv /tmp/calendar /var/www/html/custom_apps/
RUN wget -q https://github.com/westberliner/checksum/releases/download/v${checksum_version}/checksum.tar.gz -O /tmp/checksum.tar.gz \
  && cd /tmp && tar xf /tmp/checksum.tar.gz && mv /tmp/checksum /var/www/html/custom_apps/
RUN wget -q https://github.com/nextcloud/collectives/releases/download/v${collectives_version}/collectives-${collectives_version}.tar.gz -O /tmp/collectives.tar.gz \
  && cd /tmp && tar xf /tmp/collectives.tar.gz && mv /tmp/collectives /var/www/html/custom_apps/
RUN wget -q https://github.com/nextcloud-releases/contacts/releases/download/v${contacts_version}/contacts-v${contacts_version}.tar.gz -O /tmp/contacts.tar.gz \
  && cd /tmp && tar xf /tmp/contacts.tar.gz && mv /tmp/contacts /var/www/html/custom_apps/
RUN wget -q https://github.com/nextcloud-releases/files_accesscontrol/releases/download/v${files_accesscontrol_version}/files_accesscontrol-v${files_accesscontrol_version}.tar.gz -O /tmp/files_accesscontrol.tar.gz \
  && cd /tmp && tar xf /tmp/files_accesscontrol.tar.gz && mv /tmp/files_accesscontrol /var/www/html/custom_apps/
RUN wget -q https://github.com/nextcloud-releases/files_automatedtagging/releases/download/v${files_automatedtagging_version}/files_automatedtagging-v${files_automatedtagging_version}.tar.gz -O /tmp/files_automatedtagging.tar.gz \
  && cd /tmp && tar xf /tmp/files_automatedtagging.tar.gz && mv /tmp/files_automatedtagging /var/www/html/custom_apps/
RUN wget -q https://github.com/nextcloud-releases/forms/releases/download/v${forms_version}/forms-v${forms_version}.tar.gz -O /tmp/forms.tar.gz \
  && cd /tmp && tar xf /tmp/forms.tar.gz && mv /tmp/forms /var/www/html/custom_apps/
RUN wget -q https://github.com/nextcloud-releases/integration_excalidraw/releases/download/v${integration_excalidraw_version}/integration_excalidraw-v${integration_excalidraw_version}.tar.gz -O /tmp/integration_excalidraw.tar.gz \
  && cd /tmp && tar xf /tmp/integration_excalidraw.tar.gz && mv /tmp/integration_excalidraw /var/www/html/custom_apps/
RUN wget -q https://packages.framasoft.org/projects/nextcloud-apps/login-notes/login_notes-${login_notes_version}.tar.gz -O /tmp/login_notes.tar.gz \
  && cd /tmp && tar xf /tmp/login_notes.tar.gz && mv /tmp/login_notes /var/www/html/custom_apps/
RUN wget -q https://github.com/SUNET/loginpagebutton/archive/refs/tags/v.${loginpagebutton_version}.tar.gz -O /tmp/loginpagebutton.tar.gz \
  && cd /tmp && tar xf /tmp/loginpagebutton.tar.gz && mv /tmp/loginpagebutton-* /var/www/html/custom_apps/loginpagebutton
RUN wget -q https://github.com/nextcloud/maps/releases/download/v${maps_version}/maps-${maps_version}.tar.gz -O /tmp/maps.tar.gz \
  && cd /tmp && tar xf /tmp/maps.tar.gz && mv /tmp/maps /var/www/html/custom_apps/
RUN wget -q https://github.com/nextcloud/polls/releases/download/v5.2.0/polls.tar.gz -O /tmp/polls.tar.gz \
  && cd /tmp && tar xf /tmp/polls.tar.gz && mv /tmp/polls /var/www/html/custom_apps/
RUN wget -q https://github.com/nextcloud-releases/richdocuments/releases/download/v${richdocuments_version}/richdocuments-v${richdocuments_version}.tar.gz -O /tmp/richdocuments.tar.gz \
  && cd /tmp && tar xf /tmp/richdocuments.tar.gz && mv /tmp/richdocuments /var/www/html/custom_apps
RUN wget -q https://github.com/nextcloud/tasks/releases/download/v${tasks_version}/tasks.tar.gz -O /tmp/tasks.tar.gz \
  && cd /tmp && tar xf /tmp/tasks.tar.gz && mv /tmp/tasks /var/www/html/custom_apps
RUN wget -q https://github.com/juliushaertl/theming_customcss/releases/download/v${theming_customcss_version}/theming_customcss.tar.gz  -O /tmp/theming_customcss.tar.gz \
  && cd /tmp && tar xf /tmp/theming_customcss.tar.gz && mv /tmp/theming_customcss /var/www/html/custom_apps/theming_customcss
RUN wget -q https://github.com/nextcloud-releases/twofactor_webauthn/releases/download/v${twofactor_webauthn_version}/twofactor_webauthn-v${twofactor_webauthn_version}.tar.gz \
  -O /tmp/twofactor_webauthn.tar.gz \
  && cd /tmp && tar xf /tmp/twofactor_webauthn.tar.gz && mv /tmp/twofactor_webauthn /var/www/html/custom_apps
RUN wget -q https://github.com/nextcloud-releases/twofactor_admin/releases/download/v${twofactor_admin_version}/twofactor_admin.tar.gz -O /tmp/twofactor_admin.tar.gz \
  && cd /tmp && tar xf /tmp/twofactor_admin.tar.gz && mv /tmp/twofactor_admin /var/www/html/custom_apps/
RUN wget -q https://github.com/SUNET/drive-email-template/archive/refs/tags/${drive_email_template_version}.tar.gz -O /tmp/drive-email-template.tar.gz \
  && cd /tmp && tar xf /tmp/drive-email-template.tar.gz && mv /tmp/drive-email-template-* /var/www/html/custom_apps/drive_email_template
RUN wget -q https://github.com/sciencemesh/nc-sciencemesh/releases/download/v${sciencemesh_version}-nc/sciencemesh.tar.gz -O /tmp/sciencemesh.tar.gz \
  && cd /tmp && tar xf /tmp/sciencemesh.tar.gz && mv /tmp/sciencemesh /var/www/html/custom_apps/
RUN wget -q https://github.com/pondersource/mfazones/blob/main/release/mfazones.tar.gz?raw=true -O /tmp/mfazones.tar.gz \
  && cd /tmp && tar xf /tmp/mfazones.tar.gz && mv /tmp/mfazones /var/www/html/custom_apps/

## INSTALL OUR APPS
COPY --chown=root:root ./sunet/nextcloud-rds.tar.gz /tmp
RUN cd /tmp && tar xf nextcloud-rds.tar.gz && mv rds/ /var/www/html/custom_apps

## ADD www-data to tty group
RUN usermod -a -G tty www-data

# CLEAN UP
RUN apt remove -y wget curl make npm patch && apt autoremove -y
RUN rm -rf /tmp/*.tar.* && chown -R www-data:root /var/www/html

# trust all the certificates:
COPY ./tls /tls
RUN cp /tls/*.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

# app directory.
WORKDIR /var/www/html

USER www-data

# this file can be overrided in docker run or docker compose.yaml. 
# example: docker run --volume new-init.sh:/init.sh:ro
COPY ./scripts/init-nextcloud-sunet.sh /init.sh
RUN mkdir -p data; touch data/nextcloud.log

USER root

EXPOSE 443

COPY ./sunet/entrypoint.sh /entrypoint.sh
RUN chmod +x /init.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD /usr/sbin/apache2ctl -DFOREGROUND & tail --follow "${APACHE_LOG_DIR}/access.log" & tail --follow "${APACHE_LOG_DIR}/error.log" & tail --follow data/nextcloud.log
