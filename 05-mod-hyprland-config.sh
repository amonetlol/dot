#!/usr/bin/env bash
# MOD Hyprland Config
# Cria configuração base otimizada para VMware

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_arch
require_not_root

section "05 - MOD HYPRLAND CONFIG"

HYPR_DIR="$HOME/.config/hypr"
HYPR_CONF="$HYPR_DIR/hyprland.conf"

mkdir -p "$HYPR_DIR"
mkdir -p "$HOME/.cache/awww"

if [[ -f "$HYPR_CONF" ]]; then
  backup_path "$HYPR_CONF"
fi

cat > "$HYPR_CONF" <<'EOF'
# ============================================================
# Hyprland base config
# Otimizada para Arch/derivados em VMware
# ============================================================

# ------------------------------------------------------------
# Monitor
# ------------------------------------------------------------
monitor=,preferred,auto,1

# ------------------------------------------------------------
# Environment
# ------------------------------------------------------------
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Qogir-cursors
env = HYPRCURSOR_SIZE,24
env = WLR_NO_HARDWARE_CURSORS,1
env = WLR_RENDERER_ALLOW_SOFTWARE,1
env = QT_QPA_PLATFORM,wayland;xcb
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = GDK_BACKEND,wayland,x11
env = MOZ_ENABLE_WAYLAND,1

# VMware
env = GSK_RENDERER=cairo
env = WEBKIT_DISABLE_DMABUFF=1


# ------------------------------------------------------------
# Startup
# ------------------------------------------------------------
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/xfce-polkit/xfce-polkit
exec-once = waybar
exec-once = awww-daemon
exec-once = nm-applet --indicator

# ------------------------------------------------------------
# Input
# ------------------------------------------------------------
input {
    kb_layout = br
    kb_variant = abnt2
    follow_mouse = 1
    sensitivity = 0

    touchpad {
        natural_scroll = false
    }
}

# ------------------------------------------------------------
# General
# ------------------------------------------------------------
general {
    gaps_in = 4
    gaps_out = 8
    border_size = 2

    layout = dwindle

    allow_tearing = false
}

# ------------------------------------------------------------
# Decoration
# ------------------------------------------------------------
decoration {
    rounding = 6

    blur {
        enabled = false
    }

    shadow {
        enabled = false
    }
}

# ------------------------------------------------------------
# Animations
# ------------------------------------------------------------
animations {
    enabled = false
}

# ------------------------------------------------------------
# Layout
# ------------------------------------------------------------
dwindle {
    preserve_split = true
}

master {
    new_status = master
}

# ------------------------------------------------------------
# Misc
# ------------------------------------------------------------
misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    force_default_wallpaper = 0
}

# ------------------------------------------------------------
# Apps
# ------------------------------------------------------------
$terminal = foot
$fileManager = thunar
$browser = firefox
$menu = ~/.config/rofi/launcher.sh
$logout = ~/.config/rofi/rofi-applet/powermenu.sh

# ------------------------------------------------------------
# Binds principais
# ------------------------------------------------------------

# Rofi
bind = SUPER, D, exec, $menu

# Firefox
bind = SUPER, W, exec, $browser

# Fechar janela
bind = SUPER, Q, killactive

# Terminal
bind = SUPER, RETURN, exec, $terminal

# Arquivos
bind = SUPER, E, exec, $fileManager

# Logout menu
bind = SUPER, X, exec, $logout

# Reload Hyprland
bind = SUPER SHIFT, R, exec, hyprctl reload

# Restart Waybar
bind = , F12, exec, pkill waybar; waybar &

# Wallpaper
bind = , F9, exec,  ~/.config/waybar/scripts/random-wallpaper.sh
bind = , F10, exec, ~/.config/rofi/rofi-catppuccin/wall-picker.sh

# CheatSheet
bind = SUPER, slash, exec, [float; center; size 1200 800] foot -e nvim ~/.config/hypr/hyprland.conf

# ------------------------------------------------------------
# Binds básicos extras
# ------------------------------------------------------------

# Alternar fullscreen
bind = SUPER, F, fullscreen

# Janela flutuante
bind = SUPER, V, togglefloating

# Screenshot seleção
bind = SUPER SHIFT, S, exec, grim -g "$(slurp)" "$HOME/Imagens/screenshot-$(date +%Y%m%d-%H%M%S).png"

# ------------------------------------------------------------
# Foco entre janelas
# ------------------------------------------------------------
bind = SUPER, left, movefocus, l
bind = SUPER, right, movefocus, r
bind = SUPER, up, movefocus, u
bind = SUPER, down, movefocus, d

# ------------------------------------------------------------
# Workspaces
# ------------------------------------------------------------
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5
bind = SUPER, 6, workspace, 6
bind = SUPER, 7, workspace, 7
bind = SUPER, 8, workspace, 8
bind = SUPER, 9, workspace, 9
bind = SUPER, 0, workspace, 10

# Mover janela para workspace
bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4
bind = SUPER SHIFT, 5, movetoworkspace, 5
bind = SUPER SHIFT, 6, movetoworkspace, 6
bind = SUPER SHIFT, 7, movetoworkspace, 7
bind = SUPER SHIFT, 8, movetoworkspace, 8
bind = SUPER SHIFT, 9, movetoworkspace, 9
bind = SUPER SHIFT, 0, movetoworkspace, 10

# ------------------------------------------------------------
# Mouse
# ------------------------------------------------------------
bindm = SUPER, mouse:272, movewindow
bindm = SUPER, mouse:273, resizewindow

# ------------------------------------------------------------
# Regras iniciais
# ------------------------------------------------------------
windowrule = match:class .*, suppress_event maximize
EOF

ok "Configuração criada em $HYPR_CONF"

section "MOD HYPRLAND CONFIG FINALIZADO"

cat <<EOF
Config base criada.

Arquivos/pastas preparados:

  $HYPR_CONF
  $HOME/.cache/awww

Você pode colocar suas configs organizadas depois em:

  $HOME/.config/hypr
  $HOME/.config/waybar
  $HOME/.config/rofi

EOF

ok "Hyprland config pronta."