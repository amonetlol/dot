#!/usr/bin/env bash
# MOD Stow
# Move dotfiles para ~/.dotfiles e aplica GNU Stow

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_arch
require_not_root
ensure_sudo

section "00 - MOD STOW"

install_packages_smart stow

SOURCE_DOTFILES="$PWD/dotfiles"
TARGET_DOTFILES="$HOME/.dotfiles"

if [[ ! -d "$SOURCE_DOTFILES" && ! -d "$TARGET_DOTFILES" ]]; then
  fail "Não encontrei $SOURCE_DOTFILES nem $TARGET_DOTFILES."
fi

if [[ -d "$SOURCE_DOTFILES" ]]; then
  if [[ -e "$TARGET_DOTFILES" ]]; then
    backup_path "$TARGET_DOTFILES"
  fi

  log "Movendo dotfiles:"
  log "$SOURCE_DOTFILES -> $TARGET_DOTFILES"
  mv "$SOURCE_DOTFILES" "$TARGET_DOTFILES"
else
  ok "$TARGET_DOTFILES já existe. Usando esta pasta."
fi

cd "$TARGET_DOTFILES"

packages=(
  fonts
  foot
  bin
  bash
  shortcuts
  alacritty
  kitty
  neofetch
  fastfetch
  starship
  rofi
  waybar
  gtk-3.0
  btop
)

section "Resolvendo conflitos comuns antes do Stow"

backup_if_real_file() {
  local target="$1"

  if [[ -e "$target" && ! -L "$target" ]]; then
    local backup="${target}.bak-$(date +%Y%m%d-%H%M%S)"
    warn "Conflito encontrado: $target"
    log "Movendo para backup: $backup"
    mv "$target" "$backup"
  fi
}

# Conflitos comuns do módulo bash
backup_if_real_file "$HOME/.bashrc"
backup_if_real_file "$HOME/.bash_profile"
backup_if_real_file "$HOME/.profile"
backup_if_real_file "$HOME/.aliases"
backup_if_real_file "$HOME/.functions"

section "Aplicando Stow"

for pkg in "${packages[@]}"; do
  if [[ -d "$TARGET_DOTFILES/$pkg" ]]; then
    log "Aplicando stow: $pkg"
    stow -v -t "$HOME" --restow "$pkg"
  else
    warn "Pacote stow não encontrado, ignorando: $pkg"
  fi
done

if [[ -d "$HOME/.bin" ]]; then
  log "Aplicando chmod +x em ~/.bin/*"
  #find "$HOME/.bin" -type f -exec chmod +x {} \;
  chmod +x "$HOME"/.bin/*
  ok "Permissões aplicadas em ~/.bin."
else
  warn "~/.bin não encontrado após stow."
fi

section "Aplicando permissões extras"

if [[ -f "$HOME/.config/rofi/launcher.sh" ]]; then
  chmod +x "$HOME/.config/rofi/launcher.sh"
  ok "Permissão aplicada: ~/.config/rofi/launcher.sh"
else
  warn "Arquivo não encontrado: ~/.config/rofi/launcher.sh"
fi

if [[ -f "$HOME/.config/rofi/rofi-applet/powermenu.sh" ]]; then
  chmod +x "$HOME/.config/rofi/rofi-applet/powermenu.sh"
  ok "Permissão aplicada: ~/.config/rofi/rofi-applet/powermenu.sh"
else
  warn "Arquivo não encontrado: ~/.config/rofi/rofi-applet/powermenu.sh"
fi

if [[ -d "$HOME/.config/waybar/scripts" ]]; then
  find "$HOME/.config/waybar/scripts" -type f -exec chmod +x {} \;
  ok "Permissões aplicadas em ~/.config/waybar/scripts/*"
else
  warn "Diretório não encontrado: ~/.config/waybar/scripts"
fi

## Permissões extras
  chmod +x $HOME/.dotfiles/rofi/.config/rofi/rofi-catppuccin/*.sh

section "STOW FINALIZADO"
ok "Dotfiles aplicados com sucesso."