#!/bin/bash

if hyprctl monitors | rg -q '^Monitor (DP-3|HDMI-A-1) '; then
  hyprctl keyword monitor "DP-3,disable"
  hyprctl keyword monitor "HDMI-A-1,disable"
else
  hyprctl keyword monitor "DP-3,3440x1440@59.97,3515x0,1.0,transform,2"
  hyprctl keyword monitor "HDMI-A-1,1920x1080@60.0,721x1800,1.0"
  hyprctl keyword monitor "DP-2,5120x1440@240.0,2641x1440,1.0,bitdepth,10"
fi
