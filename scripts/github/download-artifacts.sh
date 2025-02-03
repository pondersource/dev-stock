#!/bin/bash

# download-artifacts.sh
#
# Downloads and processes video artifacts from GitHub Actions test workflows.
# Converts videos to AV1/WebM format and generates AVIF thumbnails.
#
# Key features:
# - Ensures artifacts are from the same commit (COMMIT_SHA)
# - Processes 42 test workflows (6 login, 27 share, 9 invite)
# - Generates manifest.json for website consumption
#
# Requirements: gh, jq, ffmpeg, unzip

set -euo pipefail

# Global variables
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ARTIFACTS_DIR="site/static/artifacts"
readonly IMAGES_DIR="site/static/images"
readonly LOG_FILE="/tmp/artifact-download-$(date +%Y%m%d-%H%M%S).log"
declare -a TEMP_DIRS=()

# Enhanced logging functions
log() { 
    local timestamp level msg
    level="$1"
    shift
    msg="$*"
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    printf "[%s] %-7s %s\n" "$timestamp" "$level" "$msg" >> "$LOG_FILE"
    printf "[%s] %-7s %s\n" "$timestamp" "$level" "$msg"
}
error() { log "ERROR" "$*" >&2; }
info() { log "INFO" "$*"; }
debug() { [[ "${DEBUG:-0}" == "1" ]] && log "DEBUG" "$*" || true; }
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
    local size="${1:-0}"  # Default to 0 if no argument provided
    if ((size < 1024)); then
        echo "${size}B"
    elif ((size < 1048576)); then
        echo "$((size/1024))KB"
    else
        echo "$((size/1048576))MB"
    fi
}

# Cleanup function with simpler temp directory handling
cleanup() {
    info "Cleaning up temporary directories..."
    if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        debug "Removed temporary directory: $TEMP_DIR"
    fi
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

# Process video file (now just generates thumbnail)
process_video() {
    local input="$1"
    local dir
    dir="$(dirname "$input")"
    local original_size
    
    start_timer
    original_size=$(stat -f%z "$input" 2>/dev/null || stat -c%s "$input")
    info "Processing video: $input ($(human_size $original_size))"
    
    # Generate thumbnail
    info "Generating thumbnail for $input"
    local thumbnail_file
    if ! thumbnail_file=$(generate_thumbnail "$input"); then
        error "Failed to generate thumbnail"
        return 1
    fi
    local thumb_size
    thumb_size=$(stat -f%z "$thumbnail_file" 2>/dev/null || stat -c%s "$thumbnail_file")
    success "Generated thumbnail at $thumbnail_file ($(human_size $thumb_size))"
    
    end_timer "Video processing"
}

# Process artifacts for a workflow
fetch_workflow_artifacts() {
    local workflow="$1"
    local workflow_name
    workflow_name=$(sanitize_name "$workflow")
    info "Processing workflow: $workflow_name"
    
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
    
    # Store workflow status for later use
    echo "$runs_json" | jq --arg name "$workflow" '{
        ($name): {
            name: .name,
            status: .status,
            conclusion: .conclusion
        }
    }' >> "$STATUS_FILE"
    
    # Get run ID
    local run_id
    run_id=$(echo "$runs_json" | jq -r '.id')
    info "Processing run ID: $run_id"
    
    # Get artifacts
    local artifacts_json
    artifacts_json=$(gh api "repos/pondersource/dev-stock/actions/runs/$run_id/artifacts") || {
        error "Failed to fetch artifacts for run $run_id"
        return 1
    }
    
    # Create workflow directory
    local workflow_dir="$ARTIFACTS_DIR/$workflow_name"
    mkdir -p "$workflow_dir"
    
    # Process each artifact
    echo "$artifacts_json" | jq -r '.artifacts[] | "\(.id) \(.name) \(.size_in_bytes // 0)"' | while read -r id name size; do
        info "Downloading artifact $name (ID: $id, Size: $(human_size ${size:-0}))"
        
        # Create temporary directory if needed
        TEMP_DIR="$(mktemp -d)"
        
        # Download and extract artifact
        if gh api "repos/pondersource/dev-stock/actions/artifacts/$id/zip" \
            -H "Accept: application/vnd.github+json" > "$TEMP_DIR/artifact.zip"; then
            
            if unzip -q -o "$TEMP_DIR/artifact.zip" -d "$workflow_dir"; then
                # Process videos
                find "$workflow_dir" -name "*.mp4" -print0 | while IFS= read -r -d '' video; do
                    process_video "$video"
                    
                    # Add to manifest if thumbnail was generated
                    local thumbnail="${video%.mp4}.avif"
                    if [[ -f "$thumbnail" ]]; then
                        local rel_video="${video#site/static/}"
                        local rel_thumbnail="${thumbnail#site/static/}"
                        jq --arg wf "$workflow_name" \
                           --arg video "$rel_video" \
                           --arg thumb "$rel_thumbnail" \
                           '.videos += [{"workflow": $wf, "video": $video, "thumbnail": $thumb}]' \
                           "$MANIFEST_FILE" > "${MANIFEST_FILE}.tmp" && \
                           mv "${MANIFEST_FILE}.tmp" "$MANIFEST_FILE"
                    fi
                done
            else
                error "Failed to extract artifact $id"
            fi
        else
            error "Failed to download artifact $id"
        fi
        
        # Cleanup temp directory
        rm -rf "$TEMP_DIR"
    done
    
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
    local temp_manifest_file="/tmp/temp_manifest_$$.json"
    
    # Initialize empty JSON files
    echo "{}" > "$temp_status_file"
    echo '{"videos": []}' > "$temp_manifest_file"
    
    # Process each workflow type
    for workflow in "${workflow_files[@]}"; do
        # Get workflow status
        local status
        status=$(fetch_workflow_status "$workflow")
        if [[ -n "$status" ]]; then
            jq --arg name "$workflow" --argjson status "$status" \
               '. + {($name): $status}' "$temp_status_file" > "${temp_status_file}.tmp" \
               && mv "${temp_status_file}.tmp" "$temp_status_file"
        fi
        
        # Get workflow artifacts
        local workflow_name
        workflow_name=$(sanitize_name "$workflow")
        local workflow_dir="$ARTIFACTS_DIR/$workflow_name"
        
        if [[ -d "$workflow_dir" ]]; then
            debug "Processing artifacts for $workflow_name"
            # Find all MP4 videos and their thumbnails
            while IFS= read -r -d '' video; do
                local rel_video="${video#site/static/}"
                local thumbnail="${video%.mp4}.avif"
                local rel_thumbnail="${thumbnail#site/static/}"
                
                if [[ -f "$video" && -f "$thumbnail" ]]; then
                    debug "Found video/thumbnail pair: $rel_video, $rel_thumbnail"
                    # Add to manifest
                    jq --arg wf "$workflow_name" \
                       --arg video "$rel_video" \
                       --arg thumb "$rel_thumbnail" \
                       '.videos += [{"workflow": $wf, "video": $video, "thumbnail": $thumb}]' \
                       "$temp_manifest_file" > "${temp_manifest_file}.tmp" \
                       && mv "${temp_manifest_file}.tmp" "$temp_manifest_file"
                else
                    warn "Missing video or thumbnail for $workflow_name"
                fi
            done < <(find "$workflow_dir" -type f -name "*.mp4" -print0)
        else
            warn "No artifacts directory found for $workflow_name"
        fi
    done
    
    # Move the final files to their destinations
    mv "$temp_status_file" "$status_file"
    mv "$temp_manifest_file" "$manifest"
    
    # Verify manifest contents
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
    
    # Debug output of manifest contents
    if [[ "${DEBUG:-0}" == "1" ]]; then
        debug "Manifest contents:"
        jq '.' "$manifest"
        debug "Status file contents:"
        jq '.' "$status_file"
    fi
}

# Main execution
main() {
    # Set up error handling
    set -Eeo pipefail
    trap cleanup EXIT
    trap 'error "Error on line $LINENO: $BASH_COMMAND"' ERR
    
    # Initialize files
    MANIFEST_FILE="$ARTIFACTS_DIR/manifest.json"
    STATUS_FILE="$ARTIFACTS_DIR/workflow-status.json"
    echo '{"videos": []}' > "$MANIFEST_FILE"
    echo '{}' > "$STATUS_FILE"
    
    info "Starting script in directory: $(pwd)"
    info "Script directory: $SCRIPT_DIR"
    
    # Check dependencies with more detailed logging
    info "Checking dependencies..."
    check_dependencies
    success "All dependencies found"
    
    # Ensure COMMIT_SHA is set
    if [[ -z "${COMMIT_SHA:-}" ]]; then
        info "COMMIT_SHA not set, attempting to determine it"
        COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null || true)
        
        if [[ -z "${COMMIT_SHA}" ]]; then
            info "Git rev-parse failed, trying GitHub API"
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
    
    # Create required directories with error checking
    info "Creating required directories..."
    if ! mkdir -p "$ARTIFACTS_DIR" 2>/dev/null; then
        error "Failed to create artifacts directory: $ARTIFACTS_DIR"
        error "Current permissions: $(ls -ld "$(dirname "$ARTIFACTS_DIR")" 2>/dev/null || echo 'Cannot read parent directory')"
        exit 1
    fi
    if ! mkdir -p "$IMAGES_DIR" 2>/dev/null; then
        error "Failed to create images directory: $IMAGES_DIR"
        error "Current permissions: $(ls -ld "$(dirname "$IMAGES_DIR")" 2>/dev/null || echo 'Cannot read parent directory')"
        exit 1
    fi
    success "Directories created successfully"
    
    # Get workflow files from the local .github/workflows directory
    info "Looking for workflow files in .github/workflows..."
    if [[ ! -d ".github/workflows" ]]; then
        error "Workflows directory not found: .github/workflows"
        error "Current directory contents: $(ls -la)"
        exit 1
    fi
    
    declare -a workflow_files=()
    while IFS= read -r -d '' workflow; do
        local basename
        basename=$(basename "$workflow")
        # Only include relevant workflow files
        if [[ "$basename" =~ ^(login|invite|share)- ]]; then
            workflow_files+=("$basename")
            debug "Added workflow: $basename"
        else
            debug "Skipping irrelevant workflow: $basename"
        fi
    done < <(find ".github/workflows" -maxdepth 1 -type f -name "*.yml" -print0 || { error "Find command failed"; exit 1; })
    
    if [[ ${#workflow_files[@]} -eq 0 ]]; then
        error "No workflow files found!"
        error "Contents of .github/workflows: $(ls -la .github/workflows)"
        exit 1
    fi
    
    info "Found ${#workflow_files[@]} workflow files"
    
    # Log all found workflows by type with counts
    info "=== Found Workflows ==="
    declare -a login_files=()
    declare -a share_files=()
    declare -a invite_files=()
    
    for wf in "${workflow_files[@]}"; do
        if [[ "$wf" =~ ^login- ]]; then
            login_files+=("$wf")
        elif [[ "$wf" =~ ^share- ]]; then
            share_files+=("$wf")
        elif [[ "$wf" =~ ^invite- ]]; then
            invite_files+=("$wf")
        fi
    done
    
    info "Login workflows (${#login_files[@]}):"
    for wf in "${login_files[@]}"; do
        info "  - $wf"
    done
    
    info "Share workflows (${#share_files[@]}):"
    for wf in "${share_files[@]}"; do
        info "  - $wf"
    done
    
    info "Invite workflows (${#invite_files[@]}):"
    for wf in "${invite_files[@]}"; do
        info "  - $wf"
    done
    
    # Count of expected workflow types
    login_count=0
    share_count=0
    invite_count=0
    
    info "Found ${#workflow_files[@]} relevant workflows"
    
    # Process and categorize workflows
    for workflow in "${workflow_files[@]}"; do
        # First increment the counters
        case "$workflow" in
            login-*)
                login_count=$((login_count + 1))
                info "Processing login workflow: $workflow"
                ;;
            share-*)
                share_count=$((share_count + 1))
                info "Processing share workflow: $workflow"
                ;;
            invite-*)
                invite_count=$((invite_count + 1))
                info "Processing invite workflow: $workflow"
                ;;
            *)
                warn "Unexpected workflow pattern found: $workflow"
                continue
                ;;
        esac

        # Then process the artifacts
        if ! fetch_workflow_artifacts "$workflow"; then
            error "Failed to process workflow: $workflow"
            continue
        fi
    done
    
    # Report workflow counts
    info "=== Workflow Count Summary ==="
    info "Login workflows: $login_count (expected: 6)"
    info "Share workflows: $share_count (expected: 27)"
    info "Invite workflows: $invite_count (expected: 9)"
    
    # Verify we processed the expected number of workflows
    total=$((login_count + share_count + invite_count))
    info "Total test workflows processed: $total (expected: 42)"
    
    if [ "$total" -ne 42 ]; then
        error "Processed $total workflows but expected 42"
        error "=== Workflow Count Mismatch ==="
        error "Found $login_count login workflows (expected 6)"
        error "Found $share_count share workflows (expected 27)"
        error "Found $invite_count invite workflows (expected 9)"
        exit 1
    fi
    
    # Generate manifest
    generate_manifest
    
    # Debug output
    info "Contents of artifacts directory:"
    ls -R "$ARTIFACTS_DIR"
    
    # Add summary at the end
    info "=== Final Summary ==="
    info "Total workflows processed: $total / 42"
    info "- Login workflows: $login_count / 6"
    info "- Share workflows: $share_count / 27"
    info "- Invite workflows: $invite_count / 9"
    
    # Add disk usage information
    local artifacts_size
    artifacts_size=$(du -sh "$ARTIFACTS_DIR" 2>/dev/null | cut -f1)
    info "Total artifacts size: $artifacts_size"
    
    info "Log file location: $LOG_FILE"
    success "Script completed successfully"
}

main "$@"
