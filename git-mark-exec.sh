#!/usr/bin/env bash
set -euo pipefail

# git-mark-exec.sh
# Marca todos os *.sh e o arquivo update_repo como executáveis no índice do Git,
# commit e push. Rode a partir da raiz do repositório.

# Ajuste: no Windows/NTFS, o modo de arquivo pode não ser observado; usamos
# `git update-index --chmod=+x` para garantir que o bit seja registrado.

# Primeiro, detecta arquivos alvo
files=$(git ls-files -- "*.sh" 2>/dev/null || true)
if [ -n "$(git ls-files -- "update_repo" 2>/dev/null || true)" ]; then
  files="$files
update_repo"
fi

if [ -z "$(echo "$files" | tr -d '[:space:]')" ]; then
  echo "Nenhum arquivo rastreado encontrado (*.sh ou update_repo). Saindo."
  exit 0
fi

echo "Arquivos a marcar como executáveis:"
echo "$files"

# Marca cada arquivo
while IFS= read -r f; do
  [ -z "$f" ] && continue
  echo "Marcando +x no índice para: $f"
  git update-index --chmod=+x -- "$f"
done <<< "$files"

# Adiciona e commita
git add -u
read -p "Mensagem de commit (enter para padrão): " msg
msg=${msg:-"Mark scripts executable"}

git commit -m "$msg"

# Push
read -p "Deseja dar push agora? [y/N]: " yn
if [[ "$yn" =~ ^[Yy]$ ]]; then
  git push
fi

echo "Pronto." 
