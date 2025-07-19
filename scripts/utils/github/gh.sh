#!/usr/bin/env bash
# Requires: GitHub CLI (`gh`) authenticated via token or `gh auth login`.

set -euo pipefail

# Select the single most relevant workflow‑run JSON blob.
#
# Cascade (stop on the first non‑empty match):
#   1. Exact head_sha match (if <commit_sha> supplied, 7/40‑char prefix OK).
#   2. Newest completed run on the current git branch.
#   3. Newest completed run on main.
#   4. Newest completed run overall (safety net).
#
# Usage: gh_get_run <repo> <workflow_file> [<commit_sha>]
gh_get_run() {
    local _repo=$1 _workflow=$2 _sha=${3:-}
    local _api_base="repos/${_repo}/actions/workflows/${_workflow}/runs"
    local _per_page="per_page=50"
    local _status="status=completed"

    # 1. exact head_sha (prefix)
    if [[ -n ${_sha} ]]; then
        local _match
        _match=$(gh api "${_api_base}?${_status}&${_per_page}" \
                 --jq ".workflow_runs[] | select(.head_sha|startswith(\"${_sha}\"))" \
                 | head -n1 || true)
        [[ -n ${_match} ]] && { echo "${_match}"; return 0; }
    fi

    # Detect current branch (empty if not in a git repo).
    local _branch
    _branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

    # Helper: fetch newest run for a given branch slug.
    _get_branch_run() {
        local _b=$1
        gh api "${_api_base}?branch=${_b}&${_status}&per_page=1" --jq '.workflow_runs[0]' 2>/dev/null || true
    }

    # 2. newest run on current branch
    if [[ -n ${_branch} && ${_branch} != "HEAD" ]]; then
        local _cur
        _cur=$(_get_branch_run "${_branch}")
        [[ -n ${_cur} && ${_cur} != "null" ]] && { echo "${_cur}"; return 0; }
    fi

    # 3. newest run on main
    local _main
    _main=$(_get_branch_run "main")
    [[ -n ${_main} && ${_main} != "null" ]] && { echo "${_main}"; return 0; }

    # 4. newest run overall (fallback)
    gh api "${_api_base}?${_status}&per_page=1" --jq '.workflow_runs[0]'
}

# Echo run‑ID only (helper)
gh_get_run_id() { gh_get_run "$@" | jq -r '.id'; }

# List artifacts for a run.
# Yields: "<id> <name> <size_bytes>"
gh_get_artifacts() {
    local _repo=$1 _run=$2
    gh api "repos/${_repo}/actions/runs/${_run}/artifacts" \
        --jq '.artifacts[] | "\(.id) \(.name) \(.size_in_bytes // 0)"'
}

# Download artifact ZIP to a directory and echo the destination path.
# Usage: gh_download_artifact <repo> <artifact_id> <dest_dir>
gh_download_artifact() {
    local _repo=$1 _art_id=$2 _dest_dir=$3
    ensure_dir "${_dest_dir}"
    local _out="${_dest_dir}/artifact-${_art_id}.zip"
    gh api "repos/${_repo}/actions/artifacts/${_art_id}/zip" >"${_out}"
    echo "${_out}"
}