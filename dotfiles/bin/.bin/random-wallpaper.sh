#!/usr/bin/env bash
set -euo pipefail
wallpaper_dir="$HOME/Imagens/wallpapers"
[[ -d "$wallpaper_dir" ]] || exit 0
wallpaper=$(find "$wallpaper_dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | shuf -n 1)
[[ -n "$wallpaper" ]] || exit 0
de="${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-}}"
set_wayland_wallpaper() {
  if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then exit 0; fi
  if ! command -v awww >/dev/null 2>&1; then
    echo "random-wallpaper: awww não encontrado" >&2
    return 1
  fi
  awww img "$wallpaper"
}
case "${de,,}" in
  *gnome*)
    uri=$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve().as_uri())' "$wallpaper")
    gsettings set org.gnome.desktop.background picture-uri "$uri"
    gsettings set org.gnome.desktop.background picture-uri-dark "$uri" 2>/dev/null || true
    ;;
  *kde*|*plasma*)
    if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then plasma-apply-wallpaperimage "$wallpaper"; else exit 0; fi
    ;;
  *qtile*|*x11*)
    if [[ -n "${DISPLAY:-}" ]] && command -v feh >/dev/null 2>&1; then feh --no-fehbg --bg-fill "$wallpaper"; else exit 0; fi
    ;;
  *niri*|*hyprland*|*wayland*|*sway*)
    set_wayland_wallpaper
    ;;
  *)
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
      set_wayland_wallpaper
    elif [[ -n "${DISPLAY:-}" ]] && command -v feh >/dev/null 2>&1; then
      feh --no-fehbg --bg-fill "$wallpaper"
    else exit 0; fi
    ;;
esac
