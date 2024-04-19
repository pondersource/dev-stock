#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# create html directory if it doesn't exist.
if [ ! -d /var/www/html ]; then
    mkdir -p /var/www/html
fi

# if /var/www/html has any files in it, do not copy nextcloud files into it.
if [ -n "$(find /var/www/html -prune -empty -type d 2>/dev/null)" ]; then
    echo "/var/www/html is an empty directory, populating it with source codes."
    # populate /var/www/html with source codes.
    cp -arn /var/www/source/* /var/www/html
else
    ls -lsa /var/www/html
    echo "/var/www/html contains files, doing noting."
fi

# fix permissions.
chown -R www-data:root /var/www && chmod -R g=u /var/www

# update OS certificate store.
mkdir -p /tls

[ -d "/certificates" ] &&                                                             \
  cp -f /certificates/*.crt                   /tls/                                   \
  &&                                                                                  \
  cp -f /certificates/*.key                   /tls/

[ -d "/certificate-authority" ] &&                                                    \
  cp -f /certificate-authority/*.crt          /tls/                                   \
  &&                                                                                  \
  cp -f /certificate-authority/*.key          /tls/

cp -f /tls/*.crt                             /usr/local/share/ca-certificates/ || true
update-ca-certificates

# This will exec the CMD from your Dockerfile, i.e. "npm start"
exec "$@"
