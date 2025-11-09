#!/usr/bin/env bash
set -euo pipefail
# Wrapper script to run multiple pruning commands

# Log file
LOG_FILE="/var/log/sanoid-pruning.log"

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Log function
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

log "Starting ZFS snapshot pruning"

# Run the pruning scripts one by one
log "Pruning frequently snapshots older than 2 days"
/home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_frequently' 2d
log "Pruning hourly snapshots older than 1 week"
/home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_hourly' 1w
log "Pruning daily snapshots older than 5 weeks"
/home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_daily' 5w
log "Pruning monthly snapshots older than 2 years"
/home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_monthly' 2y

# Optional: prune replicated snapshots on remote target (disabled by default)
# Uncomment and set REMOTE_DATASET to enable age-based pruning remotely.
#REMOTE_DATASET="remote-pool/backup-root"
#if [[ -n ${REMOTE_DATASET:-} ]]; then
#  log "Pruning remote hourly snapshots older than 1 week on $REMOTE_DATASET"
#  /home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_hourly' 1w "$REMOTE_DATASET"
#  log "Pruning remote daily snapshots older than 5 weeks on $REMOTE_DATASET"
#  /home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_daily' 5w "$REMOTE_DATASET"
#  log "Pruning remote monthly snapshots older than 2 years on $REMOTE_DATASET"
#  /home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_monthly' 2y "$REMOTE_DATASET"
#fi

log "Finished ZFS snapshot pruning"
