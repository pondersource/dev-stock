#!/usr/bin/env bash

# shellcheck shell=bash disable=SC2034,SC2155
set -euo pipefail

parse_cli() {
    # defaults
    REPO=""
    COMMIT_SHA=""
    OUTDIR="site/static/artifacts"
    VERBOSE=0
    WORKFLOWS_CSV=""

    # getopt (POSIX long‑only)
    local _TEMP
    _TEMP=$(getopt -o '' -l repo:,commit:,workflows:,outdir:,verbose,help -- "$@") || {
        echo "Try --help" >&2; return 1; }
    eval set -- "${_TEMP}"

    while true; do
        case "$1" in
            --repo)       REPO="$2"; shift 2;;
            --commit)     COMMIT_SHA="$2"; shift 2;;
            --workflows)  WORKFLOWS_CSV="$2"; shift 2;;
            --outdir)     OUTDIR="$2"; shift 2;;
            --verbose)    VERBOSE=1; shift;;
            --help)
                cat <<EOF
Usage: $(basename "$0") [options]
  --repo       owner/name  (defaults to current git remote)
  --commit     SHA         (defaults to HEAD)
  --workflows  CSV list    (defaults to pattern search)
  --outdir     path        (default: site/static/artifacts)
  --verbose                 enable debug logging
EOF
                exit 0;;
            --) shift; break;;
            *)  echo "Unknown option: $1" >&2; exit 1;;
        esac
    done

    # derive defaults when unset
    [[ -z $REPO ]] && REPO=$(git remote get-url origin 2>/dev/null | sed -E 's#.*/([^/]+/[^/.]+)(\.git)?#\1#')
    [[ -z $COMMIT_SHA ]] && COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null)

    # expose as readonly
    readonly REPO COMMIT_SHA OUTDIR VERBOSE

    # workflow list as array
    if [[ -n $WORKFLOWS_CSV ]]; then
        IFS=',' read -r -a WORKFLOWS <<< "$WORKFLOWS_CSV"
    else
        shopt -s nullglob
        WORKFLOWS=( .github/workflows/{login,share-link,share-with,invite-link}-*.yml )
        for i in "${!WORKFLOWS[@]}"; do WORKFLOWS[$i]=$(basename "${WORKFLOWS[$i]}"); done
        shopt -u nullglob
    fi
    readonly -a WORKFLOWS
}
