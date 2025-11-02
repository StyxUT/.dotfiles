#!/usr/bin/env bash

#sudo syncoid --no-sync-snap --compress=none zroot/ROOT/arch_hyprland zfs-pool-WD1TB-1/zfs-backups/arch_hyprland
#sudo syncoid --no-sync-snap --compress=none zroot/usr zfs-pool-WD1TB-1/zfs-backups/usr
#sudo syncoid --no-sync-snap --compress=none zroot/usr/local zfs-pool-WD1TB-1/zfs-backups/usr/local
#sudo syncoid --no-sync-snap --compress=none zroot/data zfs-pool-WD1TB-1/zfs-backups/data
#sudo syncoid --no-sync-snap --compress=none zroot/data/home zfs-pool-WD1TB-1/zfs-backups/data/home
#sudo install -m 0755 /dev/stdin /home/styxut/.config/sanoid/syncoid.sh <<'EOF'

set -euo pipefail
exec 9>/run/syncoid-post.lock
flock -n 9 || exit 0
LOG="/var/log/syncoid-post.log"
syncoid --no-sync-snap --compress=none --recursive zroot/data zfs-pool-WD1TB-1/zfs-backups/data >>"$LOG" 2>&1
syncoid --no-sync-snap --compress=none --recursive zroot/usr  zfs-pool-WD1TB-1/zfs-backups/usr  >>"$LOG" 2>&1
syncoid --no-sync-snap --compress=none zroot/ROOT/arch_hyprland zfs-pool-WD1TB-1/zfs-backups/arch_hyprland >>"$LOG" 2>&1
echo "[$(date -Is)] syncoid post-snapshot: completed" >>"$LOG"
EOF
