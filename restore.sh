#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
DRY_RUN=false

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: .env file not found at $ENV_FILE"
    echo "Copy .env.example to .env and fill in your credentials."
    exit 1
fi
source "$ENV_FILE"

# Resolve relative SERVICE_ACCOUNT_FILE to absolute path
[[ "$SERVICE_ACCOUNT_FILE" != /* ]] && SERVICE_ACCOUNT_FILE="$SCRIPT_DIR/$SERVICE_ACCOUNT_FILE"

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

# Check service account key exists
if [[ ! -f "$SERVICE_ACCOUNT_FILE" ]]; then
    echo "Error: service account key not found at $SERVICE_ACCOUNT_FILE"
    exit 1
fi

echo "--- Starting restoration ---"

# Temporary config so we don't depend on any existing rclone setup
export RCLONE_CONFIG="/tmp/rclone_restore.conf"
trap 'rm -f "$RCLONE_CONFIG"' EXIT

# Setup GCS remote with service account (no OAuth needed)
rclone config create gdrive-brut "google cloud storage" \
    service_account_file "$SERVICE_ACCOUNT_FILE" \
    bucket_policy_only true \
    storage_class ARCHIVE \
    --non-interactive

# Setup encrypted (crypt) remote on top of GCS
rclone config create secret crypt \
    remote "gdrive-brut:$MY_BUCKET" \
    password "$MY_PASS" \
    password2 "$MY_SALT"

if $DRY_RUN; then
    echo "Dry run: checking raw access to bucket..."
    rclone lsd gdrive-brut:"$MY_BUCKET" && echo "OK: bucket accessible" || echo "FAIL: cannot access bucket"
    echo "---"
    echo "Listing decrypted contents..."
    rclone tree secret: --human-readable
    echo "---"
    rclone size secret:
else
    mkdir -p "$DESTINATION"
    echo "Downloading to $DESTINATION..."
    rclone copy secret: "$DESTINATION" -P --transfers 4 --checkers 8
    echo "--- Restoration complete! ---"
fi
