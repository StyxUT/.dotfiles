#!/bin/bash

sudo syncoid --compress=none zroot/ROOT/arch_hyprland zfs-pool-WD1TB-1/zfs-backups/arch_hyprland

sudo syncoid --compress=none zroot/usr zfs-pool-WD1TB-1/zfs-backups/usr

sudo syncoid --compress=none zroot/usr/local zfs-pool-WD1TB-1/zfs-backups/usr/local

sudo syncoid --compress=none zroot/data zfs-pool-WD1TB-1/zfs-backups/data

sudo syncoid --compress=none zroot/data/home zfs-pool-WD1TB-1/zfs-backups/data/home
