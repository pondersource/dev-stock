#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------------
# Function: resolve_script_dir
# Purpose : Resolves the absolute path of the script's directory, handling symlinks.
# Returns :
#   Exports SOURCE, SCRIPT_DIR
# Note    : This function relies on BASH_SOURCE, so it must be used in a Bash shell.
# -----------------------------------------------------------------------------------
resolve_script_dir() {
    local source="${BASH_SOURCE[0]}"

    # Follow symbolic links until we get the real file location
    while [ -L "${source}" ]; do
        # Get the directory path where the symlink is located
        dir="$(cd -P "$(dirname "${source}")" >/dev/null 2>&1 && pwd)"
        # Use readlink to get the target the symlink points to
        source="$(readlink "${source}")"
        # If the source was a relative symlink, convert it to an absolute path
        [[ "${source}" != /* ]] && source="${dir}/${source}"
    done

    # After resolving symlinks, retrieve the directory of the final source
    SCRIPT_DIR="$(cd -P "$(dirname "${source}")" >/dev/null 2>&1 && pwd)"

    # Exports
    export SOURCE="${source}"
    export SCRIPT_DIR="${SCRIPT_DIR}"
}

# -----------------------------------------------------------------------------------
# Function: initialize_environment
# Purpose :
#   1) Resolve the script's directory.
#   2) Change into that directory plus an optional subdirectory (if provided).
#   3) Export ENV_ROOT as the new working directory.
#
# Arguments:
#   1) $1 - Relative or absolute path to a subdirectory (optional).
#           If omitted or empty, defaults to '.' (the same directory as resolve_script_dir).
#
# Usage Example:
#   initialize_environment        # Uses the script's directory
#   initialize_environment "dev"  # Changes to script's directory + "/dev"
# -----------------------------------------------------------------------------------
initialize_environment() {
    # Resolve script's directory
    resolve_script_dir

    # Local variables
    local subdir
    # Check if a subdirectory argument was passed; default to '.' if not
    subdir="${1:-.}"

    # Attempt to change into the resolved directory + the subdirectory
    if cd "${SCRIPT_DIR}/${subdir}"; then
        ENV_ROOT="$(pwd)"
        export ENV_ROOT
    else
        printf "Error: %s\n" "Failed to change directory to '${SCRIPT_DIR}/${subdir}'." >&2 && exit 1
    fi
}

require() {
    local name="$1"
    local path="$MODULES_DIR/$name"
    if [[ -f $path ]]; then
        # shellcheck source=/dev/null
        source "$path"
    else
        echo "Module '$name' not found in $MODULES_DIR" >&2
        exit 1
    fi
}

# -----------------------------------------------------------------------------------
# Function: main
# Purpose: Main function to manage the flow of the script.
# -----------------------------------------------------------------------------------
main() {
    initialize_environment "../.."

    MODULES_DIR="${ENV_ROOT}/scripts/utils/github"

    # Foundation
    require log.sh
    require fs.sh

    # Domain logic
    require cli.sh
    require gh.sh
    require video.sh
    require artifact.sh

    parse_cli "$@"

    info "Repository      : $REPO"
    info "Commit SHA      : $COMMIT_SHA"
    info "Output dir      : $OUTDIR"
    info "Workflows (${#WORKFLOWS[@]}) : ${WORKFLOWS[*]}"

    _timer_start
    ensure_dir "$OUTDIR"
    WORKDIR=$(mk_tmp)
    info "Temporary dir   : $WORKDIR"
    _timer_end "Bootstrap"

    for wf in "${WORKFLOWS[@]}"; do
        process_workflow "$REPO" "$wf" "$COMMIT_SHA" "$OUTDIR"
    done

    success "All workflows processed. Artifacts at: $OUTDIR"
}

main "$@"
