#!/usr/bin/env bash
# Requires: ffmpeg (with libaom‑av1)

set -euo pipefail

# Internal: create one AVIF thumbnail next to the video.
_make_thumbnail() {
    local _video=$1
    local _thumb="${_video%.*}.avif"
    ffmpeg -v quiet -i "${_video}" -vf scale=640:-1 -frames:v 1 \
           -c:v libaom-av1 -still-picture 1 "${_thumb}"
    echo "${_thumb}"
}

# Public API: process a freshly extracted *.mp4
# 1. renames to recording.mp4 in place
# 2. generates thumbnail
process_video() {
    local _input=$1
    local _dir
    _dir=$(dirname "${_input}")
    local _target="${_dir}/recording.mp4"
    mv -f -- "${_input}" "${_target}"
    _make_thumbnail "${_target}" >/dev/null
    success "Processed video => ${_target}"
}
