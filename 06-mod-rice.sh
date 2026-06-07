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

MANHATTAN_FILE="$ASSETS_DIR/Manhattan.zip"
QOGIR_CURSOR_FILE="$ASSETS_DIR/Qogir-cursors.tar.xz"
MACTAHOE_ICONS_FILE="$ASSETS_DIR/MacTahoe.tar.xz"

section "Verificando dependências"

install_packages_smart unzip tar xz gtk3

section "Verificando pasta Assets"

if [[ ! -d "$ASSETS_DIR" ]]; then
  fail "Pasta Assets não encontrada em: $ASSETS_DIR"
fi

section "Criando diretórios"

mkdir -p "$THEMES_DIR"
mkdir -p "$ICONS_DIR"

ok "Diretório criado/verificado: ~/.themes"
ok "Diretório criado/verificado: ~/.icons"

extract_archive() {
  local archive_file="$1"
  local destination="$2"
  local label="$3"

  if [[ ! -f "$archive_file" ]]; then
    warn "Arquivo não encontrado: $archive_file"
    warn "Pulando: $label"
    return 0
  fi

  log "Instalando $label..."
  log "Arquivo: $archive_file"
  log "Destino: $destination"

  case "$archive_file" in
    *.zip)
      unzip -o "$archive_file" -d "$destination"
      ;;
    *.tar.xz)
      tar -xJf "$archive_file" -C "$destination"
      ;;
    *.tar.gz|*.tgz)
      tar -xzf "$archive_file" -C "$destination"
      ;;
    *.tar)
      tar -xf "$archive_file" -C "$destination"
      ;;
    *)
      warn "Formato não suportado: $archive_file"
      return 0
      ;;
  esac

  ok "$label instalado em $destination"
}

section "Instalando tema GTK"

extract_archive "$MANHATTAN_FILE" "$THEMES_DIR" "Tema Manhattan"

section "Instalando cursor"

extract_archive "$QOGIR_CURSOR_FILE" "$ICONS_DIR" "Cursor Qogir"

section "Instalando ícones"

extract_archive "$MACTAHOE_ICONS_FILE" "$ICONS_DIR" "Ícones MacTahoe"

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

Arquivos esperados em Assets:

  Assets/Manhattan.zip
  Assets/Qogir-cursors.tar.xz
  Assets/MacTahoe.tar.xz

Verifique no nwg-look:

  Tema GTK:
    Manhattan

  Cursor:
    Qogir

  Ícones:
    MacTahoe

Caso o nome apareça diferente no nwg-look, é porque o nome real vem do arquivo index.theme dentro de cada tema.
EOF

ok "Tema, cursor e ícones processados."