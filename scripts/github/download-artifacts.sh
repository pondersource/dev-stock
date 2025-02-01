#!/bin/bash

set -e  # Exit on error

# Function to download artifacts from a workflow
download_artifacts() {
  local workflow=$1
  echo "Processing workflow: $workflow"
  
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
      workflow_name=$(basename $workflow)
      target_dir="site/static/artifacts/${workflow_name%.*}-$name"
      mkdir -p "$target_dir"
      unzip -o "$tmp_dir/artifact.zip" -d "$target_dir"
      
      # Convert videos to web format
      find "$target_dir" -name "*.mp4" -exec sh -c '
        input="$1"
        output="${input%.mp4}.webm"
        echo "Converting $input to $output"
        ffmpeg -hide_banner -loglevel error -i "$input" -c:v libvpx-vp9 -crf 30 -b:v 0 -b:a 128k -c:a libopus "$output" -y && \
        rm "$input"  # Remove the original MP4 after successful conversion
      ' sh {} \;
      
      # Cleanup
      rm -rf "$tmp_dir"
    done
  fi
}

# Create artifacts directory
mkdir -p site/static/artifacts

# Get all workflow files and process them
gh api repos/pondersource/dev-stock/actions/workflows --jq '.workflows[].path' | while read -r workflow; do
  if echo "$workflow" | grep -qE 'share-|login-|invite-'; then
    echo "Found test workflow: $workflow"
    download_artifacts $(basename "$workflow")
  fi
done

# Generate artifact manifest
echo "Generating artifact manifest..."
find site/static/artifacts -type f -name "*.webm" | jq -R -s 'split("\n")[:-1]' > site/static/artifacts/manifest.json

# Debug output
echo "Contents of artifacts directory:"
ls -R site/static/artifacts 