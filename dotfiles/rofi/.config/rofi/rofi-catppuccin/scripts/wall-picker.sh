#!/bin/bash

WALL_DIR="$HOME/Downloads/CozyPixels/Catppuccin"

if [[ ! -d "$WALL_DIR" ]]; then
    exit 1
fi

SELECTED_FILE=$(find "$WALL_DIR" -type f -regextype posix-extended -iregex '.*\.(jpg|jpeg|png|webp)' -printf '%P\0' | 
    while IFS= read -r -d '' file; do
        display_name=$(basename "$file")
        echo -en "${display_name}\0icon\x1f${WALL_DIR}/${file}\n"
    done | rofi -dmenu -i -p "Catppuccin:" -theme ~/.config/rofi/wall.rasi)

if [[ -n "$SELECTED_FILE" ]]; then
    FULL_PATH=$(find "$WALL_DIR" -type f -name "$SELECTED_FILE" -print -quit)
    
    if [[ -n "$FULL_PATH" ]]; then
        awww img "$FULL_PATH" --transition-type grow --transition-fps 60
    fi
fi
