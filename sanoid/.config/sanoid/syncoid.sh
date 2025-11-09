#!/usr/bin/env bash
# Post-snapshot replication script (invoked by Sanoid post_snapshot_script)
# Generated from datasets listed in datasets.txt 

set -euo pipefail

# Concurrency control
exec 9>/run/syncoid-post.lock
flock -n 9 || exit 0

# Configuration (adjust as needed)
DEST_POOL="zfs-remote"          # Remote root/pool name (update if different)
COMPRESSION="zstd-max"          # syncoid --compress value
BW_LIMIT="80M"                  # syncoid --target-bwlimit value (empty to disable)
EXTRA_OPTS=()                    # space for any additional syncoid options (e.g. --sshoption='-o IPQoS=none')

LOG="/var/log/syncoid-post.log"
mkdir -p "$(dirname "$LOG")"

log() { printf '[%s] %s\n' "$(date -Is)" "$*" >>"$LOG"; }

# Base syncoid options
SYNCOID_BASE_OPTS=(--no-sync-snap "--compress=${COMPRESSION}")
[[ -n ${BW_LIMIT} ]] && SYNCOID_BASE_OPTS+=("--target-bwlimit=${BW_LIMIT}")
SYNCOID_BASE_OPTS+=("${EXTRA_OPTS[@]}")

# Load dataset list dynamically from datasets.txt (ignore comments / blanks)
DATASET_FILE="/home/styxut/.dotfiles/sanoid/.config/sanoid/datasets.txt"
if [[ -r "$DATASET_FILE" ]]; then
  mapfile -t DATASETS < <(grep -Ev '^(#|\s*$)' "$DATASET_FILE")
else
  log "Dataset file not readable: $DATASET_FILE"; exit 1
fi
log "Loaded ${#DATASETS[@]} datasets from $DATASET_FILE"

# Fail counter
fail=0
log "Starting syncoid replication for ${#DATASETS[@]} datasets"

# Ensure syncoid present
if ! command -v syncoid >/dev/null 2>&1; then
  log "syncoid not found in PATH"; exit 1
fi

for ds in "${DATASETS[@]}"; do
  # Derive destination by replacing leading 'zroot' with DEST_POOL
  if [[ $ds != zroot/* ]]; then
    log "Skipping unexpected dataset name '$ds' (does not start with zroot/)"; continue
  fi
  dest=${ds/zroot/$DEST_POOL}
  log "Replicating $ds -> $dest"
  if syncoid "${SYNCOID_BASE_OPTS[@]}" "$ds" "$dest" >>"$LOG" 2>&1; then
    log "SUCCESS $ds -> $dest"
  else
    log "FAIL $ds -> $dest"
    fail=1
  fi
done

if (( fail == 0 )); then
  log "All replications completed successfully"
else
  log "Replication completed with failures"
fi

exit "$fail"
