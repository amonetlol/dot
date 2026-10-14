#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Imagens/wallpapers"

if ! command -v awww >/dev/null 2>&1; then
    echo "Erro: awww não encontrado no sistema."
    exit 1
fi

if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "Erro: pasta não encontrada: $WALLPAPER_DIR"
    exit 1
fi

WALLPAPER="$(
    find "$WALLPAPER_DIR" -type f \( \
        -iname "*.jpg" -o \
        -iname "*.jpeg" -o \
        -iname "*.png" \
    \) | shuf -n 1
)"

if [[ -z "$WALLPAPER" ]]; then
    echo "Erro: nenhuma imagem .jpg, .jpeg ou .png encontrada em $WALLPAPER_DIR"
    exit 1
fi

awww img "$WALLPAPER"

echo "Wallpaper definido:"
echo "$WALLPAPER"