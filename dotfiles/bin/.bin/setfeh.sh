#!/usr/bin/env bash

# Script para configurar wallpaper com feh no Qtile
# Coloque isso dentro de ~/.config/qtile/src/autostart.sh ou chame-o de lá

WALLS_CONFIG="$HOME/.config/qtile/walls"
WALLS_HOME="$HOME/walls"

# 1. Verifica se a pasta de wallpapers existe na config do qtile
if [[ ! -d "$WALLS_CONFIG" ]]; then
    echo "Erro: Pasta de wallpapers não encontrada em $WALLS_CONFIG"
    exit 1
fi

# 2. Cria link simbólico ~/walls → ~/.config/qtile/walls (se não existir)
if [[ ! -e "$WALLS_HOME" ]]; then
    echo "Criando link simbólico ~/walls → $WALLS_CONFIG"
    ln -s "$WALLS_CONFIG" "$WALLS_HOME"
# elif [[ "$(readlink -f "$WALLS_HOME")" != "$WALLS_CONFIG" ]]; then
#     # Se ~/walls existe mas aponta para outro lugar, faz backup e recria o link
#     echo "Aviso: ~/walls existe mas aponta para outro local. Fazendo backup..."
#     mv "$WALLS_HOME" "$WALLS_HOME.bak.$(date +%Y%m%d_%H%M%S)"
#     ln -s "$WALLS_CONFIG" "$WALLS_HOME"
#     echo "Link simbólico criado: ~/walls → $WALLS_CONFIG"
else
    echo "~/walls já está corretamente ligado a $WALLS_CONFIG"
fi

# 3. Define o wallpaper aleatório com feh
echo "Aplicando wallpaper aleatório com feh..."
#feh --randomize --bg-fill ~/walls/wall1.jpg
sh ~/.fehbg

# 4. (Opcional) Executa o último .fehbg salvo, caso queira restaurar o anterior em vez de randomizar
# Comente a linha acima e descomente a de baixo se preferir restaurar o último wallpaper usado
# [[ -f "$HOME/.fehbg" ]] && "$HOME/.fehbg" &

echo "Wallpaper configurado!"
