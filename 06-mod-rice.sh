#!/usr/bin/env bash
# MOD Rice
# Instala tema GTK, cursor e ícones a partir da pasta Assets

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

require_arch
require_not_root
ensure_sudo

section "06 - MOD RICE"

ASSETS_DIR="$PWD/Assets"

THEMES_DIR="$HOME/.themes"
ICONS_DIR="$HOME/.icons"

MANHATTAN_ZIP="$ASSETS_DIR/Manhattan.zip"
QOGIR_CURSOR_ZIP="$ASSETS_DIR/Qogir-Dark.zip"
MACTAHOE_ICONS_ZIP="$ASSETS_DIR/MacTahoe-dark.zip"

section "Verificando dependências"

install_packages_smart unzip

section "Verificando pasta Assets"

if [[ ! -d "$ASSETS_DIR" ]]; then
  fail "Pasta Assets não encontrada em: $ASSETS_DIR"
fi

section "Criando diretórios"

mkdir -p "$THEMES_DIR"
mkdir -p "$ICONS_DIR"

ok "Diretório criado/verificado: ~/.themes"
ok "Diretório criado/verificado: ~/.icons"

extract_zip() {
  local zip_file="$1"
  local destination="$2"
  local label="$3"

  if [[ ! -f "$zip_file" ]]; then
    warn "Arquivo não encontrado: $zip_file"
    warn "Pulando: $label"
    return 0
  fi

  log "Instalando $label..."
  log "Arquivo: $zip_file"
  log "Destino: $destination"

  unzip -o "$zip_file" -d "$destination"

  ok "$label instalado em $destination"
}

section "Instalando tema GTK"

extract_zip "$MANHATTAN_ZIP" "$THEMES_DIR" "Tema Manhattan"

section "Instalando cursor"

extract_zip "$QOGIR_CURSOR_ZIP" "$ICONS_DIR" "Cursor Qogir-Dark"

section "Instalando ícones"

extract_zip "$MACTAHOE_ICONS_ZIP" "$ICONS_DIR" "Ícones MacTahoe-dark"

section "Atualizando cache de ícones"

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  find "$ICONS_DIR" -mindepth 1 -maxdepth 1 -type d | while read -r icon_theme; do
    if [[ -f "$icon_theme/index.theme" ]]; then
      log "Atualizando cache: $icon_theme"
      gtk-update-icon-cache -f -t "$icon_theme" >/dev/null 2>&1 || warn "Não foi possível atualizar cache de: $icon_theme"
    fi
  done
else
  warn "gtk-update-icon-cache não encontrado. Pulando cache de ícones."
fi

section "MOD RICE FINALIZADO"

cat <<EOF
Rice instalado.

Verifique no nwg-look:

  Tema GTK:
    Manhattan

  Cursor:
    Qogir-Dark

  Ícones:
    MacTahoe-dark

Caso o nome apareça diferente no nwg-look, é porque o nome real vem do arquivo index.theme dentro de cada tema.
EOF

ok "Tema, cursor e ícones processados."