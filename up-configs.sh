#!/usr/bin/env bash
# Upgrade de configs Linux — menu interativo com backup automático

set -euo pipefail

NVIM_REPO="https://github.com/amonetlol/nvim"
DOT_REPO="https://github.com/amonetlol/dot"

TMP_DIR=""
DOT_CLONED=0
NVIM_CLONED=0

if [[ -t 1 ]]; then
  RED="\033[0;31m"
  GREEN="\033[0;32m"
  YELLOW="\033[1;33m"
  BLUE="\033[0;34m"
  BOLD="\033[1m"
  RESET="\033[0m"
else
  RED="" GREEN="" YELLOW="" BLUE="" BOLD="" RESET=""
fi

log()  { echo -e "${BLUE}[INFO]${RESET} $*"; }
ok()   { echo -e "${GREEN}[OK]${RESET} $*"; }
warn() { echo -e "${YELLOW}[AVISO]${RESET} $*"; }
fail() { echo -e "${RED}[ERRO]${RESET} $*" >&2; }

backup_date() { date +%d-%m-%Y; }

backup_path() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    local backup="${path}-$(backup_date)-backup"
    if [[ -e "$backup" ]]; then
      backup="${path}-$(backup_date)-$(date +%H%M%S)-backup"
    fi
    mv "$path" "$backup"
    log "Backup: $path -> $backup"
  fi
}

ensure_tmp_dir() {
  if [[ -z "$TMP_DIR" || ! -d "$TMP_DIR" ]]; then
    TMP_DIR="$(mktemp -d /tmp/up-configs-XXXXXX)"
    log "Pasta temporária: $TMP_DIR"
  fi
}

cleanup_tmp_dir() {
  local dir
  for dir in /tmp/up-configs-*; do
    [[ -d "$dir" ]] || continue
    log "Removendo pasta temporária: $dir"
    rm -rf "$dir"
  done
  TMP_DIR=""
  DOT_CLONED=0
  NVIM_CLONED=0
}

check_git() {
  if ! command -v git >/dev/null 2>&1; then
    fail "git não encontrado. Instale git antes de continuar."
    return 1
  fi
}

check_internet() {
  if ping -c 1 -W 3 github.com >/dev/null 2>&1; then
    return 0
  fi
  fail "Sem conexão com github.com."
  return 1
}

clone_dot_repo() {
  ensure_tmp_dir
  if [[ "$DOT_CLONED" -eq 1 ]]; then
    return 0
  fi
  check_git || return 1
  check_internet || return 1

  local target="$TMP_DIR/dot"
  log "Clonando $DOT_REPO ..."
  if git clone --depth 1 "$DOT_REPO" "$target" >/dev/null 2>&1; then
    DOT_CLONED=1
    ok "Repositório dot clonado."
    return 0
  fi
  fail "Falha ao clonar repositório dot."
  return 1
}

clone_nvim_repo() {
  ensure_tmp_dir
  if [[ "$NVIM_CLONED" -eq 1 ]]; then
    return 0
  fi
  check_git || return 1
  check_internet || return 1

  local target="$TMP_DIR/nvim"
  log "Clonando $NVIM_REPO ..."
  if git clone --depth 1 "$NVIM_REPO" "$target" >/dev/null 2>&1; then
    NVIM_CLONED=1
    ok "Repositório nvim clonado."
    return 0
  fi
  fail "Falha ao clonar repositório nvim."
  return 1
}

copy_tree() {
  local src="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a "$src/" "$dest/"
  else
    cp -a "$src/." "$dest/"
  fi
}

upgrade_nvim() {
  local dest="$HOME/.config/nvim"
  clone_nvim_repo || return 1

  local src="$TMP_DIR/nvim"
  if [[ ! -d "$src" ]]; then
    fail "Origem nvim não encontrada em $src"
    return 1
  fi

  mkdir -p "$HOME/.config"
  backup_path "$dest"
  copy_tree "$src" "$dest"
  ok "Nvim instalado em $dest"
  return 0
}

upgrade_fastfetch() {
  clone_dot_repo || return 1

  local src="$TMP_DIR/dot/dotfiles/fastfetch/.config/fastfetch"
  local dest="$HOME/.config/fastfetch"

  if [[ ! -d "$src" ]]; then
    fail "Origem fastfetch não encontrada em $src"
    return 1
  fi

  mkdir -p "$HOME/.config"
  backup_path "$dest"
  copy_tree "$src" "$dest"
  ok "Fastfetch instalado em $dest"
  return 0
}

upgrade_bash() {
  clone_dot_repo || return 1

  local src_dir="$TMP_DIR/dot/dotfiles/bash"
  local files=(".aliases" ".aliases-arch" ".bashrc" ".functions")
  local file

  if [[ ! -d "$src_dir" ]]; then
    fail "Origem bash não encontrada em $src_dir"
    return 1
  fi

  for file in "${files[@]}"; do
    local src="$src_dir/$file"
    local dest="$HOME/$file"
    if [[ ! -f "$src" ]]; then
      fail "Arquivo não encontrado: $src"
      return 1
    fi
    backup_path "$dest"
    cp -a "$src" "$dest"
    ok "Copiado: $dest"
  done
  return 0
}

upgrade_fonts() {
  clone_dot_repo || return 1

  local src="$TMP_DIR/dot/dotfiles/fonts/.fonts"
  local dest="$HOME/.fonts"

  if [[ ! -d "$src" ]]; then
    fail "Origem fonts não encontrada em $src"
    return 1
  fi

  backup_path "$dest"
  mkdir -p "$dest"
  copy_tree "$src" "$dest"

  if command -v fc-cache >/dev/null 2>&1; then
    log "Atualizando cache de fontes..."
    fc-cache -fv "$dest" >/dev/null 2>&1 || warn "fc-cache retornou aviso (pode ser ignorado)."
  fi

  ok "Fonts instaladas em $dest"
  return 0
}

upgrade_shortcuts() {
  clone_dot_repo || return 1

  local src="$TMP_DIR/dot/dotfiles/shortcuts/.local/share/applications"
  local dest="$HOME/.local/share/applications"

  if [[ ! -d "$src" ]]; then
    fail "Origem shortcuts não encontrada em $src"
    return 1
  fi

  mkdir -p "$HOME/.local/share"
  backup_path "$dest"
  mkdir -p "$dest"
  copy_tree "$src" "$dest"
  ok "Shortcuts instalados em $dest"
  return 0
}

upgrade_bin() {
  clone_dot_repo || return 1

  local src="$TMP_DIR/dot/dotfiles/bin/.bin"
  local dest="$HOME/.bin"

  if [[ ! -d "$src" ]]; then
    fail "Origem .bin não encontrada em $src"
    return 1
  fi

  backup_path "$dest"
  mkdir -p "$dest"
  copy_tree "$src" "$dest"
  find "$dest" -type f -exec chmod +x {} \;
  ok "Permissões executáveis aplicadas em $dest"
  ok ".bin instalado em $dest"
  return 0
}


declare -A CONFIG_NAMES=(
  [1]="Nvim"
  [2]="Fastfetch"
  [3]="Bash"
  [4]="Fonts"
  [5]="Shortcuts"
  [6]=".bin"
)

run_upgrade() {
  local id="$1"
  local name="${CONFIG_NAMES[$id]:-Desconhecido}"
  local rc=0

  echo
  echo -e "${BOLD}>>> Atualizando: $name${RESET}"
  echo

  set +e
  case "$id" in
    1) upgrade_nvim ;;
    2) upgrade_fastfetch ;;
    3) upgrade_bash ;;
    4) upgrade_fonts ;;
    5) upgrade_shortcuts ;;
    6) upgrade_bin ;;
    *) fail "Opção inválida: $id"; rc=1 ;;
  esac
  rc=${rc:-$?}
  set -e

  if [[ "$rc" -eq 0 ]]; then
    echo -e "${GREEN}[SUCESSO]${RESET} $name"
    return 0
  fi

  echo -e "${RED}[FALHOU]${RESET} $name"
  return 1
}

parse_selection() {
  local input="$1"
  local -n _result=$2
  _result=()

  input="$(echo "$input" | tr -d ' ' | tr '[:upper:]' '[:lower:]')"

  if [[ -z "$input" ]]; then
    return 1
  fi

  if [[ "$input" == "all" || "$input" == "todos" || "$input" == "a" ]]; then
    _result=(1 2 3 4 5 6)
    return 0
  fi

  local part start end i
  IFS=',' read -ra parts <<< "$input"
  for part in "${parts[@]}"; do
    if [[ "$part" =~ ^([1-6])-([1-6])$ ]]; then
      start="${BASH_REMATCH[1]}"
      end="${BASH_REMATCH[2]}"
      if (( start > end )); then
        local tmp="$start"
        start="$end"
        end="$tmp"
      fi
      for ((i = start; i <= end; i++)); do
        _result+=("$i")
      done
    elif [[ "$part" =~ ^[1-6]$ ]]; then
      _result+=("$part")
    else
      return 1
    fi
  done

  if [[ "${#_result[@]}" -eq 0 ]]; then
    return 1
  fi

  local -A seen=()
  local unique=()
  for i in "${_result[@]}"; do
    if [[ -z "${seen[$i]:-}" ]]; then
      seen[$i]=1
      unique+=("$i")
    fi
  done
  _result=("${unique[@]}")
  return 0
}

show_menu() {
  echo
  echo -e "${BOLD}${BLUE}========================================${RESET}"
  echo -e "${BOLD}     Upgrade de Configs Linux${RESET}"
  echo -e "${BOLD}${BLUE}========================================${RESET}"
  [[ -n "$TMP_DIR" ]] && echo -e "Pasta tmp: ${YELLOW}$TMP_DIR${RESET}"
  echo
  echo "  1) Nvim"
  echo "  2) Fastfetch"
  echo "  3) Bash"
  echo "  4) Fonts"
  echo "  5) Shortcuts"
  echo "  6) .bin"
  echo
  echo "  0) Sair"
  echo
  echo "Selecione: número (1), vários (1,3,5), range (1-3), todos (all)"
  echo
}

process_selection() {
  local choices=("$@")
  local id
  local success=0
  local failed=0

  ensure_tmp_dir

  echo
  echo -e "${BOLD}Resumo da operação${RESET}"
  echo "----------------------------------------"

  for id in "${choices[@]}"; do
    if run_upgrade "$id"; then
      ((success++)) || true
    else
      ((failed++)) || true
    fi
  done

  echo "----------------------------------------"
  echo -e "Concluído: ${GREEN}$success sucesso${RESET}, ${RED}$failed falha(s)${RESET}"
  echo
}

trap cleanup_tmp_dir EXIT

main() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    warn "Este script foi feito para Linux."
  fi

  if [[ "${EUID:-0}" -eq 0 ]]; then
    fail "Não execute como root. Use seu usuário normal."
    exit 1
  fi

  local input choices=()

  while true; do
    show_menu
    read -r -p "Escolha: " input

    input="$(echo "$input" | tr -d ' ' | tr '[:upper:]' '[:lower:]')"

    if [[ "$input" == "0" || "$input" == "sair" || "$input" == "q" || "$input" == "exit" ]]; then
      cleanup_tmp_dir
      trap - EXIT
      ok "Até logo!"
      exit 0
    fi

    if ! parse_selection "$input" choices; then
      warn "Seleção inválida. Use 1-6, 1,3,6, 1-3 ou all."
      continue
    fi

    process_selection "${choices[@]}"

    read -r -p "Pressione Enter para voltar ao menu..."
  done
}

main "$@"
