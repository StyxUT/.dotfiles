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
BW_LIMIT="90M"                  # syncoid --target-bwlimit value (empty to disable)
CONCURRENT="1"                  # number of simultaneous syncoid processes (override via env CONCURRENT)
AUTOCREATE_DEST="1"             # If set to 1, auto-create missing destination parent datasets
EXTRA_OPTS=()                    # space for any additional syncoid options (e.g. --sshoption='-o IPQoS=none')
: "${FORCE_DELETE_TARGET:=0}"    # set to 1 to append --force-delete for mismatched targets
: "${REPLICATE_SNAP_CLASSES:=daily monthly}"  # space-separated allowed classes (suffixes)
: "${REPLICATE_FORCE:=0}"                    # set 1 to force replication regardless of snapshot class

LOG="/var/log/syncoid-post.log"
mkdir -p "$(dirname "$LOG")"

log() { printf '[%s] %s\n' "$(date -Is)" "$*" >>"$LOG"; }

# Snapshot class gating (skip frequently/hourly unless allowed)
select_snapshot_name() {
  local v
  for v in SNAPSHOT_NAME SANOID_SNAP_NAME SANOID_SNAPNAME; do
    if [[ -n "${!v:-}" ]]; then
      echo "${!v}"; return 0
    fi
  done
  return 1
}
should_replicate() {
  local name class allowed
  if [[ ${REPLICATE_FORCE} == 1 ]]; then
    log "REPLICATE_FORCE_ENABLED"; return 0
  fi
  name=$(select_snapshot_name || true)
  if [[ -z $name ]]; then
    # If no name supplied, be conservative and replicate
    log "SNAPSHOT_NAME_MISSING_REPLICATE"; return 0
  fi
  if [[ $name =~ _([a-zA-Z]+)$ ]]; then
    class="${BASH_REMATCH[1]}"
  else
    log "SNAPSHOT_NAME_PARSE_FAIL [NAME=$name]"; return 0
  fi
  for allowed in $REPLICATE_SNAP_CLASSES; do
    if [[ $class == "$allowed" ]]; then
      log "SNAPSHOT_CLASS_ALLOWED [NAME=$name] [CLASS=$class]"; return 0
    fi
  done
  log "SKIP_SNAPSHOT_CLASS [NAME=$name] [CLASS=$class] [ALLOWED='$REPLICATE_SNAP_CLASSES']"; return 1
}
if ! should_replicate; then
  exit 0
fi

# iSCSI / pool import configuration
: "${ISCSI_ENABLE:=1}"          # set 0 to disable iSCSI workflow
: "${ISCSI_TARGET_IQN:=iqn.2000-01.com.synology:Synology.default-target.f81f38e3406}"       # e.g. iqn.2025-11.com.example:backup
: "${ISCSI_PORTAL:=synology.home}"           # e.g. 192.0.2.10:3260
: "${ISCSI_DEVICE_WAIT:=60}"    # seconds to wait for pool import availability
: "${ISCSI_EXPORT_ON_EXIT:=1}"  # export pool we imported on exit
: "${ISCSI_LOGOUT_ON_EXIT:=1}"  # logout iSCSI session on exit

POOL_IMPORTED_FLAG=0             # will be set to 1 if we import the pool here
ISCSI_LOGGED_IN=0

# Suppress mbuffer HOME warning: define HOME if unset
if [[ -z "${HOME:-}" ]]; then
  export HOME="/root"
  log "HOME_DEFAULT_APPLIED [VALUE=$HOME]"
fi

iscsi_login() {
  if [[ ${ISCSI_ENABLE} != 1 ]]; then
    return 0
  fi
  if [[ -z $ISCSI_TARGET_IQN || -z $ISCSI_PORTAL ]]; then
    log "ISCSI_CONFIG_MISSING [TARGET_IQN=$ISCSI_TARGET_IQN] [PORTAL=$ISCSI_PORTAL]"
    return 1
  fi
  if ! command -v iscsiadm >/dev/null 2>&1; then
    log "ISCSIADM_NOT_FOUND"; return 1
  fi
  # Conditional discovery only if node entry missing
  if ! iscsiadm -m node -T "$ISCSI_TARGET_IQN" -p "$ISCSI_PORTAL" -o show >/dev/null 2>&1; then
    log "ISCSI_DISCOVERY [PORTAL=$ISCSI_PORTAL]"
    if ! iscsiadm -m discovery -t sendtargets -p "$ISCSI_PORTAL" >>"$LOG" 2>&1; then
      log "ISCSI_DISCOVERY_FAIL [PORTAL=$ISCSI_PORTAL]"; return 1
    fi
  fi
  log "ISCSI_LOGIN [TARGET=$ISCSI_TARGET_IQN] [PORTAL=$ISCSI_PORTAL]"
  if iscsiadm -m node -T "$ISCSI_TARGET_IQN" -p "$ISCSI_PORTAL" --login >>"$LOG" 2>&1; then
    ISCSI_LOGGED_IN=1
    log "ISCSI_LOGIN_SUCCESS [TARGET=$ISCSI_TARGET_IQN]"
  else
    log "ISCSI_LOGIN_FAIL [TARGET=$ISCSI_TARGET_IQN]"
    return 1
  fi
}

iscsi_logout() {
  if [[ ${ISCSI_ENABLE} != 1 || ${ISCSI_LOGGED_IN} != 1 ]]; then
    return 0
  fi
  log "ISCSI_LOGOUT [TARGET=$ISCSI_TARGET_IQN] [PORTAL=$ISCSI_PORTAL]"
  if iscsiadm -m node -T "$ISCSI_TARGET_IQN" -p "$ISCSI_PORTAL" --logout >>"$LOG" 2>&1; then
    log "ISCSI_LOGOUT_SUCCESS [TARGET=$ISCSI_TARGET_IQN]"
  else
    log "ISCSI_LOGOUT_FAIL [TARGET=$ISCSI_TARGET_IQN]"
  fi
}

ensure_pool_import() {
  if [[ ${ISCSI_ENABLE} != 1 ]]; then
    return 0
  fi
  # If pool already imported we skip import
  if zpool list -H -o name "$DEST_POOL" >/dev/null 2>&1; then
    log "POOL_ALREADY_IMPORTED [POOL=$DEST_POOL]"
    return 0
  fi
  log "POOL_IMPORT_ATTEMPT [POOL=$DEST_POOL] [WAIT=$ISCSI_DEVICE_WAIT]"
  local i
  for (( i=1; i<=ISCSI_DEVICE_WAIT; i++ )); do
    if zpool import | grep -Eq "^\s+pool: ${DEST_POOL}\b"; then
      if zpool import -N -f "$DEST_POOL" >>"$LOG" 2>&1; then
        POOL_IMPORTED_FLAG=1
        log "POOL_IMPORT_SUCCESS [POOL=$DEST_POOL] [SECONDS=$i]"
        return 0
      else
        log "POOL_IMPORT_CMD_FAIL [POOL=$DEST_POOL]"; return 1
      fi
    fi
    sleep 1
  done
  log "POOL_IMPORT_TIMEOUT [POOL=$DEST_POOL] [SECONDS=$ISCSI_DEVICE_WAIT]"
  return 1
}

cleanup() {
  local status=$?
  if [[ $status -ne 0 ]]; then
    log "SCRIPT_EXIT_WITH_ERROR [CODE=$status]"
  fi
  if [[ ${POOL_IMPORTED_FLAG} == 1 && ${ISCSI_EXPORT_ON_EXIT} == 1 ]]; then
    if zpool list -H -o name "$DEST_POOL" >/dev/null 2>&1; then
      log "POOL_EXPORT [POOL=$DEST_POOL]"
      if zpool export "$DEST_POOL" >>"$LOG" 2>&1; then
        log "POOL_EXPORT_SUCCESS [POOL=$DEST_POOL]"
      else
        log "POOL_EXPORT_FAIL [POOL=$DEST_POOL]"
      fi
    fi
  fi
  if [[ ${ISCSI_LOGOUT_ON_EXIT} == 1 ]]; then
    iscsi_logout || true
  fi
}
trap cleanup EXIT

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

# iSCSI connect + pool import (fail-fast if enabled and unsuccessful)
if ! iscsi_login; then
  if [[ ${ISCSI_ENABLE} == 1 ]]; then
    log "ABORT_ISCSI_LOGIN_FAIL"; exit 1
  fi
fi
if ! ensure_pool_import; then
  if [[ ${ISCSI_ENABLE} == 1 ]]; then
    log "ABORT_POOL_IMPORT_FAIL"; exit 1
  fi
fi

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

