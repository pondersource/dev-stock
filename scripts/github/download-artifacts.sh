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
# Author: PonderSource
# License: MIT

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
    local thumbnail="${video%.*}.jpg"
    info "Generating thumbnail for $video"
    
    if ! ffmpeg -hide_banner -loglevel error -i "$video" \
        -vf "select=eq(n\,0),scale=640:-1" -vframes 1 "$thumbnail"; then
        error "Failed to generate thumbnail for $video"
        return 1
    fi
    
    debug "Thumbnail generated at $thumbnail"
}

# Function to convert video to WebM
convert_to_webm() {
    local input="$1"
    local output="${input%.mp4}.webm"
    info "Converting $input to WebM format"
    
    if ! ffmpeg -hide_banner -loglevel error -i "$input" \
        -c:v libvpx-vp9 -crf 30 -b:v 0 -b:a 128k -c:a libopus "$output" -y; then
        error "Failed to convert $input to WebM"
        return 1
    fi
    
    debug "Conversion complete: $output"
    printf "%s" "$output"  # Use printf instead of echo for cleaner output
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
    local webm_file
    webm_file=$(convert_to_webm "$new_name") || {
        error "Failed to convert video to WebM"
        return 1
    }
    
    # Generate thumbnail
    if ! generate_thumbnail "$webm_file"; then
        error "Failed to generate thumbnail"
        return 1
    fi
    
    # Cleanup original MP4
    rm -f "$new_name"
}

# Function to fetch workflow artifacts
fetch_workflow_artifacts() {
    local workflow="$1"
    local latest_run
    
    latest_run=$(gh api "repos/pondersource/dev-stock/actions/workflows/$workflow/runs" \
        --jq '.workflow_runs[0].id') || {
        error "Failed to fetch latest run for workflow $workflow"
        return 1
    }
    
    if [[ -z "$latest_run" ]]; then
        error "No runs found for workflow $workflow"
        return 1
    fi
    
    echo "$latest_run"
}

# Function to download and process artifacts
download_artifacts() {
    local workflow="$1"
    local workflow_name
    workflow_name=$(sanitize_name "$workflow")
    info "Processing workflow: $workflow_name"
    
    # Get the latest workflow run ID
    local latest_run
    latest_run=$(fetch_workflow_artifacts "$workflow") || return 1
    info "Latest run ID: $latest_run"
    
    # Get artifacts for this run
    local artifacts_json
    artifacts_json=$(gh api "repos/pondersource/dev-stock/actions/runs/$latest_run/artifacts") || {
        error "Failed to fetch artifacts for run $latest_run"
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
        
        # Process videos - explicitly use bash and export functions
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

# Function to generate manifest
generate_manifest() {
    info "Generating artifact manifest..."
    local manifest="$ARTIFACTS_DIR/manifest.json"
    
    # Use jq to build the manifest
    find "$ARTIFACTS_DIR" -type f -name "*.webm" -print0 | sort -z | jq -R -s -c 'split("\u0000")[:-1] | 
        map(select(length > 0) | {
            workflow: capture("artifacts/(?<wf>[^/]+)").wf,
            video: .,
            thumbnail: sub("\\.webm$"; ".jpg")
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