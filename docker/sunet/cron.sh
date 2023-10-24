#!/usr/bin/env sh
set -eu

exec cron -f -l 0 -L /dev/stdout
