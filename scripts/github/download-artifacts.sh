#!/bin/bash
# download-artifacts.sh
#
# Downloads and processes video artifacts from GitHub Actions test workflows.
# Converts videos to AV1/WebM format and generates AVIF thumbnails.
# Ensures artifacts match a given COMMIT_SHA and generates a manifest for website consumption.
#
# Requirements: gh, jq, ffmpeg, unzip

set -euo pipefail

###########################
# Global Variables & Constants
###########################
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ARTIFACTS_DIR="site/static/artifacts"
readonly IMAGES_DIR="site/static/images"
readonly LOG_FILE="/tmp/artifact-download-$(date +%Y%m%d-%H%M%S).log"

# These files will be initialized in main()
MANIFEST_FILE=""
STATUS_FILE=""

# Global arrays for workflow files and counts
declare -a workflow_files=()
login_count=0
share_count=0
invite_count=0

###########################
# Logging Functions
###########################
log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    printf "[%s] %-7s %s\n" "$timestamp" "$level" "$msg" | tee -a "$LOG_FILE"
}
error()   { log "ERROR" "$*" >&2; }
info()    { log "INFO" "$*"; }
debug()   { [[ "${DEBUG:-0}" == "1" ]] && log "DEBUG" "$*" || true; }
warn()    { log "WARN" "$*" >&2; }
success() { log "SUCCESS" "$*"; }

###########################
# Timer Functions
###########################
start_timer() { timer_start=$(date +%s); }
end_timer() {
    local operation="$1"
    local duration=$(( $(date +%s) - timer_start ))
    info "Operation '$operation' completed in ${duration}s"
}

###########################
# Utility Functions
###########################
human_size() {
    local size="${1:-0}"
    if ((size < 1024)); then
        echo "${size}B"
    elif ((size < 1048576)); then
        echo "$((size/1024))KB"
    else
        echo "$((size/1048576))MB"
    fi
}

sanitize_name() {
    local name="$1"
    echo "$name" | sed -E 's/\.(yml|yaml)$//' | tr '[:upper:]' '[:lower:]'
}

###########################
# Cleanup Function
###########################
cleanup() {
    info "Cleaning up temporary directories..."
    if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        debug "Removed temporary directory: $TEMP_DIR"
    fi
}

###########################
# Dependency Check
###########################
check_dependencies() {
    local missing_deps=()
    for cmd in gh jq ffmpeg unzip; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing_deps[*]}"
        error "Please install these tools before running the script."
        exit 1
    fi
}

###########################
# Video Processing Functions
###########################
# Generates an AVIF thumbnail from the first frame of a video.
generate_thumbnail() {
    local video="$1"
    local thumbnail="${video%.*}.avif"
    if ! ffmpeg -hide_banner -loglevel error -i "$video" \
         -vf "select=eq(n\,0),scale=640:-1" -vframes 1 -c:v libaom-av1 -still-picture 1 "$thumbnail" 2>/dev/null; then
        return 1
    fi
    printf "%s" "$thumbnail"
}

# Processes a single video by generating its thumbnail.
process_video() {
    local input="$1"
    start_timer
    local original_size
    original_size=$(stat -f%z "$input" 2>/dev/null || stat -c%s "$input")
    info "Processing video: $input ($(human_size "$original_size"))"
    
    info "Generating thumbnail for $input"
    local thumbnail_file
    if ! thumbnail_file=$(generate_thumbnail "$input"); then
        error "Failed to generate thumbnail for $input"
        return 1
    fi
    local thumb_size
    thumb_size=$(stat -f%z "$thumbnail_file" 2>/dev/null || stat -c%s "$thumbnail_file")
    success "Generated thumbnail at $thumbnail_file ($(human_size "$thumb_size"))"
    end_timer "Video processing"
}

###########################
# GitHub API Functions
###########################
# Fetches artifacts for a given workflow and processes the contained videos.
fetch_workflow_artifacts() {
    local workflow="$1"
    local workflow_name
    workflow_name=$(sanitize_name "$workflow")
    info "Processing workflow: $workflow_name"
    
    # Fetch runs matching COMMIT_SHA (or fall back to the latest run)
    local runs_json
    debug "Fetching workflow runs for $workflow_name"
    runs_json=$(gh api "repos/pondersource/dev-stock/actions/workflows/$workflow/runs?per_page=20" \
        --jq ".workflow_runs[] | select(.head_sha == \"${COMMIT_SHA}\" or .head_sha == \"${COMMIT_SHA:0:7}\")" | head -n 1) || {
        error "Failed to fetch runs for workflow $workflow"
        return 1
    }
    
    if [[ -z "$runs_json" ]]; then
        warn "No runs found for workflow $workflow with commit ${COMMIT_SHA}, trying latest run instead"
        runs_json=$(gh api "repos/pondersource/dev-stock/actions/workflows/$workflow/runs?per_page=1" \
            --jq ".workflow_runs[0]") || {
            error "Failed to fetch latest run for workflow $workflow"
            return 1
        }
    fi
    
    # Append workflow status to the status file
    echo "$runs_json" | jq --arg name "$workflow" '{
        ($name): {
            name: .name,
            status: .status,
            conclusion: .conclusion
        }
    }' >> "$STATUS_FILE"
    
    # Get the run ID and fetch artifacts
    local run_id
    run_id=$(echo "$runs_json" | jq -r '.id')
    info "Processing run ID: $run_id"
    
    local artifacts_json
    artifacts_json=$(gh api "repos/pondersource/dev-stock/actions/runs/$run_id/artifacts") || {
        error "Failed to fetch artifacts for run $run_id"
        return 1
    }
    
    local workflow_dir="$ARTIFACTS_DIR/$workflow_name"
    mkdir -p "$workflow_dir"
    
    echo "$artifacts_json" | jq -r '.artifacts[] | "\(.id) \(.name) \(.size_in_bytes // 0)"' | while read -r id name size; do
        info "Downloading artifact $name (ID: $id, Size: $(human_size ${size:-0}))"
        TEMP_DIR=$(mktemp -d)
        if gh api "repos/pondersource/dev-stock/actions/artifacts/$id/zip" \
           -H "Accept: application/vnd.github+json" > "$TEMP_DIR/artifact.zip"; then
            if unzip -q -o "$TEMP_DIR/artifact.zip" -d "$workflow_dir"; then
                # Process each MP4 video in the extracted artifact
                find "$workflow_dir" -name "*.mp4" -print0 | while IFS= read -r -d '' video; do
                    process_video "$video"
                    local thumbnail="${video%.mp4}.avif"
                    if [[ -f "$thumbnail" ]]; then
                        local rel_video="${video#site/static/}"
                        local rel_thumbnail="${thumbnail#site/static/}"
                        jq --arg wf "$workflow_name" --arg video "$rel_video" --arg thumb "$rel_thumbnail" \
                           '.videos += [{"workflow": $wf, "video": $video, "thumbnail": $thumb}]' \
                           "$MANIFEST_FILE" > "${MANIFEST_FILE}.tmp" && mv "${MANIFEST_FILE}.tmp" "$MANIFEST_FILE"
                    fi
                done
            else
                error "Failed to extract artifact $id"
            fi
        else
            error "Failed to download artifact $id"
        fi
        rm -rf "$TEMP_DIR"
    done
}

# Fetches the latest workflow status from the GitHub API.
fetch_workflow_status() {
    local workflow="$1"
    local status_json
    status_json=$(gh api "repos/pondersource/dev-stock/actions/workflows/$workflow/runs?branch=main&per_page=1" \
        --jq '{
            name: .workflow_runs[0].name,
            status: .workflow_runs[0].status,
            conclusion: .workflow_runs[0].conclusion
        }') || {
        error "Failed to fetch status for workflow $workflow"
        return 1
    }
    echo "$status_json"
}

###########################
# Manifest Generation
###########################
generate_manifest() {
    info "Generating artifact manifest..."
    local manifest="$ARTIFACTS_DIR/manifest.json"
    local status_file="$ARTIFACTS_DIR/workflow-status.json"
    local temp_status_file="/tmp/temp_status_$$.json"
    local temp_manifest_file="/tmp/temp_manifest_$$.json"
    
    # Initialize temporary JSON files
    echo "{}" > "$temp_status_file"
    echo '{"videos": []}' > "$temp_manifest_file"
    
    for workflow in "${workflow_files[@]}"; do
        # Merge workflow status
        local status
        status=$(fetch_workflow_status "$workflow")
        if [[ -n "$status" ]]; then
            jq --arg name "$workflow" --argjson status "$status" \
               '. + {($name): $status}' "$temp_status_file" > "${temp_status_file}.tmp" && \
               mv "${temp_status_file}.tmp" "$temp_status_file"
        fi
        
        local workflow_name
        workflow_name=$(sanitize_name "$workflow")
        local workflow_dir="$ARTIFACTS_DIR/$workflow_name"
        
        if [[ -d "$workflow_dir" ]]; then
            debug "Processing artifacts for $workflow_name"
            while IFS= read -r -d '' video; do
                local rel_video="${video#site/static/}"
                local thumbnail="${video%.mp4}.avif"
                local rel_thumbnail="${thumbnail#site/static/}"
                if [[ -f "$video" && -f "$thumbnail" ]]; then
                    debug "Found video/thumbnail pair: $rel_video, $rel_thumbnail"
                    jq --arg wf "$workflow_name" --arg video "$rel_video" --arg thumb "$rel_thumbnail" \
                       '.videos += [{"workflow": $wf, "video": $video, "thumbnail": $thumb}]' \
                       "$temp_manifest_file" > "${temp_manifest_file}.tmp" && \
                       mv "${temp_manifest_file}.tmp" "$temp_manifest_file"
                else
                    warn "Missing video or thumbnail for $workflow_name"
                fi
            done < <(find "$workflow_dir" -type f -name "*.mp4" -print0)
        else
            warn "No artifacts directory found for $workflow_name"
        fi
    done
    
    mv "$temp_status_file" "$status_file"
    mv "$temp_manifest_file" "$manifest"
    
    local video_count
    video_count=$(jq '.videos | length' "$manifest")
    info "Generated manifest with $video_count video entries"
    
    if [[ ! -f "$manifest" || ! -f "$status_file" ]]; then
        error "Failed to generate manifest files"
        return 1
    fi
    
    info "Manifest files generated:"
    info "- Status file: $status_file"
    info "- Manifest file: $manifest"
    
    if [[ "${DEBUG:-0}" == "1" ]]; then
        debug "Manifest contents:" && jq '.' "$manifest"
        debug "Status file contents:" && jq '.' "$status_file"
    fi
}

###########################
# Commit SHA Retrieval
###########################
retrieve_commit_sha() {
    if [[ -z "${COMMIT_SHA:-}" ]]; then
        info "COMMIT_SHA not set, attempting to determine it via git"
        COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null || true)
        if [[ -z "$COMMIT_SHA" ]]; then
            info "git rev-parse failed, trying GitHub API"
            COMMIT_SHA=$(gh api repos/pondersource/dev-stock/commits/main --jq '.sha' 2>/dev/null || true)
            if [[ -z "$COMMIT_SHA" ]]; then
                error "Could not determine COMMIT_SHA. Please set it manually or run in a valid git repository."
                exit 1
            fi
        fi
        export COMMIT_SHA
        info "Using commit SHA: ${COMMIT_SHA}"
    fi
}

###########################
# Workflow Processing
###########################
process_workflows() {
    info "Looking for workflow files in .github/workflows..."
    if [[ ! -d ".github/workflows" ]]; then
        error "Workflows directory not found: .github/workflows"
        error "Current directory contents: $(ls -la)"
        exit 1
    fi

    # Gather workflow files that start with login-, invite-, or share-
    declare -a wf_files=()
    while IFS= read -r -d '' workflow; do
        local basename
        basename=$(basename "$workflow")
        if [[ "$basename" =~ ^(login|invite|share)- ]]; then
            wf_files+=("$basename")
            debug "Added workflow: $basename"
        else
            debug "Skipping irrelevant workflow: $basename"
        fi
    done < <(find ".github/workflows" -maxdepth 1 -type f -name "*.yml" -print0)

    if [[ ${#wf_files[@]} -eq 0 ]]; then
        error "No workflow files found in .github/workflows!"
        error "Contents: $(ls -la .github/workflows)"
        exit 1
    fi

    workflow_files=("${wf_files[@]}")
    info "Found ${#workflow_files[@]} workflow files"

    # Count workflows by type
    for wf in "${workflow_files[@]}"; do
        case "$wf" in
            login-*) ((login_count++));;
            share-*) ((share_count++));;
            invite-*) ((invite_count++));;
            *) warn "Unexpected workflow pattern: $wf";;
        esac
    done

    info "Workflow Count Summary: Login: $login_count (expected: 6), Share: $share_count (expected: 27), Invite: $invite_count (expected: 9)"
    total=$((login_count + share_count + invite_count))
    info "Total test workflows processed: $total (expected: 42)"
    if [ "$total" -ne 42 ]; then
        error "Processed $total workflows but expected 42. Aborting."
        exit 1
    fi

    # Process each workflow's artifacts
    for wf in "${workflow_files[@]}"; do
        case "$wf" in
            login-*|share-*|invite-*)
                info "Processing workflow: $wf"
                if ! fetch_workflow_artifacts "$wf"; then
                    error "Failed to process workflow: $wf"
                fi
                ;;
            *)
                warn "Skipping unrecognized workflow: $wf"
                ;;
        esac
    done
}

###########################
# Main Execution
###########################
main() {
    trap cleanup EXIT
    trap 'error "Error on line $LINENO: $BASH_COMMAND"' ERR

    info "Creating required directories..."
    mkdir -p "$ARTIFACTS_DIR" || { error "Failed to create: $ARTIFACTS_DIR"; exit 1; }
    mkdir -p "$IMAGES_DIR" || { error "Failed to create: $IMAGES_DIR"; exit 1; }
    success "Directories created successfully"

    # Initialize manifest and status files
    MANIFEST_FILE="$ARTIFACTS_DIR/manifest.json"
    STATUS_FILE="$ARTIFACTS_DIR/workflow-status.json"
    echo '{"videos": []}' > "$MANIFEST_FILE"
    echo '{}' > "$STATUS_FILE"

    info "Starting script in directory: $(pwd)"
    info "Script directory: $SCRIPT_DIR"

    info "Checking dependencies..."
    check_dependencies
    success "All dependencies are present"

    retrieve_commit_sha
    info "Downloading artifacts for commit: ${COMMIT_SHA}"

    process_workflows
    generate_manifest

    info "Contents of artifacts directory:"
    ls -R "$ARTIFACTS_DIR"

    local artifacts_size
    artifacts_size=$(du -sh "$ARTIFACTS_DIR" 2>/dev/null | cut -f1)
    info "Total artifacts size: $artifacts_size"
    info "Log file location: $LOG_FILE"
    success "Script completed successfully"
}

main "$@"
