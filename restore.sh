#!/bin/bash
set -euo pipefail

# --- FILL IN YOUR CREDENTIALS ---
MY_BUCKET="archives-valgui"
MY_PASS="TON_MOT_DE_PASSE_SECRET"
MY_SALT="TON_DEUXIEME_MOT_DE_PASSE_SALT"
DESTINATION="./restored_data"
CLIENT_ID="TON_CLIENT_ID.apps.googleusercontent.com"
CLIENT_SECRET="TON_CLIENT_SECRET"
DRY_RUN=false

# --- SCRIPT ---

usage() {
    echo "Usage: $0 [--dry-run]"
    echo "  --dry-run   List files without downloading (no GCS retrieval fees)"
    exit 0
}

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --help|-h) usage ;;
        *) echo "Unknown option: $arg"; usage ;;
    esac
done

# Check rclone is installed
if ! command -v rclone &>/dev/null; then
    echo "Error: rclone is not installed. Install it first: https://rclone.org/install/"
    exit 1
fi

echo "--- Starting restoration ---"

# Temporary config so we don't depend on any existing rclone setup
export RCLONE_CONFIG="/tmp/rclone_restore.conf"
trap 'rm -f "$RCLONE_CONFIG"' EXIT

# Setup GCS remote
rclone config create gdrive-brut "google cloud storage" \
    client_id "$CLIENT_ID" \
    client_secret "$CLIENT_SECRET" \
    bucket_policy_only true \
    storage_class ARCHIVE

# Setup encrypted (crypt) remote on top of GCS
rclone config create secret crypt \
    remote "gdrive-brut:$MY_BUCKET" \
    password "$MY_PASS" \
    password2 "$MY_SALT"

if $DRY_RUN; then
    echo "Dry run: listing remote contents (decrypted names)..."
    rclone tree secret: --human-readable
    echo "---"
    rclone size secret:
else
    mkdir -p "$DESTINATION"
    echo "Downloading to $DESTINATION..."
    rclone copy secret: "$DESTINATION" -P --transfers 4 --checkers 8
    echo "--- Restoration complete! ---"
fi
