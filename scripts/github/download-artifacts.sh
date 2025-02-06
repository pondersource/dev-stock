#!/bin/bash

# download-artifacts.sh
#
# Downloads and processes video artifacts from GitHub Actions test workflows.
# Generates AVIF thumbnails.
#
# Key features:
# - Ensures artifacts are from the same commit (COMMIT_SHA)
# - Processes 42 test workflows (6 login, 27 share, 9 invite)
# - Generates manifest.json for website consumption
#
# Requirements: gh, jq, ffmpeg, unzip, zip

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

# Get human readable file size in KiB format
human_size() {
    # If no argument is provided or if it's not a number, return '0 KiB'
    local size
    size="${1:-0}"
    if ! [[ "$size" =~ ^[0-9]+$ ]]; then
        echo "0 KiB"
        return
    fi
    
    if ((size < 1024)); then
        echo "${size} B"
    elif ((size < 1048576)); then
        # Convert to KiB with one decimal place
        local kib=$(echo "scale=1; $size/1024" | bc)
        echo "${kib} KiB"
    elif ((size < 1073741824)); then
        # Convert to MiB with one decimal place
        local mib=$(echo "scale=1; $size/1048576" | bc)
        echo "${mib} MiB"
    else
        # Convert to GiB with one decimal place
        local gib=$(echo "scale=1; $size/1073741824" | bc)
        echo "${gib} GiB"
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
    for cmd in gh jq ffmpeg unzip zip; do
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
    
    # Generate thumbnail
    info "Generating thumbnail for $new_name"
    local thumbnail_file
    if ! thumbnail_file=$(generate_thumbnail "$new_name"); then
        error "Failed to generate thumbnail"
        return 1
    fi
    local thumb_size
    thumb_size=$(stat -f%z "$thumbnail_file" 2>/dev/null || stat -c%s "$thumbnail_file")
    success "Generated thumbnail at $thumbnail_file ($(human_size $thumb_size))"
    
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
    local downloaded_count=0
    local video_count=0
    echo "$artifacts_json" | jq -r '.artifacts[] | "\(.id) \(.name) \(.size_in_bytes // 0)"' | while read -r id name size; do
        ((processed_count++))
        info "Downloading artifact $name (ID: $id, Size: $(human_size ${size:-0})) [$processed_count/$artifact_count]"
        
        # Create a temporary directory for this artifact
        local tmp_dir
        tmp_dir=$(mktemp -d)
        TEMP_DIRS+=("$tmp_dir")
        
        # Download with progress indication and error checking
        debug "Downloading to temporary directory: $tmp_dir"
        if ! gh api "repos/pondersource/dev-stock/actions/artifacts/$id/zip" \
            -H "Accept: application/vnd.github+json" > "$tmp_dir/artifact.zip"; then
            error "Failed to download artifact $id"
            rm -rf "$tmp_dir"
            continue
        fi
        ((downloaded_count++))
        
        # Get actual downloaded size and verify
        local downloaded_size
        downloaded_size=$(stat -f%z "$tmp_dir/artifact.zip" 2>/dev/null || stat -c%s "$tmp_dir/artifact.zip" 2>/dev/null || echo 0)
        if [[ $downloaded_size -eq 0 ]]; then
            error "Downloaded artifact $id is empty"
            rm -rf "$tmp_dir"
            continue
        fi
        debug "Downloaded size: $(human_size ${downloaded_size:-0})"
        
        # Extract with size information and error checking
        local target_dir="$ARTIFACTS_DIR/$workflow_name"
        mkdir -p "$target_dir"
        debug "Extracting to $target_dir"
        if ! unzip -o "$tmp_dir/artifact.zip" -d "$target_dir" 2>/dev/null; then
            error "Failed to extract artifact $id"
            rm -rf "$tmp_dir"
            continue
        fi
        
        # Process videos with enhanced logging
        while IFS= read -r -d '' video; do
            ((video_count++))
            if ! process_video "$video"; then
                error "Failed to process video: $video"
                continue
            fi
            info "Successfully processed video $video_count from artifact $name"
        done < <(find "$target_dir" -type f \( -name "*.mp4" -o -name "*.webm" \) -print0)
        
        # Cleanup
        rm -rf "$tmp_dir"
        for i in "${!TEMP_DIRS[@]}"; do
            if [[ ${TEMP_DIRS[i]} = "$tmp_dir" ]]; then
                unset 'TEMP_DIRS[i]'
                break
            fi
        done
    done
    
    info "Artifact processing summary for $workflow_name:"
    info "- Processed artifacts: $processed_count"
    info "- Successfully downloaded: $downloaded_count"
    info "- Videos processed: $video_count"
    
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
            # Find all WebM videos and their thumbnails
            while IFS= read -r -d '' video; do
                local rel_video="${video#site/static/}"
                local thumbnail="${video%.webm}.avif"
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
            done < <(find "$workflow_dir" -type f -name "*.webm" -print0)
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

# Create a combined zip file of all test artifacts
create_combined_zip() {
    info "Creating combined zip file of all test artifacts..."
    local zip_file="$ARTIFACTS_DIR/ocm-tests-all.zip"
    local temp_dir
    temp_dir=$(mktemp -d)
    TEMP_DIRS+=("$temp_dir")

    # Copy all workflow artifacts to temp directory
    for workflow in "${workflow_files[@]}"; do
        local workflow_name
        workflow_name=$(sanitize_name "$workflow")
        local workflow_dir="$ARTIFACTS_DIR/$workflow_name"
        
        if [[ -d "$workflow_dir" ]]; then
            # Create workflow directory in temp
            mkdir -p "$temp_dir/$workflow_name"
            
            # Copy original MP4 files
            find "$workflow_dir" -name "recording.mp4" -exec cp {} "$temp_dir/$workflow_name/" \;
        fi
    done

    # Create zip file
    (cd "$temp_dir" && zip -r "$zip_file" .)
    
    if [[ -f "$zip_file" ]]; then
        local zip_size
        zip_size=$(stat -f%z "$zip_file" 2>/dev/null || stat -c%s "$zip_file")
        success "Created combined zip file: $zip_file ($(human_size ${zip_size:-0}))"
    else
        error "Failed to create combined zip file"
        return 1
    fi
}

# Create platform-specific zip bundles
create_platform_bundles() {
    info "Creating platform-specific zip bundles..."
    local base_dir="$ARTIFACTS_DIR/bundles"
    mkdir -p "$base_dir"
    
    # Define platform combinations
    declare -A platforms=(
        ["nextcloud"]="nc"
        ["owncloud"]="oc"
        ["sciencemesh"]="sm"
        ["seafile"]="sf"
        ["ocis"]="ocis"
        ["cernbox"]="cb"
    )
    
    # Create temp directory for each platform combination
    for platform in "${!platforms[@]}"; do
        local temp_dir
        temp_dir=$(mktemp -d)
        TEMP_DIRS+=("$temp_dir")
        local platform_code="${platforms[$platform]}"
        
        info "Processing $platform tests..."
        
        # Find workflows containing the platform code
        for workflow in "${workflow_files[@]}"; do
            if [[ "$workflow" =~ $platform_code ]]; then
                local workflow_name
                workflow_name=$(sanitize_name "$workflow")
                local workflow_dir="$ARTIFACTS_DIR/$workflow_name"
                
                if [[ -d "$workflow_dir" ]]; then
                    mkdir -p "$temp_dir/$workflow_name"
                    find "$workflow_dir" -name "recording.mp4" -exec cp {} "$temp_dir/$workflow_name/" \;
                fi
            fi
        done
        
        # Create zip file for this platform
        local zip_file="$base_dir/ocm-tests-$platform.zip"
        (cd "$temp_dir" && zip -r "$zip_file" .)
        
        if [[ -f "$zip_file" ]]; then
            local zip_size
            zip_size=$(stat -f%z "$zip_file" 2>/dev/null || stat -c%s "$zip_file")
            success "Created $platform bundle: $zip_file ($(human_size ${zip_size:-0}))"
        fi
    done
}

# Create test-type specific bundles
create_test_type_bundles() {
    info "Creating test-type specific bundles..."
    local base_dir="$ARTIFACTS_DIR/bundles"
    mkdir -p "$base_dir"
    
    # Define test types
    declare -a types=("login" "share" "invite")
    
    for type in "${types[@]}"; do
        local temp_dir
        temp_dir=$(mktemp -d)
        TEMP_DIRS+=("$temp_dir")
        
        info "Processing $type tests..."
        
        # Find workflows of this type
        for workflow in "${workflow_files[@]}"; do
            if [[ "$workflow" =~ ^$type- ]]; then
                local workflow_name
                workflow_name=$(sanitize_name "$workflow")
                local workflow_dir="$ARTIFACTS_DIR/$workflow_name"
                
                if [[ -d "$workflow_dir" ]]; then
                    mkdir -p "$temp_dir/$workflow_name"
                    find "$workflow_dir" -name "recording.mp4" -exec cp {} "$temp_dir/$workflow_name/" \;
                fi
            fi
        done
        
        # Create zip file for this test type
        local zip_file="$base_dir/ocm-tests-$type.zip"
        (cd "$temp_dir" && zip -r "$zip_file" .)
        
        if [[ -f "$zip_file" ]]; then
            local zip_size
            zip_size=$(stat -f%z "$zip_file" 2>/dev/null || stat -c%s "$zip_file")
            success "Created $type tests bundle: $zip_file ($(human_size ${zip_size:-0}))"
        fi
    done
}

# Create result-specific bundles based on workflow status
create_result_bundles() {
    info "Creating result-specific bundles..."
    local base_dir="$ARTIFACTS_DIR/bundles"
    mkdir -p "$base_dir"
    local status_file="$ARTIFACTS_DIR/workflow-status.json"
    
    # Create temp directories for success/failure
    local success_dir
    success_dir=$(mktemp -d)
    TEMP_DIRS+=("$success_dir")
    local failed_dir
    failed_dir=$(mktemp -d)
    TEMP_DIRS+=("$failed_dir")
    
    # Process each workflow based on its status
    jq -r 'to_entries[] | "\(.key) \(.value.conclusion)"' "$status_file" | while read -r workflow status; do
        local workflow_name
        workflow_name=$(sanitize_name "$workflow")
        local workflow_dir="$ARTIFACTS_DIR/$workflow_name"
        
        if [[ -d "$workflow_dir" ]]; then
            local target_dir
            if [[ "$status" == "success" ]]; then
                target_dir="$success_dir/$workflow_name"
            else
                target_dir="$failed_dir/$workflow_name"
            fi
            
            mkdir -p "$target_dir"
            find "$workflow_dir" -name "recording.mp4" -exec cp {} "$target_dir/" \;
        fi
    done
    
    # Create success/failure zip files
    for result in "success" "failed"; do
        local source_dir
        if [[ "$result" == "success" ]]; then
            source_dir="$success_dir"
        else
            source_dir="$failed_dir"
        fi
        
        local zip_file="$base_dir/ocm-tests-$result.zip"
        (cd "$source_dir" && zip -r "$zip_file" .)
        
        if [[ -f "$zip_file" ]]; then
            local zip_size
            zip_size=$(stat -f%z "$zip_file" 2>/dev/null || stat -c%s "$zip_file")
            success "Created $result tests bundle: $zip_file ($(human_size ${zip_size:-0}))"
        fi
    done
}

# Create category-specific bundles based on workflow types
create_category_bundles() {
    info "Creating category-specific bundles..."
    local base_dir="$ARTIFACTS_DIR/bundles"
    mkdir -p "$base_dir"

    # Define test categories and their workflow patterns
    declare -A categories=(
        ["auth"]="login-"
        ["share-link"]="share-link-"
        ["share-with"]="share-with-"
        ["sciencemesh"]="invite-"
    )

    for category in "${!categories[@]}"; do
        local pattern="${categories[$category]}"
        local temp_dir
        temp_dir=$(mktemp -d)
        TEMP_DIRS+=("$temp_dir")

        info "Processing $category category tests..."

        # Find workflows matching this category's pattern
        for workflow in "${workflow_files[@]}"; do
            if [[ "$workflow" =~ ^$pattern ]]; then
                local workflow_name
                workflow_name=$(sanitize_name "$workflow")
                local workflow_dir="$ARTIFACTS_DIR/$workflow_name"

                if [[ -d "$workflow_dir" ]]; then
                    mkdir -p "$temp_dir/$workflow_name"
                    find "$workflow_dir" -name "recording.mp4" -exec cp {} "$temp_dir/$workflow_name/" \;
                fi
            fi
        done

        # Create zip file for this category
        local zip_file="$base_dir/ocm-tests-$category.zip"
        (cd "$temp_dir" && zip -r "$zip_file" .)

        if [[ -f "$zip_file" ]]; then
            local zip_size
            zip_size=$(stat -f%z "$zip_file" 2>/dev/null || stat -c%s "$zip_file")
            success "Created $category category bundle: $zip_file ($(human_size ${zip_size:-0}))"
        fi
    done
}

# Create bundle sizes JSON file
generate_bundle_sizes() {
    info "Generating bundle sizes JSON file..."
    local base_dir="$ARTIFACTS_DIR/bundles"
    local sizes_file="$ARTIFACTS_DIR/bundle-sizes.json"
    local temp_sizes_file="/tmp/temp_sizes_$$.json"
    
    echo "{}" > "$temp_sizes_file"
    
    # Process each bundle file
    while IFS= read -r -d '' bundle; do
        local bundle_name
        bundle_name=$(basename "$bundle")
        local bundle_size
        bundle_size=$(stat -f%z "$bundle" 2>/dev/null || stat -c%s "$bundle")
        local human_bundle_size
        human_bundle_size=$(human_size "$bundle_size")
        
        # Add to JSON
        jq --arg name "$bundle_name" \
           --arg size "$human_bundle_size" \
           --arg bytes "$bundle_size" \
           '. + {($name): {"size": $size, "bytes": $bytes}}' "$temp_sizes_file" > "${temp_sizes_file}.tmp" \
           && mv "${temp_sizes_file}.tmp" "$temp_sizes_file"
        
        debug "Added size for bundle: $bundle_name ($human_bundle_size)"
    done < <(find "$base_dir" -type f -name "ocm-tests-*.zip" -print0)
    
    # Move the final file to its destination
    mv "$temp_sizes_file" "$sizes_file"
    
    if [[ -f "$sizes_file" ]]; then
        success "Generated bundle sizes file: $sizes_file"
        debug "Bundle sizes file contents:"
        debug "$(cat "$sizes_file")"
    else
        error "Failed to generate bundle sizes file"
        return 1
    fi
}

# Enhanced main function with summary statistics
main() {
    # Set up error handling with line numbers
    set -E
    trap 'error "Error on line $LINENO. Command: $BASH_COMMAND"' ERR
    trap cleanup EXIT
    
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
    for dir in "$ARTIFACTS_DIR" "$IMAGES_DIR" "$ARTIFACTS_DIR/bundles"; do
        if ! mkdir -p "$dir" 2>/dev/null; then
            error "Failed to create directory: $dir"
            error "Current permissions: $(ls -ld "$(dirname "$dir")" 2>/dev/null || echo 'Cannot read parent directory')"
            exit 1
        fi
    done
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
    
    # Create all zip bundles
    create_combined_zip
    create_platform_bundles
    create_test_type_bundles
    create_result_bundles
    create_category_bundles

    # Generate bundle sizes JSON
    generate_bundle_sizes
    
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
