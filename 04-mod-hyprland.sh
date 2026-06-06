#!/usr/bin/env bash
# MOD Hyprland
# Instala pacotes Hyprland, Wayland, Thunar, Waybar, Rofi, Awww e utilitários

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_arch
require_not_root
ensure_sudo
check_internet

section "04 - MOD HYPRLAND"

hyprland_packages=(
  awww

  ttf-geist
  ttf-geist-mono
  otf-geist-mono-nerd

  nwg-look
  cliphist
  wl-clipboard

  hyprland
  hyperv
  hyphen
  hyprcursor
  hyprgraphics
  hypridle
  hyprland-guiutils
  hyprlang
  hyprlock
  hyprpaper
  hyprpicker
  hyprsunset
  hyprtoolkit
  hyprutils
  hyprwayland-scanner
  hyprwire
  xdg-desktop-portal
  xdg-desktop-portal-hyprland

  thunar
  thunar-archive-plugin
  thunar-media-tags-plugin
  thunar-volman
  xarchiver

  waybar
  ruby
  rofi
  dmenu
  wlogout
  firefox
  mako
  viewnior
  grim
  slurp

  xfce-polkit
  network-manager-applet

  xdg-user-dirs
  xdg-user-dirs-gtk

  pipewire
  pipewire-pulse
  pipewire-alsa
  wireplumber
  pavucontrol

  brightnessctl
  playerctl

  qt5-wayland
  qt6-wayland
)

section "Instalando pacotes Hyprland"
install_packages_smart "${hyprland_packages[@]}"

section "Ativando xdg-user-dirs com locale pt_BR.UTF-8"

if command -v xdg-user-dirs-update >/dev/null 2>&1; then
  LANG=pt_BR.UTF-8 xdg-user-dirs-update
  ok "xdg-user-dirs atualizado."
else
  warn "xdg-user-dirs-update não encontrado."
fi

section "Criando diretórios úteis"

mkdir -p \
  "$HOME/.config/hypr" \
  "$HOME/.config/waybar" \
  "$HOME/.config/rofi" \
  "$HOME/.config/mako" \
  "$HOME/.cache/awww" \
  "$HOME/Imagens/wallpapers"

ok "Diretórios criados."

section "Serviços de áudio"

systemctl --user enable --now pipewire.service 2>/dev/null || warn "Não consegui ativar pipewire.service do usuário."
systemctl --user enable --now pipewire-pulse.service 2>/dev/null || warn "Não consegui ativar pipewire-pulse.service do usuário."
systemctl --user enable --now wireplumber.service 2>/dev/null || warn "Não consegui ativar wireplumber.service do usuário."

section "MOD HYPRLAND FINALIZADO"
ok "Hyprland e utilitários instalados."
warn "Alguns pacotes muito específicos podem depender do repositório/AUR disponível na sua distro."