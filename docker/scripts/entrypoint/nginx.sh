#!/bin/sh

# @michielbdejong halt on error in docker init scripts.
set -e

entrypoint_log() {
    if [ -z "${NGINX_ENTRYPOINT_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

# copy self signed certificates to /tls and create symbolic link to correct server certificate for this container.
mkdir -p /tls

[ -d "/certificates" ] &&                                                             \
  cp -f /certificates/*.crt                   /tls/                                   \
  &&                                                                                  \
  cp -f /certificates/*.key                   /tls/

[ -d "/certificate-authority" ] &&                                                    \
  cp -f /certificate-authority/*.crt          /tls/                                   \
  &&                                                                                  \
  cp -f /certificate-authority/*.key          /tls/

ln -sf "/tls/${HOST}.crt" /tls/server.crt
ln -sf "/tls/${HOST}.key" /tls/server.key

if [ "$1" = "nginx" ] || [ "$1" = "nginx-debug" ]; then
    if /usr/bin/find "/docker-entrypoint.d/" -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | read v; then
        entrypoint_log "$0: /docker-entrypoint.d/ is not empty, will attempt to perform configuration"

        entrypoint_log "$0: Looking for shell scripts in /docker-entrypoint.d/"
        find "/docker-entrypoint.d/" -follow -type f -print | sort -V | while read -r f; do
            case "$f" in
                *.envsh)
                    if [ -x "$f" ]; then
                        entrypoint_log "$0: Sourcing $f";
                        . "$f"
                    else
                        # warn on shell scripts without exec bit
                        entrypoint_log "$0: Ignoring $f, not executable";
                    fi
                    ;;
                *.sh)
                    if [ -x "$f" ]; then
                        entrypoint_log "$0: Launching $f";
                        "$f"
                    else
                        # warn on shell scripts without exec bit
                        entrypoint_log "$0: Ignoring $f, not executable";
                    fi
                    ;;
                *) entrypoint_log "$0: Ignoring $f";;
            esac
        done

        # @MahdiBaghbani: I have to do some shenanigans here! sorry nginx.
        entrypoint_log "@MahdiBaghbani: overriding some stuff :D keep calm!"
        rm /etc/nginx/nginx.conf
        mv /etc/nginx/conf.d/server.conf /etc/nginx/nginx.conf
        /docker-entrypoint.d/30-tune-worker-processes.sh

        entrypoint_log "$0: Configuration complete; ready for start up"
    else
        entrypoint_log "$0: No files found in /docker-entrypoint.d/, skipping configuration"
    fi
fi

# @MahdiBaghbani: we need this to check if a port is open in container. and I don't want to create another docker image for nginx -_-
entrypoint_log "@MahdiBaghbani: installing ss command!"
apk add --no-cache iproute2-ss

exec "$@"
