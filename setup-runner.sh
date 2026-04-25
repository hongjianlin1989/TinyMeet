#!/bin/bash
# Self-hosted runner setup script for TinyMeet-iOS
# Run this in Terminal on your Mac

set -e

RUNNER_DIR="$HOME/actions-runner"
REPO_URL="https://github.com/TinyMeet-Org/TinyMeet-iOS"

echo "=== Setting up GitHub Actions self-hosted runner ==="

# Create runner directory
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

# Download runner (macOS x64)
if [ ! -factions-runner.tar.gz ]; then
    echo "Downloading actions runner..."
    curl -o actions-runner.tar.gz https://github.com/actions/runner/releases/download/v2.321.0/actions-runner-osx-x64-2.321.0.tar.gz
fi

# Extract
echo "Extracting..."
tar xzf actions-runner.tar.gz

# Configure runner
# NOTE: Get token from https://github.com/TinyMeet-Org/TinyMeet-iOS/settings/actions/runners/new
# Then fill it below or pass as argument
TOKEN="${1:-YOUR_TOKEN_HERE}"

if [ "$TOKEN" = "YOUR_TOKEN_HERE" ]; then
    echo "ERROR: Please provide runner token as argument or edit this script"
    echo "Get token from: $REPO_URL/settings/actions/runners/new"
    exit 1
fi

echo "Configuring runner..."
./config.sh --url "$REPO_URL" --token "$TOKEN" --labels "self-hosted,macos,x86-64" --name "macos-local"

# Install and start as service
echo "Installing service..."
./svc.sh install
./svc.sh start

echo "=== Runner setup complete ==="
echo "Check status at: $REPO_URL/settings/actions/runners"