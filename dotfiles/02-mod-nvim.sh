#!/usr/bin/env bash
# MOD Nvim
# Clona configuração do Neovim para usuário e root

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_arch
require_not_root
ensure_sudo
check_internet

section "02 - MOD NVIM"

install_packages_smart git neovim

NVIM_REPO="https://github.com/amonetlol/nvim"

USER_NVIM="$HOME/.config/nvim"
ROOT_NVIM="/root/.config/nvim"

mkdir -p "$HOME/.config"

section "Instalando configuração do Neovim para usuário"

if [[ -e "$USER_NVIM" ]]; then
  backup_path "$USER_NVIM"
fi

git clone "$NVIM_REPO" "$USER_NVIM"
ok "Configuração clonada em $USER_NVIM"

section "Instalando configuração do Neovim para root"

if sudo test -e "$ROOT_NVIM"; then
  sudo mv "$ROOT_NVIM" "${ROOT_NVIM}.bak-$(date +%Y%m%d-%H%M%S)"
  ok "Backup criado da configuração root do Neovim."
fi

sudo mkdir -p /root/.config
sudo git clone "$NVIM_REPO" "$ROOT_NVIM"
ok "Configuração clonada em $ROOT_NVIM"

section "AVISO IMPORTANTE"

cat <<'EOF'
Configuração do Neovim instalada.

Agora abra o Neovim manualmente:

  nvim

Depois execute dentro do Neovim:

  :MasonInstallAll

Não executei esse comando automaticamente porque o Mason depende do carregamento completo dos plugins dentro do Neovim.
EOF

section "MOD NVIM FINALIZADO"
ok "Neovim configurado para usuário e root."