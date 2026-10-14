#!/bin/bash
# =============================================
# Script para trocar tema MacTahoe (Shell + GTK)
# =============================================

THEMES_DIR="$HOME/.themes"

echo "🔍 Procurando temas MacTahoe em $THEMES_DIR..."
echo ""

# Verifica se a pasta existe e lista temas MacTahoe
if [ ! -d "$THEMES_DIR" ]; then
    echo "❌ Pasta ~/.themes não encontrada!"
    echo "Execute o instalador do MacTahoe primeiro."
    exit 1
fi

# Lista apenas pastas que começam com MacTahoe-
mapfile -t THEME_LIST < <(ls -1 "$THEMES_DIR" 2>/dev/null | grep '^MacTahoe-' | sort)

if [ ${#THEME_LIST[@]} -eq 0 ]; then
    echo "❌ Nenhum tema MacTahoe encontrado em ~/.themes"
    exit 1
fi

echo "🎨 Temas MacTahoe disponíveis:"
echo "========================================"

for i in "${!THEME_LIST[@]}"; do
    printf "%2d) %s\n" $((i+1)) "${THEME_LIST[i]}"
done

echo "========================================"
echo ""

while true; do
    read -p "Digite o número do tema que deseja aplicar: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#THEME_LIST[@]}" ]; then
        SELECTED_THEME="${THEME_LIST[$((choice-1))]}"
        break
    else
        echo "❌ Opção inválida! Tente novamente."
    fi
done

echo ""
echo "🚀 Aplicando tema: $SELECTED_THEME"

# Aplicar temas via gsettings
gsettings set org.gnome.desktop.interface gtk-theme "$SELECTED_THEME"
gsettings set org.gnome.desktop.wm.preferences theme "$SELECTED_THEME"
gsettings set org.gnome.shell.extensions.user-theme name "$SELECTED_THEME"

echo "✅ Tema aplicado com sucesso!"
echo ""
echo "🎉 Pronto! Tema $SELECTED_THEME aplicado em Shell e Aplicativos."
echo "Se precisar trocar novamente, rode este script."
