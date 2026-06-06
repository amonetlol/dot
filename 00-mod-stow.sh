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
)

section "Aplicando Stow"

for pkg in "${packages[@]}"; do
  if [[ -d "$TARGET_DOTFILES/$pkg" ]]; then
    log "Aplicando stow: $pkg"
    stow -v -t "$HOME" "$pkg"
  else
    warn "Pacote stow não encontrado, ignorando: $pkg"
  fi
done

if [[ -d "$HOME/.bin" ]]; then
  log "Aplicando chmod +x em ~/.bin/*"
  find "$HOME/.bin" -type f -exec chmod +x {} \;
  ok "Permissões aplicadas em ~/.bin."
else
  warn "~/.bin não encontrado após stow."
fi

section "STOW FINALIZADO"
ok "Dotfiles aplicados com sucesso."