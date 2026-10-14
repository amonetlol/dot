#!/usr/bin/env bash
# Executa os módulos disponíveis na pasta atual

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/lib/common.sh"
else
  echo "[ERRO] lib/common.sh não encontrado."
  exit 1
fi

require_arch
require_not_root
ensure_sudo
check_internet

section "INSTALL ALL"

log "Este instalador executa somente os scripts encontrados na pasta atual."
log "Você pode apagar qualquer módulo antes de rodar este arquivo."

mapfile -t modules < <(
  find "$SCRIPT_DIR" -maxdepth 1 -type f -name '[0-9][0-9]-*.sh' | sort
)

if [[ "${#modules[@]}" -eq 0 ]]; then
  fail "Nenhum módulo encontrado no formato NN-*.sh."
fi

echo
log "Módulos encontrados:"
for module in "${modules[@]}"; do
  echo "  - $(basename "$module")"
done

echo
if ! confirm "Executar os módulos acima?" "S"; then
  warn "Operação cancelada."
  exit 0
fi

for module in "${modules[@]}"; do
  section "Executando $(basename "$module")"

  chmod +x "$module"

  if confirm "Executar $(basename "$module") agora?" "S"; then
    bash "$module"
    ok "Finalizado: $(basename "$module")"
  else
    warn "Pulando: $(basename "$module")"
  fi
done

section "FINALIZADO"
ok "Todos os módulos selecionados foram processados."