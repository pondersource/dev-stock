#!/usr/bin/env bash

# shellcheck shell=bash disable=SC2034
set -euo pipefail

# Ensure a directory exists or create if absent
ensure_dir() {
    local _dir=$1
    [[ -d "$_dir" ]] || mkdir -p -- "$_dir"
}

# Create one global workspace that is wiped automatically
mk_tmp() {
    WORKDIR=$(mktemp -d)
    trap 'rm -rf -- "$WORKDIR"' EXIT
    echo "$WORKDIR"
}

# Human readable byte size KiB/MiB/GiB with one decimal
hr_size() {
    local _bytes=${1:-0}
    (( _bytes < 1024 ))       && { printf "%d B"   "${_bytes}"; return; }
    (( _bytes < 1048576 ))    && { printf "%.1f KiB" "$(bc -l <<< "${_bytes}/1024")"; return; }
    (( _bytes < 1073741824 )) && { printf "%.1f MiB" "$(bc -l <<< "${_bytes}/1048576")"; return; }
    printf "%.1f GiB" "$(bc -l <<< "${_bytes}/1073741824")"
}