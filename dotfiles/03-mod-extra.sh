#!/usr/bin/env bash
# MOD Extra
# Fonts + wallpapers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_arch
require_not_root
ensure_sudo
check_internet

section "03 - MOD EXTRA"

install_packages_smart git wget fontconfig

# =========================
# Fonts
# =========================

section "Fonts config"

FONTS_REPO="https://github.com/amonetlol/fonts"
FONTS_TARGET="$HOME/.local/share/fonts/amonetlol"

mkdir -p "$HOME/.local/share/fonts"

safe_clone_or_update "$FONTS_REPO" "$FONTS_TARGET"

section "Atualizando cache de fontes"
fc-cache -fv

ok "Cache de fontes atualizado."

# =========================
# Wallpapers
# =========================

section "Wallpapers"

WALLS_REPO="https://github.com/amonetlol/walls"
WALLS_BASE="$HOME/Imagens/wallpapers"
WALLS_TARGET="$WALLS_BASE/amonetlol-walls"

mkdir -p "$WALLS_BASE"

safe_clone_or_update "$WALLS_REPO" "$WALLS_TARGET"

ok "Wallpapers clonados em $WALLS_TARGET"

section "MOD EXTRA FINALIZADO"
ok "Fontes e wallpapers configurados."