#!/usr/bin/env bash

# @michielbdejong halt on error in docker init scripts.
set -e

# kill running revad.
REVAD_PID=$(pgrep -f "revad" | tail -1) && kill -9 "${REVAD_PID}"
