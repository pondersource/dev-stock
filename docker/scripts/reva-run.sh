#!/usr/bin/env bash

# run revad.
revad -c "/etc/revad/${HOST}.toml" -log "${LOG_LEVEL:-debug}" &

