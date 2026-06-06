#!/usr/bin/env bash
# Common helpers for Arch modular installer

set -euo pipefail

# =========================
# Colors
# =========================
if [[ -t 1 ]]; then
  RED="\033[0;31m"
  GREEN="\033[0;32m"
  YELLOW="\033[1;33m"
  BLUE="\033[0;34m"
  BOLD="\033[1m"
  RESET="\033[0m"
else
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  BOLD=""
  RESET=""
fi

log() {
  echo -e "${BLUE}[INFO]${RESET} $*"
}

ok() {
  echo -e "${GREEN}[OK]${RESET} $*"
}

warn() {
  echo -e "${YELLOW}[AVISO]${RESET} $*"
}

fail() {
  echo -e "${RED}[ERRO]${RESET} $*" >&2
  exit 1
}

section() {
  echo
  echo -e "${BOLD}${BLUE}============================================================${RESET}"
  echo -e "${BOLD}${BLUE} $*${RESET}"
  echo -e "${BOLD}${BLUE}============================================================${RESET}"
}

confirm() {
  local prompt="${1:-Continuar?}"
  local default="${2:-S}"

  if [[ "${AUTO_YES:-0}" == "1" ]]; then
    return 0
  fi

  local answer
  read -r -p "$prompt [S/n]: " answer
  answer="${answer:-$default}"

  case "$answer" in
    s|S|sim|SIM|y|Y|yes|YES)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

require_arch() {
  if [[ ! -f /etc/arch-release ]]; then
    fail "Este script foi feito para Arch Linux e derivados."
  fi
}

require_not_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    fail "Não rode este script como root. Use seu usuário normal com sudo."
  fi
}

check_internet() {
  log "Verificando conexão com a internet..."
  if ping -c 1 -W 3 archlinux.org >/dev/null 2>&1; then
    ok "Internet funcionando."
  elif ping -c 1 -W 3 github.com >/dev/null 2>&1; then
    ok "Internet funcionando."
  else
    fail "Sem conexão com a internet ou DNS indisponível."
  fi
}

backup_path() {
  local path="$1"

  if [[ -e "$path" || -L "$path" ]]; then
    local backup="${path}.bak-$(date +%Y%m%d-%H%M%S)"
    log "Backup: $path -> $backup"
    mv "$path" "$backup"
  fi
}

ensure_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    fail "sudo não encontrado. Instale/configure sudo antes de continuar."
  fi

  sudo -v
}

pacman_sync() {
  sudo pacman -Sy --needed --noconfirm "$@"
}

pkg_installed() {
  pacman -Qi "$1" >/dev/null 2>&1
}

ensure_pacman_pkg() {
  local pkg="$1"

  if pkg_installed "$pkg"; then
    ok "$pkg já instalado."
  else
    log "Instalando $pkg via pacman..."
    pacman_sync "$pkg"
  fi
}

ensure_base_devel() {
  log "Garantindo base-devel e git..."
  pacman_sync base-devel git
}

ensure_yay() {
  if command -v yay >/dev/null 2>&1; then
    ok "yay já instalado."
    return 0
  fi

  section "Instalando yay-bin"

  ensure_base_devel

  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
  cd "$tmpdir/yay-bin"
  makepkg -si --noconfirm
  cd - >/dev/null

  ok "yay instalado."
}

install_pacman_packages() {
  local packages=("$@")
  local missing=()

  for pkg in "${packages[@]}"; do
    if pkg_installed "$pkg"; then
      ok "$pkg já instalado."
    else
      missing+=("$pkg")
    fi
  done

  if [[ "${#missing[@]}" -gt 0 ]]; then
    log "Instalando pacotes via pacman:"
    printf '  - %s\n' "${missing[@]}"
    pacman_sync "${missing[@]}"
  fi
}

install_aur_packages() {
  local packages=("$@")

  if [[ "${#packages[@]}" -eq 0 ]]; then
    return 0
  fi

  ensure_yay

  log "Instalando pacotes via yay/AUR:"
  printf '  - %s\n' "${packages[@]}"
  yay -S --needed --noconfirm "${packages[@]}"
}

install_packages_smart() {
  local packages=("$@")
  local pacman_ok=()
  local aur_try=()

  for pkg in "${packages[@]}"; do
    if pkg_installed "$pkg"; then
      ok "$pkg já instalado."
      continue
    fi

    if pacman -Si "$pkg" >/dev/null 2>&1; then
      pacman_ok+=("$pkg")
    else
      aur_try+=("$pkg")
    fi
  done

  if [[ "${#pacman_ok[@]}" -gt 0 ]]; then
    install_pacman_packages "${pacman_ok[@]}"
  fi

  if [[ "${#aur_try[@]}" -gt 0 ]]; then
    install_aur_packages "${aur_try[@]}"
  fi
}

safe_clone_or_update() {
  local repo="$1"
  local target="$2"

  if [[ -d "$target/.git" ]]; then
    log "Atualizando repositório existente: $target"
    git -C "$target" pull --ff-only || warn "Não foi possível atualizar $target. Verifique manualmente."
    return 0
  fi

  if [[ -e "$target" ]]; then
    backup_path "$target"
  fi

  log "Clonando $repo em $target"
  git clone "$repo" "$target"
}

enable_service_if_exists() {
  local service="$1"

  if systemctl list-unit-files "$service" >/dev/null 2>&1; then
    sudo systemctl enable --now "$service"
    ok "Serviço ativado: $service"
  else
    warn "Serviço não encontrado: $service"
  fi
}

user_enable_service_if_exists() {
  local service="$1"

  if systemctl --user list-unit-files "$service" >/dev/null 2>&1; then
    systemctl --user enable --now "$service"
    ok "Serviço de usuário ativado: $service"
  else
    warn "Serviço de usuário não encontrado: $service"
  fi
}