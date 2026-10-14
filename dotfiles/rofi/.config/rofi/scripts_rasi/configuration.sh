#!/usr/bin/env bash

if [[ $# -gt 2 || $1 != "standalone" && $1 != "menu" ]]; then
  echo "Usage $0 [menu|standalone] [previous_menu]"
  exit 1
fi

THEME_PATH="$HOME/.config/rofi/catppuccin-script.rasi"
SCRIPT_DIR="$HOME/Scripts/Rofi"

MODE="${1:-menu}"
BACK="${2:-menu}"

options=$(printf " dotfiles\n Hyprland\n Wallpapers\n Neovim\n Starship\n Foot\n Waybar\n Fastfetch" | rofi -i -dmenu -p " Configuration" -theme "$THEME_PATH")

if [[ -z "$options" ]]; then
  if [[ "$MODE" == "menu" ]]; then
    exec "$SCRIPT_DIR/menu.sh" "$BACK"
  else
    exit 0
  fi
fi

case "$options" in
*dotfiles*)
  foot nvim "$HOME/.dotfiles"
  ;;
*Hyprland*)
  foot nvim "$HOME/.config/hypr"
  ;;
*Wallpapers*)
  "$SCRIPT_DIR/hyprland-config.sh" menu config
  ;;
*Neovim*)
  foot nvim +'lua Snacks.dashboard.pick("files", { cwd = vim.fn.stdpath("config") })'
  ;;
*Starship*)
  foot nvim "$HOME/.config/starship.toml"
  ;;
*Foot*)
  foot nvim "$HOME/.config/foot/foot.ini"
  ;;
*Waybar*)
  foot nvim "$HOME/.config/waybar"
  ;;
*Fastfetch*)
  foot nvim "$HOME/.config/fastfetch/config.jsonc"
  ;;
*Scripts*)
  foot nvim "$HOME/Scripts"
  ;;
*)
  notify-send -u normal "This option doesn't exist."
  ;;
esac
