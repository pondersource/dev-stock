#!/bin/bash

# download-artifacts.sh
#
# Description: Downloads and processes video artifacts from GitHub Actions workflows,
# converting them to web-friendly formats and generating thumbnails.
#
# Usage: ./download-artifacts.sh
# Requirements:
#   - GitHub CLI (gh)
#   - jq
#   - ffmpeg
#   - unzip
#
# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>
#

set -euo pipefail

# Global variables
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ARTIFACTS_DIR="site/static/artifacts"
readonly IMAGES_DIR="site/static/images"
readonly LOG_FILE="/tmp/artifact-download-$(date +%Y%m%d-%H%M%S).log"
declare -a TEMP_DIRS

# Logging functions
log() { 
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $*" >> "$LOG_FILE"
    echo "[$timestamp] $*"
}
error() { log "ERROR: $*" >&2; }
info() { log "INFO: $*"; }
debug() { [[ "${DEBUG:-0}" == "1" ]] && log "DEBUG: $*"; }

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

# Function to sanitize workflow name for consistent file naming
sanitize_name() {
    local name="$1"
    echo "$name" | sed -E 's/\.(yml|yaml)$//' | tr '[:upper:]' '[:lower:]'
}

# Function to generate video thumbnail
generate_thumbnail() {
    local video="$1"
    local thumbnail="${video%.*}.avif"
    
    if ! ffmpeg -hide_banner -loglevel error -i "$video" \
        -vf "select=eq(n\,0),scale=640:-1" -vframes 1 -c:v libaom-av1 -still-picture 1 "$thumbnail" 2>/dev/null; then
        return 1
    fi
    
    printf "%s" "$thumbnail"
}

# Function to convert video to WebM
convert_to_webm() {
    local input="$1"
    local output="${input%.mp4}.webm"
    
    if ! ffmpeg -hide_banner -loglevel error -i "$input" \
        -c:v libaom-av1 -crf 30 -b:v 0 -b:a 128k -c:a libopus -row-mt 1 -cpu-used 4 "$output" -y 2>/dev/null; then
        return 1
    fi
    
    printf "%s" "$output"
}

# Function to process video file
process_video() {
    local input="$1"
    local dir
    dir="$(dirname "$input")"
    local new_name="$dir/recording.mp4"
    
    info "Processing video: $input"
    
    # Rename to consistent filename
    if ! mv "$input" "$new_name"; then
        error "Failed to rename $input to $new_name"
        return 1
    fi
    
    # Convert to WebM
    info "Converting $new_name to WebM format"
    local webm_file
    if ! webm_file=$(convert_to_webm "$new_name"); then
        error "Failed to convert video to WebM"
        return 1
    fi
    info "Successfully converted to $webm_file"
    
    # Generate thumbnail
    info "Generating thumbnail for $webm_file"
    local thumbnail_file
    if ! thumbnail_file=$(generate_thumbnail "$webm_file"); then
        error "Failed to generate thumbnail"
        return 1
    fi
    info "Successfully generated thumbnail at $thumbnail_file"
    
    # Cleanup original MP4
    rm -f "$new_name"
}

# Function to fetch workflow artifacts
fetch_workflow_artifacts() {
    local workflow="$1"
    local workflow_name
    workflow_name=$(sanitize_name "$workflow")
    info "Processing workflow: $workflow_name"
    
    # Get the latest workflow run for this specific commit
    local runs_json
    runs_json=$(gh api "repos/pondersource/dev-stock/actions/workflows/$workflow/runs" \
        --jq ".workflow_runs[] | select(.head_sha == \"${COMMIT_SHA}\")" | head -n 1) || {
        error "Failed to fetch runs for workflow $workflow"
        return 1
    }
    
    if [[ -z "$runs_json" ]]; then
        error "No runs found for workflow $workflow with commit ${COMMIT_SHA}"
        return 1
    }
    
    # Get run ID from the JSON
    local run_id
    run_id=$(echo "$runs_json" | jq -r '.id')
    info "Found run ID: $run_id for commit ${COMMIT_SHA}"
    
    # Get artifacts for this run
    local artifacts_json
    artifacts_json=$(gh api "repos/pondersource/dev-stock/actions/runs/$run_id/artifacts") || {
        error "Failed to fetch artifacts for run $run_id"
        return 1
    }
    
    # Process each artifact
    echo "$artifacts_json" | jq -r '.artifacts[] | "\(.id) \(.name)"' | while read -r id name; do
        info "Downloading artifact $name (ID: $id)"
        
        # Create a temporary directory for this artifact
        local tmp_dir
        tmp_dir=$(mktemp -d)
        TEMP_DIRS+=("$tmp_dir")
        
        # Download the artifact
        if ! gh api "repos/pondersource/dev-stock/actions/artifacts/$id/zip" \
            -H "Accept: application/vnd.github+json" > "$tmp_dir/artifact.zip"; then
            error "Failed to download artifact $id"
            rm -rf "$tmp_dir"  # Clean up immediately on failure
            continue
        fi
        
        # Extract to the appropriate directory
        local target_dir="$ARTIFACTS_DIR/$workflow_name"
        mkdir -p "$target_dir"
        if ! unzip -o "$tmp_dir/artifact.zip" -d "$target_dir"; then
            error "Failed to extract artifact $id"
            rm -rf "$tmp_dir"  # Clean up immediately on failure
            continue
        fi
        
        # Process videos
        export LOG_FILE  # Export log file path
        export -f process_video convert_to_webm generate_thumbnail log error info debug
        find "$target_dir" -name "*.mp4" -exec bash -c '
            process_video "$1"
        ' _ {} \;
        
        # Clean up the temporary directory after successful processing
        rm -rf "$tmp_dir"
        # Remove the directory from our tracking array
        for i in "${!TEMP_DIRS[@]}"; do
            if [[ ${TEMP_DIRS[i]} = "$tmp_dir" ]]; then
                unset 'TEMP_DIRS[i]'
                break
            fi
        done
    done
}

# Function to fetch workflow status
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

# Function to generate manifest
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

main() {
    # Set up error handling
    trap cleanup EXIT
    
    # Check dependencies
    check_dependencies
    
    # Ensure COMMIT_SHA is set
    if [[ -z "${COMMIT_SHA}" ]]; then
        error "COMMIT_SHA environment variable is not set"
        exit 1
    }
    
    info "Downloading artifacts for commit: ${COMMIT_SHA}"
    
    # Create required directories
    mkdir -p "$ARTIFACTS_DIR" "$IMAGES_DIR"
    
    # Process workflows
    gh api repos/pondersource/dev-stock/actions/workflows --jq '.workflows[].path' | \
    while read -r workflow; do
        if echo "$workflow" | grep -qE 'share-|login-|invite-'; then
            info "Found test workflow: $workflow"
            if ! download_artifacts "$(basename "$workflow")"; then
                error "Failed to process workflow: $workflow"
                continue
            fi
        fi
    done
    
    # Generate manifest
    generate_manifest
    
    # Debug output
    info "Contents of artifacts directory:"
    ls -R "$ARTIFACTS_DIR"
    
    info "Script completed successfully"
}

# Execute main function
main "$@" 