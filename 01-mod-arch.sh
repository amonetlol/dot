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
  bat
  #sysd-manager

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
  python-virtualenv
  tmux
  prettier

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
  openssh
  inetutils

  open-vm-tools
  fuse2
  gtkmm3  
  mesa
)

aur_packages=(
  
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

if systemctl list-unit-files sshd.service >/dev/null 2>&1; then
  sudo systemctl enable --now sshd.service
  ok "sshd ativado."
else
  warn "sshd.service não encontrado."
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

  install_packages_smart sddm unzip curl qt5-quickcontrols2 qt5-graphicaleffects qt5-svg

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

  section "Instalando tema Catppuccin via AUR"

  if ! pacman -Q catppuccin-sddm-theme-mocha >/dev/null 2>&1; then
    ensure_yay
    yay -S --needed --noconfirm catppuccin-sddm-theme-mocha
  else
    ok "catppuccin-sddm-theme-mocha já instalado."
  fi

  local theme_name="catppuccin-mocha"

  if [[ ! -d "/usr/share/sddm/themes/$theme_name" ]]; then
    warn "Não encontrei /usr/share/sddm/themes/$theme_name."
    log "Temas disponíveis:"
    find /usr/share/sddm/themes -maxdepth 1 -mindepth 1 -type d -printf '  - %f\n' 2>/dev/null || true

    local detected_theme
    detected_theme="$(find /usr/share/sddm/themes -maxdepth 1 -mindepth 1 -type d -name 'catppuccin*' -printf '%f\n' 2>/dev/null | head -n 1 || true)"

    if [[ -n "$detected_theme" ]]; then
      theme_name="$detected_theme"
      ok "Tema Catppuccin detectado: $theme_name"
    else
      fail "Tema Catppuccin não encontrado após instalação."
    fi
  fi

  sudo mkdir -p /etc/sddm.conf.d

  if [[ -f /etc/sddm.conf ]]; then
    sudo cp /etc/sddm.conf "/etc/sddm.conf.bak-$(date +%Y%m%d-%H%M%S)"
    ok "Backup criado de /etc/sddm.conf"
  fi

  if [[ -f /etc/sddm.conf.d/theme.conf ]]; then
    sudo cp /etc/sddm.conf.d/theme.conf "/etc/sddm.conf.d/theme.conf.bak-$(date +%Y%m%d-%H%M%S)"
    ok "Backup criado de /etc/sddm.conf.d/theme.conf"
  fi

  cat <<EOF | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
[Theme]
Current=$theme_name
EOF

  ok "Tema SDDM configurado: $theme_name"
  warn "Reinicie o sistema para validar a tela de login com SDDM."
}

install_sddm_catppuccin

section "MOD ARCH FINALIZADO"
ok "Base Arch, VMware, AUR helper e SDDM configurados."