#!/bin/bash

case "$1" in
  calculator)
    if pgrep -f 'wofi .* -p calc' >/dev/null; then
      pkill -f 'wofi .* -p calc'
    else
      wofi-calc >/dev/null 2>&1 &
    fi
    ;;
  network)
    if pgrep -f 'kitty .*--class=waybar-nmtui' >/dev/null; then
      pkill -f 'kitty .*--class=waybar-nmtui'
    else
      kitty --class=waybar-nmtui -T waybar-nmtui sh -lc 'nmtui' >/dev/null 2>&1 &
    fi
    ;;
  audio)
    if pgrep -x hyprpwcenter >/dev/null; then
      pkill -x hyprpwcenter
    else
      hyprpwcenter >/dev/null 2>&1 &
    fi
    ;;
  *)
    exit 1
    ;;
esac
