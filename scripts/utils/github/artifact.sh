#!/usr/bin/env bash
# Requires: gh, jq, unzip

set -euo pipefail

# Convert workflow filename to a lowercase slug (basename without extension)
_slugify() {
    local _x=$1
    _x="${_x##*/}"
    _x="${_x%.*}"
    echo "${_x,,}"
}

# Fetch, extract, and post-process artifacts for one workflow.
# Arguments: <repo> <workflow_file> <commit_sha> <output_dir>
process_workflow() {
    local _repo=$1 _workflow=$2 _sha=$3 _out=$4

    local _slug _run_id
    _slug=$(_slugify "${_workflow}")

    # Resolve the most relevant run ID
    _run_id=$(gh_get_run_id "${_repo}" "${_workflow}" "${_sha}" || true)
    if [[ -z ${_run_id} || ${_run_id} == "null" ]]; then
        warn "No run found for ${_workflow} @ ${_sha} | skipping"
        return 0
    fi

    info "Workflow ${_workflow}: using run-id ${_run_id}"
    ensure_dir "${_out}/${_slug}"

    # Temporary location for zips
    local _tmp
    _tmp=$(mktemp -d)
    trap 'rm -rf -- "${_tmp}"' RETURN

    # Download & unzip every artifact
    gh_get_artifacts "${_repo}" "${_run_id}" | while read -r _id _name _size; do
        info "↳ downloading artifact ${_name} ($(hr_size ${_size}))"
        local _zip
        _zip=$(gh_download_artifact "${_repo}" "${_id}" "${_tmp}")
        unzip -q -o "${_zip}" -d "${_out}/${_slug}"
    done

    # Post-process all raw videos (skip ones already renamed)
    find "${_out}/${_slug}" -type f -name "*.mp4" ! -name "recording.mp4" -print0 |
        while IFS= read -r -d '' _vid; do
            process_video "${_vid}"
        done

    success "Finished processing ${_workflow}"
}