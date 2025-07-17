#!/bin/bash

# Author: Mohammad Mahdi Baghbani Pourvahid <mahdi@pondersource.com>

set -e  # Exit on error

echo "Starting Zola build process..."

# Check if we're in the site directory
if [ ! -d "site" ]; then
    echo "Error: 'site' directory not found"
    exit 1
fi

# Verify required directories exist
required_dirs=(
    "site/templates"
    "site/themes/PonderMatrix/templates"
    "site/content"
    "site/static"
    "site/static/artifacts"
)

for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    fi
done

# Verify required theme files exist
if [ ! -f "site/themes/PonderMatrix/theme.toml" ]; then
    echo "Error: Theme configuration file not found at site/themes/PonderMatrix/theme.toml"
    exit 1
fi

# Build the site
echo "Building Zola site..."
cd site
zola build

echo "Build complete!" 