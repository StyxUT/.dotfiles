#!/bin/bash
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

# Also prune snapshots in the backup location
log "Pruning backup snapshots in zfs-pool-WD1TB-1/zfs-backups"
/home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_frequently' 2d zfs-pool-WD1TB-1/zfs-backups
/home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_hourly' 1w zfs-pool-WD1TB-1/zfs-backups
/home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_daily' 5w zfs-pool-WD1TB-1/zfs-backups
/home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_monthly' 2y zfs-pool-WD1TB-1/zfs-backups

log "Finished ZFS snapshot pruning"
