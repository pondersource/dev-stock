#!/bin/bash

set -e  # Exit on error

# Default version if not specified
ZOLA_VERSION=${ZOLA_VERSION:-"0.19.2"}

echo "Installing Zola version ${ZOLA_VERSION}..."

# Download and install Zola
wget -q "https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
tar xzf "zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
sudo mv zola /usr/local/bin

# Verify installation
zola --version

echo "Zola installation complete!"
