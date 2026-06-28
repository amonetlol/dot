#!/usr/bin/env bash

LOGO_DIR="$HOME/.config/fastfetch/png"

RANDOM_LOGO=$(find "$LOGO_DIR" -type f \( \
    -iname "*.jpg"  -o -iname "*.jpeg" -o \
    -iname "*.png"  -o -iname "*.webp" -o \
    -iname "*.gif"  \
\) | shuf -n 1)

if [[ -n "$RANDOM_LOGO" ]]; then
    fastfetch --logo "$RANDOM_LOGO" --logo-type kitty-icat --config ~/.config/fastfetch/config.jsonc
else
    fastfetch --config ~/.config/fastfetch/config.jsonc
fi
