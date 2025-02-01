#!/bin/bash

set -e  # Exit on error

# Function to sanitize workflow name for consistent file naming
sanitize_name() {
    echo "$1" | sed -E 's/\.(yml|yaml)$//' | tr '[:upper:]' '[:lower:]'
}

# Function to generate video thumbnail
generate_thumbnail() {
    local video="$1"
    local thumbnail="${video%.*}.jpg"
    echo "Generating thumbnail for $video"
    ffmpeg -hide_banner -loglevel error -i "$video" -vf "select=eq(n\,0)" -vframes 1 "$thumbnail"
}

# Function to download artifacts from a workflow
download_artifacts() {
    local workflow=$1
    local workflow_name=$(sanitize_name "$workflow")
    echo "Processing workflow: $workflow_name"
    
    # Get the latest workflow run ID
    latest_run=$(gh api repos/pondersource/dev-stock/actions/workflows/$workflow/runs --jq '.workflow_runs[0].id')
    if [ -n "$latest_run" ]; then
        echo "Latest run ID: $latest_run"
        
        # Get artifacts for this run
        artifacts_json=$(gh api repos/pondersource/dev-stock/actions/runs/$latest_run/artifacts)
        
        # Process each artifact
        echo "$artifacts_json" | jq -r '.artifacts[] | "\(.id) \(.name)"' | while read -r id name; do
            echo "Downloading artifact $name (ID: $id)"
            
            # Create a temporary directory for this artifact
            tmp_dir=$(mktemp -d)
            
            # Download the artifact
            gh api repos/pondersource/dev-stock/actions/artifacts/$id/zip -H "Accept: application/vnd.github+json" > "$tmp_dir/artifact.zip"
            
            # Extract to the appropriate directory
            target_dir="site/static/artifacts/$workflow_name"
            mkdir -p "$target_dir"
            unzip -o "$tmp_dir/artifact.zip" -d "$target_dir"
            
            # Process videos
            find "$target_dir" -name "*.mp4" -exec sh -c '
                input="$1"
                # Create a simpler filename
                new_name="$(dirname "$input")/recording.mp4"
                mv "$input" "$new_name"
                
                # Convert to WebM
                output="${new_name%.mp4}.webm"
                echo "Converting $new_name to $output"
                ffmpeg -hide_banner -loglevel error -i "$new_name" \
                    -c:v libvpx-vp9 -crf 30 -b:v 0 -b:a 128k -c:a libopus "$output" -y
                
                # Generate thumbnail
                thumbnail="${new_name%.mp4}.jpg"
                echo "Generating thumbnail for $output"
                ffmpeg -hide_banner -loglevel error -i "$output" \
                    -vf "select=eq(n\,0),scale=640:-1" -vframes 1 "$thumbnail"
                
                # Remove original MP4
                rm "$new_name"
            ' sh {} \;
            
            # Cleanup
            rm -rf "$tmp_dir"
        done
    fi
}

# Create artifacts directory and placeholder image directory
mkdir -p site/static/artifacts
mkdir -p site/static/images

# Get all workflow files and process them
gh api repos/pondersource/dev-stock/actions/workflows --jq '.workflows[].path' | while read -r workflow; do
    if echo "$workflow" | grep -qE 'share-|login-|invite-'; then
        echo "Found test workflow: $workflow"
        download_artifacts $(basename "$workflow")
    fi
done

# Generate artifact manifest with proper paths
echo "Generating artifact manifest..."
echo "{" > site/static/artifacts/manifest.json
echo "  \"videos\": [" >> site/static/artifacts/manifest.json
find site/static/artifacts -type f -name "*.webm" | sort | while read -r file; do
    rel_path="${file#site/static/}"
    thumb_path="${file%.webm}.jpg"
    rel_thumb="${thumb_path#site/static/}"
    workflow_name=$(echo "$file" | grep -oP 'artifacts/\K[^/]+')
    echo "    {" >> site/static/artifacts/manifest.json
    echo "      \"workflow\": \"$workflow_name\"," >> site/static/artifacts/manifest.json
    echo "      \"video\": \"$rel_path\"," >> site/static/artifacts/manifest.json
    echo "      \"thumbnail\": \"$rel_thumb\"" >> site/static/artifacts/manifest.json
    echo "    }," >> site/static/artifacts/manifest.json
done
# Remove last comma and close JSON
sed -i '$ s/,$//' site/static/artifacts/manifest.json
echo "  ]" >> site/static/artifacts/manifest.json
echo "}" >> site/static/artifacts/manifest.json

# Debug output
echo "Contents of artifacts directory:"
ls -R site/static/artifacts 