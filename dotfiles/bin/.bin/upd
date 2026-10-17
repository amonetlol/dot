#!/usr/bin/env bash
# Executa o up-configs.sh remoto

set -euo pipefail

URL="https://raw.githubusercontent.com/amonetlol/dot/refs/heads/main/dotfiles/bin/.bin/up-configs.sh"

if ! command -v curl >/dev/null 2>&1; then
  echo "Erro: curl não encontrado." >&2
  exit 1
fi

echo "Baixando e executando up-configs.sh..."
bash <(curl -fsSL "$URL")
