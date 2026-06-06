#!/usr/bin/env bash
# MOD Arch
# Pacotes base + yay + VMware + SDDM Catppuccin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_arch
require_not_root
ensure_sudo
check_internet

section "01 - MOD ARCH"

official_packages=(
  base-devel
  git
  wget
  curl
  unzip
  zip
  p7zip
  tar
  rsync
  nano
  vim
  neovim
  bash-completion

  starship
  zoxide
  eza
  fd
  ripgrep
  fzf
  duf
  fastfetch  
  btop
  htop
  tree
  tldr
  lazygit

  gcc
  make
  cmake
  pkgconf
  jq
  bc
  findutils
  coreutils

  nodejs
  npm
  lua51
  luarocks
  python
  python-pip
  python-pynvim
  python-pipenv
  tree-sitter-cli

  foot
  kitty
  alacritty

  fontconfig
  noto-fonts
  noto-fonts-emoji

  xdg-utils
  xdg-user-dirs
  xdg-user-dirs-gtk

  networkmanager
  network-manager-applet

  open-vm-tools
  fuse2
  gtkmm3  
  mesa
)

aur_packages=(
  visual-studio-code-bin
)

section "Instalando pacotes oficiais"
install_pacman_packages "${official_packages[@]}"

section "Instalando pacotes AUR"
install_aur_packages "${aur_packages[@]}"

section "Ativando serviços úteis"

if systemctl list-unit-files NetworkManager.service >/dev/null 2>&1; then
  sudo systemctl enable --now NetworkManager.service
  ok "NetworkManager ativado."
else
  warn "NetworkManager.service não encontrado."
fi

if systemctl list-unit-files vmtoolsd.service >/dev/null 2>&1; then
  sudo systemctl enable --now vmtoolsd.service
  ok "vmtoolsd ativado."
else
  warn "vmtoolsd.service não encontrado."
fi

if systemctl list-unit-files vmware-vmblock-fuse.service >/dev/null 2>&1; then
  sudo systemctl enable --now vmware-vmblock-fuse.service || warn "Não consegui ativar vmware-vmblock-fuse.service."
else
  warn "vmware-vmblock-fuse.service não encontrado. Ignorando."
fi

# =========================
# SDDM Catppuccin
# =========================

install_sddm_catppuccin() {
  section "SDDM Theme Catppuccin"

  install_packages_smart sddm unzip curl

  local lightdm_active=0
  local sddm_active=0

  if systemctl is-active --quiet lightdm.service || systemctl is-enabled --quiet lightdm.service 2>/dev/null; then
    lightdm_active=1
  fi

  if systemctl is-active --quiet sddm.service || systemctl is-enabled --quiet sddm.service 2>/dev/null; then
    sddm_active=1
  fi

  if [[ "$lightdm_active" -eq 1 ]]; then
    warn "LightDM está ativo ou habilitado."
    log "Desativando LightDM e trocando para SDDM, conforme solicitado."
    sudo systemctl disable --now lightdm.service || warn "Não consegui parar/desabilitar lightdm.service. Continuando..."
  fi

  if [[ "$sddm_active" -eq 0 || "$lightdm_active" -eq 1 ]]; then
    log "Ativando SDDM..."
    sudo systemctl enable sddm.service
    ok "SDDM habilitado para o próximo boot."
  else
    ok "SDDM já está ativo ou habilitado."
  fi

  local tmpdir
  tmpdir="$(mktemp -d)"

  log "Baixando tema Catppuccin SDDM..."
  curl -L \
    -o "$tmpdir/catppuccin-sddm.zip" \
    "https://github.com/catppuccin/sddm/archive/refs/heads/main.zip"

  unzip -q "$tmpdir/catppuccin-sddm.zip" -d "$tmpdir"

  local extracted
  extracted="$(find "$tmpdir" -maxdepth 1 -type d -name 'sddm-*' | head -n 1)"

  if [[ -z "$extracted" ]]; then
    rm -rf "$tmpdir"
    fail "Não consegui localizar a pasta extraída do tema Catppuccin."
  fi

  local theme_source=""
  local preferred_theme="${SDDM_THEME:-catppuccin-macchiato}"

  if [[ -d "$extracted/src/$preferred_theme" ]]; then
    theme_source="$extracted/src/$preferred_theme"
  else
    theme_source="$(find "$extracted/src" -maxdepth 1 -type d -name 'catppuccin-*' | head -n 1 || true)"
  fi

  if [[ -z "$theme_source" || ! -d "$theme_source" ]]; then
    rm -rf "$tmpdir"
    fail "Não encontrei uma pasta de tema Catppuccin válida dentro de $extracted/src."
  fi

  local theme_name
  theme_name="$(basename "$theme_source")"

  log "Instalando tema: $theme_name"
  sudo mkdir -p /usr/share/sddm/themes
  sudo rm -rf "/usr/share/sddm/themes/$theme_name"
  sudo cp -r "$theme_source" "/usr/share/sddm/themes/$theme_name"

  sudo mkdir -p /etc/sddm.conf.d

  if [[ -f /etc/sddm.conf ]]; then
    sudo cp /etc/sddm.conf "/etc/sddm.conf.bak-$(date +%Y%m%d-%H%M%S)"
    ok "Backup criado de /etc/sddm.conf"
  fi

  if [[ -f /etc/sddm.conf.d/theme.conf ]]; then
    sudo cp /etc/sddm.conf.d/theme.conf "/etc/sddm.conf.d/theme.conf.bak-$(date +%Y%m%d-%H%M%S)"
  fi

  cat <<EOF | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
[Theme]
Current=$theme_name
EOF

  rm -rf "$tmpdir"

  ok "Tema SDDM configurado: $theme_name"
  warn "Reinicie o sistema para validar a tela de login com SDDM."
}

install_sddm_catppuccin

section "MOD ARCH FINALIZADO"
ok "Base Arch, VMware, AUR helper e SDDM configurados."