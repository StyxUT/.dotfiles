#!/bin/bash
#  ____  _             _    __        __          _                 
# / ___|| |_ __ _ _ __| |_  \ \      / /_ _ _   _| |__   __ _ _ __  
# \___ \| __/ _` | '__| __|  \ \ /\ / / _` | | | | '_ \ / _` | '__| 
#  ___) | || (_| | |  | |_    \ V  V / (_| | |_| | |_) | (_| | |    
# |____/ \__\__,_|_|   \__|    \_/\_/ \__,_|\__, |_.__/ \__,_|_|    
#                                           |___/                   
# by Stephan Raabe (2023) 
# ----------------------------------------------------- 

# ----------------------------------------------------- 
# Quit all running waybar instances
# ----------------------------------------------------- 
killall waybar
pkill waybar
sleep 0.5

# ----------------------------------------------------- 
# Reload AGS
# -----------------------------------------------------

echo ":: Reload ags"
if command -v ags >/dev/null 2>&1; then
    ags quit &
    sleep 0.2
    ags run &
fi

# ----------------------------------------------------- 
# Default theme: /THEMEFOLDER;/VARIATION
# Prefer the local top-level config/style and only use an
# external theme selection when the ML4W settings exist.
# ----------------------------------------------------- 
themestyle="local"

# ----------------------------------------------------- 
# Get current theme information from ~/.config/ml4w/settings/waybar-theme.sh
# ----------------------------------------------------- 
if [ -f ~/.config/ml4w/settings/waybar-theme.sh ]; then
    themestyle=$(cat ~/.config/ml4w/settings/waybar-theme.sh)
elif [ -d ~/.config/ml4w/settings ]; then
    themestyle="/ml4w;/ml4w/light"
    touch ~/.config/ml4w/settings/waybar-theme.sh
    echo "$themestyle" > ~/.config/ml4w/settings/waybar-theme.sh
fi

theme_config="$HOME/.config/waybar/config"
theme_style="$HOME/.config/waybar/style.css"

if [ "$themestyle" != "local" ]; then
    IFS=';' read -ra arrThemes <<< "$themestyle"
    echo ":: Theme: ${arrThemes[0]}"
    theme_config="$HOME/.config/waybar/themes${arrThemes[0]}/config"
    theme_style="$HOME/.config/waybar/themes${arrThemes[1]}/style.css"
    if [ ! -f "$theme_style" ]; then
        themestyle="/ml4w;/ml4w/light"
        IFS=';' read -ra arrThemes <<< "$themestyle"
        theme_config="$HOME/.config/waybar/themes${arrThemes[0]}/config"
        theme_style="$HOME/.config/waybar/themes${arrThemes[1]}/style.css"
    fi

    if [ ! -f "$theme_style" ] || grep -q '\.cache/wal/colors-waybar\.css' "$theme_style" && [ ! -f "$HOME/.cache/wal/colors-waybar.css" ]; then
        echo ":: Falling back to local config/style"
        theme_config="$HOME/.config/waybar/config"
        theme_style="$HOME/.config/waybar/style.css"
    fi
else
    echo ":: Theme: local"
fi

# ----------------------------------------------------- 
# Loading the configuration
# ----------------------------------------------------- 
config_file="config"
style_file="style.css"

# Standard files can be overwritten with an existing config-custom or style-custom.css
if [ "$themestyle" != "local" ] && [ "$theme_config" = "$HOME/.config/waybar/themes${arrThemes[0]}/config" ] && [ -f ~/.config/waybar/themes${arrThemes[0]}/config-custom ] ;then
    config_file="config-custom"
fi
if [ "$themestyle" != "local" ] && [ "$theme_style" = "$HOME/.config/waybar/themes${arrThemes[1]}/style.css" ] && [ -f ~/.config/waybar/themes${arrThemes[1]}/style-custom.css ] ;then
    style_file="style-custom.css"
fi

if [ "$themestyle" != "local" ] && [ "$theme_config" = "$HOME/.config/waybar/themes${arrThemes[0]}/config" ]; then
    theme_config="$HOME/.config/waybar/themes${arrThemes[0]}/$config_file"
fi

if [ "$themestyle" != "local" ] && [ "$theme_style" = "$HOME/.config/waybar/themes${arrThemes[1]}/style.css" ]; then
    theme_style="$HOME/.config/waybar/themes${arrThemes[1]}/$style_file"
fi

# Check if waybar-disabled file exists
if [ ! -f $HOME/.cache/waybar-disabled ] ;then 
    waybar -c "$theme_config" -s "$theme_style" &
fi
