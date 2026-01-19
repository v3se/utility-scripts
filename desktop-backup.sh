#!/bin/bash

# This script creates a backup of the user directory
# Add excludes to the excludes array as needed

set -e
set -x

### Configuration ###

# Load secrets from environment file
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ENV_FILE="${SCRIPT_DIR}/.backup-secrets"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Secrets file not found at $ENV_FILE"
    echo "Create it with the following variables:"
    echo "  AWS_ACCESS_KEY_ID"
    echo "  AWS_SECRET_ACCESS_KEY"
    echo "  RESTIC_PASSWORD"
    exit 1
fi

# Source the secrets file
source "$ENV_FILE"

# Backblaze bucket name where to store the backups
B2_BUCKET_NAME="vese-desktop-backup"

# Backblaze B2 S3-compatible endpoint (replace us-west-004 with your region)
B2_ENDPOINT="s3.eu-central-003.backblazeb2.com"

B2_URL="s3:${B2_ENDPOINT}/${B2_BUCKET_NAME}"

# Define directories and files to exclude from backup
EXCLUDES=(
    --exclude='/home/*/.cache'
    --exclude='/home/*/.local/share/Trash'
    --exclude='/home/*/Downloads'
    --exclude='/home/*/.npm'
    --exclude='/home/*/.yarn'
    --exclude='/home/*/node_modules'
    --exclude='/home/*/.docker'
    --exclude='*.tmp'
    --exclude='*.log'
    --exclude='/home/*/.vscode/extensions'
    --exclude='/home/*/.mozilla/firefox/*/cache2'
    --exclude='/home/*/.steam'
    --exclude='/home/*/.local/share/Steam'
)

# Check if restic is installed
if ! command -v restic >/dev/null 2>&1
then
    echo "Restic could not be found. Please install restic to proceed."
    exit 1
fi

# Initialize the restic repository if it does not exist
if ! restic -r ${B2_URL} cat config >/dev/null 2>&1
then
    echo "Repository not initialized. Initializing..."
    restic -r ${B2_URL} init
else
    echo "Repository already initialized."
fi

# Create backup
echo "Starting backup of /home..."
restic -r ${B2_URL} backup /home \
    "${EXCLUDES[@]}" \
    --tag "desktop-backup" \
    --tag "$(hostname)" \
    --verbose

# Verify backup integrity
echo "Verifying backup..."
restic -r ${B2_URL} check --read-data-subset=5%

# Clean up old snapshots
echo "Pruning old snapshots..."
restic -r ${B2_URL} forget \
    --keep-daily 7 \
    --keep-monthly 1 \
    --prune

echo "Backup completed successfully!"