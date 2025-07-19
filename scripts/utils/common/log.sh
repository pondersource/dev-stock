#!/usr/bin/env bash

# shellcheck shell=bash disable=SC2034,SC2155
set -euo pipefail

# colour palette
readonly _CLR_RESET="\033[0m"
readonly _CLR_INFO="\033[1;34m"      # bright blue
readonly _CLR_WARN="\033[1;33m"      # bright yellow
readonly _CLR_ERROR="\033[1;31m"     # bright red
readonly _CLR_SUCCESS="\033[1;32m"   # bright green
readonly _CLR_DEBUG="\033[1;90m"    # dim gray

# core logger
_log() {
    local _level=$1; shift
    local _msg="$*"
    local _stamp
    _stamp=$(date +"%Y-%m-%d %H:%M:%S")

    # example: INFO _CLR_INFO
    local _clr_var="_CLR_${_level^^}"
    # shellcheck disable=SC2086
    printf "%s %b%-7s%b %s\n" "${_stamp}" "${!_clr_var}" "${_level}" "${_CLR_RESET}" "${_msg}"
}

info()    { _log INFO    "$*"; }
warn()    { _log WARN    "$*"; }
error()   { _log ERROR   "$*"; }
success() { _log SUCCESS "$*"; }

debug() {
    [[ ${VERBOSE:-0} -eq 1 ]] && _log DEBUG "$*" || true
}

# timing helpers
_timer_start() { TIMER_START=${SECONDS:-0}; }
_timer_end()   {
    local _op="$1"
    local _elapsed=$(( SECONDS - TIMER_START ))
    info "${_op} finished in ${_elapsed}s"
}
