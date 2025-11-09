#!/usr/bin/env bash
# Post-snapshot replication script (invoked by Sanoid post_snapshot_script)
# Generated from datasets listed in datasets.txt 

set -euo pipefail

# Concurrency control
exec 9>/run/syncoid-post.lock
flock -n 9 || exit 0

# Configuration (adjust as needed)
DEST_POOL="zfs-remote"          # Remote root/pool name (update if different)
COMPRESSION="max"               # syncoid --compress value (set 'max' to auto-select highest available)
BW_LIMIT="80M"                  # syncoid --target-bwlimit value (empty to disable)
EXTRA_OPTS=()                    # space for any additional syncoid options (e.g. --sshoption='-o IPQoS=none')

LOG="/var/log/syncoid-post.log"
mkdir -p "$(dirname "$LOG")"

log() { printf '[%s] %s\n' "$(date -Is)" "$*" >>"$LOG"; }

# Base syncoid options
# Accepted values: gzip, pigz-fast, pigz-slow, zstd-fast, zstd-slow, lz4, xz, lzo (default)
if [[ $COMPRESSION == max ]]; then
  help_out="$(syncoid --help 2>&1 || true)"
  for c in xz zstd-slow pigz-slow gzip zstd-fast pigz-fast lz4 lzo; do
    if grep -Eiq "(compress[^\n]*\b${c}\b|--compress[ =]${c}\b)" <<<"$help_out"; then
      COMPRESSION="$c"; break
    fi
  done
  log "COMPRESSION_AUTOSELECT [VALUE=$COMPRESSION]"
fi
if [[ $COMPRESSION != max ]]; then
  case "$COMPRESSION" in
    gzip|pigz-fast|pigz-slow|zstd-fast|zstd-slow|lz4|xz|lzo) : ;; 
    *) log "COMPRESSION_INVALID [VALUE=$COMPRESSION] [FALLBACK=lzo]"; COMPRESSION="lzo" ;; 
  esac
fi
SYNCOID_BASE_OPTS=(--no-sync-snap)
[[ -n $COMPRESSION && $COMPRESSION != max ]] && SYNCOID_BASE_OPTS+=("--compress=${COMPRESSION}")
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

# Concurrency (number of simultaneous syncoid processes); default 2
CONCURRENT="${CONCURRENT:-2}"

RUN_PIDS=()
RUN_SRC=()
RUN_DEST=()

start_replication() {
  local ds="$1"
  if [[ $ds != zroot/* ]]; then
    log "Skipping unexpected dataset name '$ds' (does not start with zroot/)"; return 0
  fi
  local dest=${ds/zroot/$DEST_POOL}
  log "START [DATASET=$ds] [DEST=$dest]"
  # Launch syncoid in background; stdout/stderr already appended to LOG
  if syncoid "${SYNCOID_BASE_OPTS[@]}" "$ds" "$dest" >>"$LOG" 2>&1 & then
    RUN_PIDS+=("$!")
    RUN_SRC+=("$ds")
    RUN_DEST+=("$dest")
    RUN_START+=("$(date +%s)")
  else
    log "FAIL_START [DATASET=$ds] [DEST=$dest]"
    fail=1
  fi
}

wait_batch() {
  local i pid rc
  for i in "${!RUN_PIDS[@]}"; do
    pid=${RUN_PIDS[$i]}
    if wait "$pid"; then
      log "SUCCESS [DATASET=${RUN_SRC[$i]}] [DEST=${RUN_DEST[$i]}] [DURATION=$(($(date +%s)-${RUN_START[$i]}))s]"
    else
      log "FAIL [DATASET=${RUN_SRC[$i]}] [DEST=${RUN_DEST[$i]}] [DURATION=$(($(date +%s)-${RUN_START[$i]}))s]"
      fail=1
    fi
  done
  RUN_PIDS=()
  RUN_SRC=()
RUN_DEST=()
RUN_START=()
}

for ds in "${DATASETS[@]}"; do
  start_replication "$ds"
  if (( CONCURRENT > 1 )) && (( ${#RUN_PIDS[@]} >= CONCURRENT )); then
    wait_batch
  fi
  # Sequential mode if CONCURRENT <=1: batch flush immediately
  if (( CONCURRENT <= 1 )); then
    wait_batch
  fi
done
# Flush any remaining background jobs
wait_batch

if (( fail == 0 )); then
  log "SUMMARY [STATUS=success] [TOTAL=${#DATASETS[@]}]"
else
  log "SUMMARY [STATUS=failures] [TOTAL=${#DATASETS[@]}]"
fi

exit "$fail"
