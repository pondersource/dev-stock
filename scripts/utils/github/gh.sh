#!/usr/bin/env bash
# Requires: GitHub CLI (`gh`) authenticated via token or `gh auth login`.

set -euo pipefail

# Return the JSON blob for the most relevant workflow run.
# Usage: gh_get_run <repo> <workflow_file> [<commit_sha>]
# If <commit_sha> is provided, tries to match first 7/40‑char prefix.
# Falls back to the latest run when nothing matches.
gh_get_run() {
    local _repo=$1 _workflow=$2 _sha=${3:-}
    local _api="repos/${_repo}/actions/workflows/${_workflow}/runs?per_page=20"
    local _filter='.workflow_runs[0]'
    if [[ -n $_sha ]]; then
        _filter=".workflow_runs[] | select(.head_sha|startswith(\"${_sha}\")) | ."
    fi
    gh api "${_api}" --jq "${_filter}"
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