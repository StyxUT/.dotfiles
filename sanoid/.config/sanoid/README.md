# ZFS Snapshot Management with Sanoid

This directory is an override Sanoid config dir (passed with `--configdir=/home/styxut/.config/sanoid` in the systemd unit) rather than `/etc/sanoid`. Templates and scripts live alongside `sanoid.conf` for portability.



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

Retention is defined by templates in `sanoid.conf`:

- `template_production`: frequent snapshots (`frequently=5` every `frequent_period=20` minutes), plus hourly(5), daily(8), and monthly(1). Yearly disabled.
- `template_backup`: receives replicated snapshots only (`autosnap = no`), retains hourly(10), daily(8), monthly(6).
- `template_scripts`: adds hook scripts; does not alter counts.

Pruning also calls the standalone pruning script for age-based cleanup beyond counts (see Pruning Wrapper section).

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

## Datasets and Replication

Managed source datasets (recursive) in `sanoid.conf`:

- `<source-pool>/<root-dataset>` (e.g. operating system root)
- `<source-pool>/<primary-data>` (e.g. user data hierarchy)
- Additional source datasets as required

Remote backup root dataset:
- `<remote-pool>/<backup-root>` (replicated copy; no local autosnap)

Replication workflow:
1. Sanoid takes snapshots on source datasets via `template_production`.
2. After each snapshot, `post_snapshot_script` (`syncoid.sh`) runs.
3. `syncoid.sh` loads list of datasets from `datasets.txt` (one per line, comments allowed) and replicates each to the remote pool, transforming `<source-pool>/...` to `<remote-pool>/...`.
4. Compression (`COMPRESSION`), bandwidth cap (`BW_LIMIT`), and base flags (`--no-sync-snap`) are configured near the top of `syncoid.sh`. Setting `COMPRESSION=max` auto-selects highest supported in order: xz > zstd-slow > pigz-slow > gzip > zstd-fast > pigz-fast > lz4 > lzo, logging `COMPRESSION_AUTOSELECT`. Use `COMPRESSION=none` to disable syncoid stream compression entirely. Unsupported explicit values fall back to lzo.
5. Transfers run with configurable concurrency (export `CONCURRENT=<n>`, default 2) using background jobs; adjust to avoid saturating network or I/O.
6. Failures and progress are logged in `/var/log/syncoid-post.log` with tagged lines: `START [DATASET=...] [DEST=...]`, `SUCCESS ... [DURATION=Ns]`, `FAIL ... [DURATION=Ns]`, and a final `SUMMARY [STATUS=success|failures] [TOTAL=N]` for easy parsing.

Adjusting bandwidth: set `BW_LIMIT=""` to remove cap or change value (e.g. `40M`).
Adding concurrency example (edit script):
```
CONCURRENT=3
sem_count=0
for ds in "${DATASETS[@]}"; do
  # derive dest ...
  syncoid "${SYNCOID_BASE_OPTS[@]}" "$ds" "$dest" &
  ((sem_count++))
  if (( sem_count >= CONCURRENT )); then
    wait
    sem_count=0
  fi
done
wait
```

Add or remove datasets by editing `datasets.txt` and ensuring corresponding entries exist in `sanoid.conf`.

## Scripts

### Pruning Wrapper

`pruning-wrapper.sh` runs the age-based prune script for each snapshot class. Optional remote pruning lines are commented and can be enabled by setting a remote dataset variable in the script.

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

Pruning operations are logged to `/var/log/sanoid-pruning.log` (ISO timestamps).

## Troubleshooting

### Replication Issues

- Check `/var/log/syncoid-post.log` for per-dataset success/fail entries.
- Ensure `datasets.txt` exists and is readable; script aborts otherwise.
- Verify `syncoid` installed (`command -v syncoid`).
- Manually dry-run a single dataset: `syncoid --no-sync-snap --dry-run <source-pool>/<dataset> <remote-pool>/<dataset>`.
- Confirm destination pool and dataset names (`zfs list <remote-pool>/<backup-root>`).


If snapshots are not being pruned:

1. Ensure the service is running with the `--prune-snapshots` flag
2. Check the logs in `/var/log/sanoid-pruning.log`
3. Run the pruning script manually to debug: 
   ```
   /home/styxut/.config/sanoid/zfs-prune-snaphsots.sh -v -s '_hourly' 1w
   ```
4. Verify the templates are correctly applied to datasets
