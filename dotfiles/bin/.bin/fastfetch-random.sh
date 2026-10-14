#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="$(realpath "$HOME/.config/fastfetch")"

mapfile -t configs < <(
  find "$CONFIG_DIR" -maxdepth 1 -type f \( -name "*.jsonc" -o -name "*.json" \) | sort
)

if [[ ${#configs[@]} -eq 0 ]]; then
  echo "Nenhuma config encontrada em: $CONFIG_DIR"
  exit 1
fi

selected_config="${configs[RANDOM % ${#configs[@]}]}"

exec fastfetch --config "$selected_config"