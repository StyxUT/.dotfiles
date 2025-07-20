# ZFS Snapshot Management with Sanoid

This directory contains configuration files and scripts for managing ZFS snapshots using Sanoid.

## Overview

The setup uses Sanoid for automatic snapshot creation and pruning, with custom scripts to handle retention policies for different snapshot types.

## Files

- `sanoid.conf`: Main configuration file for Sanoid
- `sanoid.defaults.conf`: Default configuration values (don't edit directly)
- `syncoid.sh`: Script for replicating snapshots to backup location
- `zfs-prune-snaphsots.sh`: Custom script for pruning snapshots based on age and name patterns
- `pruning-wrapper.sh`: Wrapper script that calls the pruning script with different parameters

## Configuration

### Sanoid Service

The Sanoid service has been configured with a custom override to run both snapshot creation and pruning:

```
[Service]
ExecStart=/usr/bin/sanoid --take-snapshots --prune-snapshots --verbose --configdir=/home/styxut/.config/sanoid
```

### Retention Policies

The system is configured with the following snapshot retention policies:

1. **Frequently** snapshots: Kept for 2 days
2. **Hourly** snapshots: Kept for 1 week
3. **Daily** snapshots: Kept for 5 weeks
4. **Monthly** snapshots: Kept for 2 years

### Dataset Templates

The configuration uses several templates:

- `template_production`: For production datasets with frequent snapshots
- `template_backup`: For backup datasets (no automatic snapshots, just retention)
- `template_scripts`: Defines pre/post snapshot and pruning scripts

## Scripts

### Pruning Wrapper

The `pruning-wrapper.sh` script handles running the pruning script with different parameters for different snapshot types:

```bash
/home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_frequently' 2d
/home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_hourly' 1w
/home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_daily' 5w
/home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_monthly' 2y
```

### ZFS Prune Snapshots

The `zfs-prune-snaphsots.sh` script provides flexible options for pruning snapshots based on:

- Age (`1d`, `1w`, `1M`, `1y`, etc.)
- Name prefix (`-p` option)
- Name suffix (`-s` option)

## Automation

The setup runs via a systemd timer (`sanoid.timer`) which triggers every 15 minutes.

## Log Files

Pruning operations are logged to `/var/log/sanoid-pruning.log`.

## Troubleshooting

If snapshots are not being pruned:

1. Ensure the service is running with the `--prune-snapshots` flag
2. Check the logs in `/var/log/sanoid-pruning.log`
3. Run the pruning script manually to debug: 
   ```
   /home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_hourly' 1w
   ```
4. Verify the templates are correctly applied to datasets
