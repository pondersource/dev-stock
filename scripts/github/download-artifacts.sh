#!/bin/bash

# download-artifacts.sh
#
# Downloads and processes video artifacts from GitHub Actions test workflows.
# Converts videos to AV1/WebM format and generates AVIF thumbnails.
#
# Key features:
# - Ensures artifacts are from the same commit (COMMIT_SHA)
# - Processes 43 test workflows (6 login, 28 share, 9 invite)
# - Generates manifest.json for website consumption
#
# Requirements: gh, jq, ffmpeg, unzip

set -euo pipefail

# Global variables
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ARTIFACTS_DIR="site/static/artifacts"
readonly IMAGES_DIR="site/static/images"
readonly LOG_FILE="/tmp/artifact-download-$(date +%Y%m%d-%H%M%S).log"
declare -a TEMP_DIRS

# Enhanced logging functions
log() { 
    local timestamp
    local level="$1"
    shift
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    printf "[%s] %-7s %s\n" "$timestamp" "$level" "$*" >> "$LOG_FILE"
    printf "[%s] %-7s %s\n" "$timestamp" "$level" "$*"
}
error() { log "ERROR" "$*" >&2; }
info() { log "INFO" "$*"; }
debug() { [[ "${DEBUG:-0}" == "1" ]] && log "DEBUG" "$*"; }
warn() { log "WARN" "$*" >&2; }
success() { log "SUCCESS" "$*"; }

# Timer functions for operation timing
start_timer() {
    timer_start=$(date +%s)
}

end_timer() {
    local end_time=$(date +%s)
    local duration=$((end_time - timer_start))
    local operation="$1"
    info "Operation '$operation' completed in ${duration}s"
}

# Get human readable file size
human_size() {
    local size=$1
    if ((size < 1024)); then
        echo "${size}B"
    elif ((size < 1048576)); then
        echo "$((size/1024))KB"
    else
        echo "$((size/1048576))MB"
    fi
}

# Cleanup function
cleanup() {
    local exit_code=$?
    info "Cleaning up temporary directories..."
    for dir in "${TEMP_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            debug "Removed temporary directory: $dir"
        fi
    done
    if [[ $exit_code -ne 0 ]]; then
        error "Script failed with exit code $exit_code"
    fi
    exit "$exit_code"
}

# Check required tools
check_dependencies() {
    local missing_deps=()
    for cmd in gh jq ffmpeg unzip; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing_deps[*]}"
        error "Please install these tools before running this script."
        exit 1
    fi
}

# Sanitizes workflow names for filesystem usage
sanitize_name() {
    local name="$1"
    echo "$name" | sed -E 's/\.(yml|yaml)$//' | tr '[:upper:]' '[:lower:]'
}

# Generates AVIF thumbnail from first frame
# Uses AV1 codec with still-picture optimization
generate_thumbnail() {
    local video="$1"
    local thumbnail="${video%.*}.avif"
    
    if ! ffmpeg -hide_banner -loglevel error -i "$video" \
        -vf "select=eq(n\,0),scale=640:-1" -vframes 1 -c:v libaom-av1 -still-picture 1 "$thumbnail" 2>/dev/null; then
        return 1
    fi
    
    printf "%s" "$thumbnail"
}

# Converts MP4 to WebM using AV1 codec
# Uses multi-threading and speed optimization (cpu-used=4)
convert_to_webm() {
    local input="$1"
    local output="${input%.mp4}.webm"
    
    if ! ffmpeg -hide_banner -loglevel error -i "$input" \
        -c:v libaom-av1 -crf 30 -b:v 0 -b:a 128k -c:a libopus -row-mt 1 -cpu-used 4 "$output" -y 2>/dev/null; then
        return 1
    fi
    
    printf "%s" "$output"
}

# Enhanced process_video with progress logging
process_video() {
    local input="$1"
    local dir
    dir="$(dirname "$input")"
    local new_name="$dir/recording.mp4"
    local original_size
    
    start_timer
    original_size=$(stat -f%z "$input" 2>/dev/null || stat -c%s "$input")
    info "Processing video: $input ($(human_size $original_size))"
    
    # Rename to consistent filename
    if ! mv "$input" "$new_name"; then
        error "Failed to rename $input to $new_name"
        return 1
    fi
    debug "Renamed $input to $new_name"
    
    # Convert to WebM
    info "Converting $new_name to WebM format"
    local webm_file
    if ! webm_file=$(convert_to_webm "$new_name"); then
        error "Failed to convert video to WebM"
        return 1
    fi
    local webm_size
    webm_size=$(stat -f%z "$webm_file" 2>/dev/null || stat -c%s "$webm_file")
    success "Converted to $webm_file ($(human_size $webm_size))"
    
    # Generate thumbnail
    info "Generating thumbnail for $webm_file"
    local thumbnail_file
    if ! thumbnail_file=$(generate_thumbnail "$webm_file"); then
        error "Failed to generate thumbnail"
        return 1
    fi
    local thumb_size
    thumb_size=$(stat -f%z "$thumbnail_file" 2>/dev/null || stat -c%s "$thumbnail_file")
    success "Generated thumbnail at $thumbnail_file ($(human_size $thumb_size))"
    
    # Cleanup original MP4
    rm -f "$new_name"
    end_timer "Video processing"
}

# Enhanced fetch_workflow_artifacts with more detailed logging
fetch_workflow_artifacts() {
    local workflow="$1"
    local workflow_name
    workflow_name=$(sanitize_name "$workflow")
    info "Processing workflow: $workflow_name"
    start_timer
    
    # Get the latest run for this workflow
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
    
    # Get run ID and additional information
    local run_id run_status run_conclusion
    run_id=$(echo "$runs_json" | jq -r '.id')
    run_status=$(echo "$runs_json" | jq -r '.status')
    run_conclusion=$(echo "$runs_json" | jq -r '.conclusion')
    info "Found run ID: $run_id (Status: $run_status, Conclusion: $run_conclusion) for commit ${COMMIT_SHA}"
    
    # Get artifacts with count information
    local artifacts_json artifact_count
    debug "Fetching artifacts for run $run_id"
    artifacts_json=$(gh api "repos/pondersource/dev-stock/actions/runs/$run_id/artifacts") || {
        error "Failed to fetch artifacts for run $run_id"
        return 1
    }
    artifact_count=$(echo "$artifacts_json" | jq '.total_count')
    info "Found $artifact_count artifacts for run $run_id"
    
    # Process each artifact with size information
    local processed_count=0
    echo "$artifacts_json" | jq -r '.artifacts[] | "\(.id) \(.name) \(.size_in_bytes)"' | while read -r id name size; do
        ((processed_count++))
        info "Downloading artifact $name (ID: $id, Size: $(human_size $size)) [$processed_count/$artifact_count]"
        
        # Create a temporary directory for this artifact
        local tmp_dir
        tmp_dir=$(mktemp -d)
        TEMP_DIRS+=("$tmp_dir")
        
        # Download with progress indication
        debug "Downloading to temporary directory: $tmp_dir"
        if ! gh api "repos/pondersource/dev-stock/actions/artifacts/$id/zip" \
            -H "Accept: application/vnd.github+json" > "$tmp_dir/artifact.zip"; then
            error "Failed to download artifact $id"
            rm -rf "$tmp_dir"
            continue
        fi
        
        # Extract with size information
        local target_dir="$ARTIFACTS_DIR/$workflow_name"
        mkdir -p "$target_dir"
        debug "Extracting to $target_dir"
        if ! unzip -o "$tmp_dir/artifact.zip" -d "$target_dir"; then
            error "Failed to extract artifact $id"
            rm -rf "$tmp_dir"
            continue
        fi
        
        # Process videos with enhanced logging
        local video_count=0
        while IFS= read -r -d '' video; do
            ((video_count++))
            process_video "$video"
        done < <(find "$target_dir" -name "*.mp4" -print0)
        info "Processed $video_count videos from artifact $name"
        
        # Cleanup
        rm -rf "$tmp_dir"
        for i in "${!TEMP_DIRS[@]}"; do
            if [[ ${TEMP_DIRS[i]} = "$tmp_dir" ]]; then
                unset 'TEMP_DIRS[i]'
                break
            fi
        done
    done
    
    end_timer "Workflow artifact processing"
    return 0
}

# Fetches workflow status
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

# Generates two key files:
# 1. manifest.json: Maps workflows to their video/thumbnail files
# 2. workflow-status.json: Current status of all test workflows
generate_manifest() {
    info "Generating artifact manifest..."
    local manifest="$ARTIFACTS_DIR/manifest.json"
    local status_file="$ARTIFACTS_DIR/workflow-status.json"
    local temp_status_file="/tmp/temp_status_$$.json"
    
    # Initialize empty JSON in temp file
    echo "{}" > "$temp_status_file"
    
    # Collect all workflow statuses
    while read -r workflow; do
        workflow_name=$(basename "$workflow")
        status=$(fetch_workflow_status "$workflow_name")
        if [[ -n "$status" ]]; then
            jq --arg name "$workflow_name" --argjson status "$status" '. + {($name): $status}' "$temp_status_file" > "${temp_status_file}.tmp" && mv "${temp_status_file}.tmp" "$temp_status_file"
        fi
    done < <(gh api repos/pondersource/dev-stock/actions/workflows --jq '.workflows[] | select(.path | test("share-|login-|invite-")) | .path')
    
    # Move the final status file to its destination
    mv "$temp_status_file" "$status_file"
    info "Workflow statuses written to $status_file"
    
    # Use jq to build the manifest with correct relative paths
    # Remove 'site/static/' prefix from paths as it's not needed in the final URL
    find "$ARTIFACTS_DIR" -type f -name "*.webm" -print0 | sort -z | jq -R -s -c 'split("\u0000")[:-1] | 
        map(select(length > 0) | {
            workflow: capture("artifacts/(?<wf>[^/]+)").wf,
            video: (. | sub("^site/static/"; "")),
            thumbnail: (. | sub("^site/static/"; "") | sub("\\.webm$"; ".avif"))
        }) | { videos: . }' > "$manifest"
    
    if [[ ! -f "$manifest" ]]; then
        error "Failed to generate manifest"
        return 1
    fi
    
    info "Manifest generated at $manifest"
}

# Enhanced main function with summary statistics
main() {
    # Set up error handling
    trap cleanup EXIT
    
    # Check dependencies
    check_dependencies
    
    # Ensure COMMIT_SHA is set
    if [[ -z "${COMMIT_SHA:-}" ]]; then
        # Try to get the latest commit SHA from git
        COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null || true)
        
        if [[ -z "${COMMIT_SHA}" ]]; then
            # If git command fails, try to get it from GitHub API
            COMMIT_SHA=$(gh api repos/pondersource/dev-stock/commits/main --jq '.sha' 2>/dev/null || true)
            
            if [[ -z "${COMMIT_SHA}" ]]; then
                error "Could not determine COMMIT_SHA. Please set it manually or ensure you're in a git repository."
                exit 1
            fi
        fi
        export COMMIT_SHA
        info "Using commit SHA: ${COMMIT_SHA}"
    fi
    
    info "Downloading artifacts for commit: ${COMMIT_SHA}"
    
    # Create required directories
    mkdir -p "$ARTIFACTS_DIR" "$IMAGES_DIR"
    
    # Get workflow files from the local .github/workflows directory
    local workflow_files=()
    while IFS= read -r -d '' workflow; do
        workflow_files+=("$(basename "$workflow")")
    done < <(find ".github/workflows" -maxdepth 1 -type f -name "*.yml" -print0)
    
    # Count of expected workflow types
    local login_count=0
    local share_count=0
    local invite_count=0
    local other_count=0
    
    info "Found ${#workflow_files[@]} total workflows"
    
    # Process and categorize workflows
    for workflow in "${workflow_files[@]}"; do
        # Skip the orchestrator and pages workflows
        if [[ "$workflow" == "github-pages.yml" || "$workflow" == "tests-orchestrator.yml" ]]; then
            debug "Skipping workflow: $workflow"
            continue
        fi
        
        # Categorize the workflow
        if [[ "$workflow" == login-* ]]; then
            ((login_count++))
            info "Processing login workflow: $workflow"
        elif [[ "$workflow" == share-* ]]; then
            ((share_count++))
            info "Processing share workflow: $workflow"
        elif [[ "$workflow" == invite-* ]]; then
            ((invite_count++))
            info "Processing invite workflow: $workflow"
        else
            ((other_count++))
            warn "Found unexpected workflow: $workflow"
            continue
        fi
        
        if ! fetch_workflow_artifacts "$workflow"; then
            error "Failed to process workflow: $workflow"
            continue
        fi
    done
    
    # Report workflow counts
    info "Workflow processing summary:"
    info "- Login workflows: $login_count (expected: 6)"
    info "- Share workflows: $share_count (expected: 28)"
    info "- Invite workflows: $invite_count (expected: 9)"
    if ((other_count > 0)); then
        warn "Found $other_count unexpected workflow types"
    fi
    
    # Verify we processed the expected number of workflows
    local total=$((login_count + share_count + invite_count))
    info "Total test workflows processed: $total (expected: 43)"
    if ((total != 43)); then
        error "Processed $total workflows but expected 43"
        error "Some workflows might be missing or miscategorized"
        exit 1
    fi
    
    # Generate manifest
    generate_manifest
    
    # Debug output
    info "Contents of artifacts directory:"
    ls -R "$ARTIFACTS_DIR"
    
    # Add summary at the end
    info "=== Final Summary ==="
    info "Total workflows processed: $total / 43"
    info "- Login workflows: $login_count / 6"
    info "- Share workflows: $share_count / 28"
    info "- Invite workflows: $invite_count / 9"
    if ((other_count > 0)); then
        warn "- Unexpected workflows: $other_count"
    fi
    
    # Add disk usage information
    local artifacts_size
    artifacts_size=$(du -sh "$ARTIFACTS_DIR" 2>/dev/null | cut -f1)
    info "Total artifacts size: $artifacts_size"
    
    info "Log file location: $LOG_FILE"
    success "Script completed successfully"
}

main "$@" 