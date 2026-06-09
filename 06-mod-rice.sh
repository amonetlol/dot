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
CATPPUCCIN_FILE="$ASSETS_DIR/catppuccin-mocha-blue-standard+default.zip"

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
      unzip -o -q "$archive_file" -d "$destination"
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

# Função dedicada para o Catppuccin devido à necessidade de renomear a pasta interna
install_catppuccin() {
  local archive_file="$1"
  local themes_dir="$2"
  local tmp_dir="/tmp/catppuccin-theme"
  local final_dest="$themes_dir/catppuccin-mocha-blue"

  if [[ ! -f "$archive_file" ]]; then
    warn "Arquivo não encontrado: $archive_file"
    warn "Pulando: Tema Catppuccin"
    return 0
  fi

  log "Instalando Tema Catppuccin..."
  log "Arquivo: $archive_file"
  log "Destino: $final_dest"

  # Limpa resquícios antigos no /tmp, cria e extrai de forma silenciosa (-q)
  rm -rf "$tmp_dir"
  mkdir -p "$tmp_dir"
  unzip -o -q "$archive_file" -d "$tmp_dir"

  # Remove versão antiga se existir no destino final e move a nova pasta renomeada
  rm -rf "$final_dest"
  cp -r "$tmp_dir/catppuccin-mocha-blue-standard+default" "$final_dest"

  # Limpeza
  rm -rf "$tmp_dir"

  ok "Tema catppuccin-mocha-blue instalado com sucesso!"
}

section "Instalando temas GTK"

extract_archive "$MANHATTAN_FILE" "$THEMES_DIR" "Tema Manhattan"
install_catppuccin "$CATPPUCCIN_FILE" "$THEMES_DIR"

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
  Assets/catppuccin-mocha-blue-standard+default.zip

Verifique no nwg-look:

  Tema GTK:
    Manhattan || catppuccin-mocha-blue 

  Cursor:
    Qogir

  Ícones:
    MacTahoe

Caso o nome apareça diferente no nwg-look, é porque o nome real vem do arquivo index.theme dentro de cada tema.
EOF

ok "Tema, cursor e ícones processados."
