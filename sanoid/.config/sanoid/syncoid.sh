#!/usr/bin/env bash
# Post-snapshot replication script (invoked by Sanoid post_snapshot_script)
# Generated from datasets listed in datasets.txt 

set -euo pipefail

# Concurrency control
exec 9>/run/syncoid-post.lock
flock -n 9 || exit 0

# Configuration (adjust as needed)
DEST_POOL="zfs-backups"          # Remote root/pool name (update if different)
COMPRESSION="none"              # syncoid --compress value; set 'max' to auto-select; 'none' for no compression
BW_LIMIT="80M"                  # syncoid --target-bwlimit value (empty to disable)
AUTOCREATE_DEST="1"             # If set to 1, auto-create missing destination parent datasets
EXTRA_OPTS=()                    # space for any additional syncoid options (e.g. --sshoption='-o IPQoS=none')
: "${FORCE_DELETE_TARGET:=0}"    # set to 1 to append --force-delete for mismatched targets

LOG="/var/log/syncoid-post.log"
mkdir -p "$(dirname "$LOG")"

log() { printf '[%s] %s\n' "$(date -Is)" "$*" >>"$LOG"; }

# Suppress mbuffer HOME warning: define HOME if unset
if [[ -z "${HOME:-}" ]]; then
  export HOME="/root"
  log "HOME_DEFAULT_APPLIED [VALUE=$HOME]"
fi

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
    gzip|pigz-fast|pigz-slow|zstd-fast|zstd-slow|lz4|xz|lzo|none) : ;; 
    *) log "COMPRESSION_INVALID [VALUE=$COMPRESSION] [FALLBACK=lzo]"; COMPRESSION="lzo" ;; 
  esac
fi
SYNCOID_BASE_OPTS=(--no-sync-snap)
[[ -n $COMPRESSION && $COMPRESSION != max && $COMPRESSION != none ]] && SYNCOID_BASE_OPTS+=("--compress=${COMPRESSION}")
[[ -n ${BW_LIMIT} ]] && SYNCOID_BASE_OPTS+=("--target-bwlimit=${BW_LIMIT}")
SYNCOID_BASE_OPTS+=("${EXTRA_OPTS[@]}")
[[ $FORCE_DELETE_TARGET == 1 ]] && SYNCOID_BASE_OPTS+=("--force-delete")

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
RUN_START=()

start_replication() {
  local ds="$1"
  if [[ $ds != zroot/* ]]; then
    log "Skipping unexpected dataset name '$ds' (does not start with zroot/)"; return 0
  fi
  local dest=${ds/zroot/$DEST_POOL}
  local dest_parent
  dest_parent="${dest%/*}"
  # Pre-flight: ensure destination parent exists (or create if enabled)
  if ! zfs list -H -o name "$dest_parent" >/dev/null 2>&1; then
    if [[ ${AUTOCREATE_DEST:-0} == 1 ]]; then
      if zfs create -p "$dest_parent" >/dev/null 2>&1; then
        log "DEST_PARENT_CREATED [DEST_PARENT=$dest_parent]"
      else
        log "DEST_PARENT_CREATE_FAIL [DEST_PARENT=$dest_parent]"
        return 1
      fi
    else
      log "DEST_PARENT_MISSING [DEST_PARENT=$dest_parent]"
      return 0
    fi
  fi
  if ! zfs list -H -o name "$dest" >/dev/null 2>&1; then
    if [[ ${AUTOCREATE_DEST:-0} == 1 ]]; then
      if zfs create -p "$dest" >/dev/null 2>&1; then
        log "DEST_CREATED [DEST=$dest]"
      else
        log "DEST_CREATE_FAIL [DEST=$dest]"
        return 1
      fi
    else
      log "DEST_MISSING [DEST=$dest]"
      return 0
    fi
  fi
  # Guard: ensure source has at least one snapshot to replicate
  if ! zfs list -t snapshot -o name -r "$ds" | grep -q '@'; then
    log "NO_SOURCE_SNAPSHOTS [DATASET=$ds]"; return 0
  fi
  log "START [DATASET=$ds] [DEST=$dest] [COMP=$COMPRESSION]"
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
  local i pid
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
