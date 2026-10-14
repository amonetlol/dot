#!/usr/bin/env bash
# Wallpaper aleatório a cada 5 minutos.
# Detecta Gnome, KDE ou Hyprland. No Hyprland usa o awww.
# Pasta: ~/Imagens/wallpapers

WALLPAPER_DIR="${HOME}/Imagens/wallpapers"
INTERVAL=300

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=${XDG_RUNTIME_DIR}/bus}"

import_env_from() {
  local pid="$1"
  local item
  [ -n "$pid" ] || return 0
  [ -r "/proc/${pid}/environ" ] || return 0
  while IFS= read -r -d '' item; do
    case "$item" in
      DBUS_SESSION_BUS_ADDRESS=*|\
      WAYLAND_DISPLAY=*|\
      DISPLAY=*|\
      XDG_RUNTIME_DIR=*|\
      HYPRLAND_INSTANCE_SIGNATURE=*|\
      XDG_CURRENT_DESKTOP=*|\
      XDG_SESSION_DESKTOP=*|\
      XDG_SESSION_TYPE=*)
        export "$item"
        ;;
    esac
  done < "/proc/${pid}/environ"
}

first_pid() {
  pgrep -x "$1" 2>/dev/null | head -n 1 || true
}

detect_de() {
  local pid

  pid=$(first_pid Hyprland)
  if [ -n "$pid" ] || [ "${XDG_CURRENT_DESKTOP:-}" = "Hyprland" ] || [ "${XDG_SESSION_DESKTOP:-}" = "hyprland" ]; then
    [ -n "$pid" ] && import_env_from "$pid"
    printf '%s\n' hyprland
    return
  fi

  pid=$(first_pid plasmashell)
  if [ -n "$pid" ] || [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]] || [ "${XDG_SESSION_DESKTOP:-}" = "plasma" ]; then
    [ -n "$pid" ] && import_env_from "$pid"
    printf '%s\n' kde
    return
  fi

  pid=$(first_pid gnome-shell)
  if [ -n "$pid" ] || [[ "${XDG_CURRENT_DESKTOP:-}" == *GNOME* ]] || [ "${XDG_SESSION_DESKTOP:-}" = "gnome" ]; then
    [ -n "$pid" ] && import_env_from "$pid"
    printf '%s\n' gnome
    return
  fi

  printf '%s\n' unknown
}

file_uri() {
  local path="$1"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import pathlib,sys; print(pathlib.Path(sys.argv[1]).resolve().as_uri())' "$path" && return
  fi
  path=$(readlink -f "$path")
  printf 'file://%s\n' "${path// /%20}"
}

pick_wallpaper() {
  [ -d "$WALLPAPER_DIR" ] || return 1
  find "$WALLPAPER_DIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.avif' \) \
    -print0 | shuf -z -n 1 | tr -d '\0'
}

ensure_awww() {
  local i
  if awww query >/dev/null 2>&1; then
    return 0
  fi
  if command -v awww-daemon >/dev/null 2>&1; then
    awww-daemon >/dev/null 2>&1 &
  elif awww daemon --help >/dev/null 2>&1; then
    awww daemon >/dev/null 2>&1 &
  else
    echo "awww não encontrado" >&2
    return 1
  fi
  for i in 1 2 3 4 5 6 7 8 9 10; do
    if awww query >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.3
  done
  return 1
}

set_gnome() {
  local uri
  uri=$(file_uri "$1")
  gsettings set org.gnome.desktop.background picture-uri "$uri"
  gsettings set org.gnome.desktop.background picture-uri-dark "$uri" || true
}

set_kde() {
  local uri
  if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
    plasma-apply-wallpaperimage "$1"
    return
  fi
  uri=$(file_uri "$1")
  qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
    var d = desktops();
    for (var i = 0; i < d.length; i++) {
      d[i].wallpaperPlugin = 'org.kde.image';
      d[i].currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
      d[i].writeConfig('Image', '${uri}');
    }
  "
}

set_hyprland() {
  command -v awww >/dev/null 2>&1 || {
    echo "awww não encontrado" >&2
    return 1
  }
  ensure_awww || return 1
  awww img "$1"
}

apply_wallpaper() {
  local de="$1"
  local file="$2"
  case "$de" in
    gnome) set_gnome "$file" ;;
    kde) set_kde "$file" ;;
    hyprland) set_hyprland "$file" ;;
    *) return 1 ;;
  esac
}

while true; do
  de=$(detect_de)
  if [ "$de" = "unknown" ]; then
    sleep 5
    continue
  fi

  file=$(pick_wallpaper || true)
  if [ -z "${file:-}" ]; then
    echo "Nenhum wallpaper em ${WALLPAPER_DIR}" >&2
    sleep 15
    continue
  fi

  if apply_wallpaper "$de" "$file"; then
    sleep "$INTERVAL"
  else
    sleep 15
  fi
done
