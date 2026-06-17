#!/bin/bash
# Script para instalar MacTahoe GTK Theme no Arch Linux

set -e  # Para o script em caso de erro

echo "=== Instalando MacTahoe GTK Theme ==="

# 1. Instalar dependências necessárias no Arch
echo "Instalando dependências..."
sudo pacman -S --needed git sassc glib2 librsvg optipng inkscape imagemagick dialog --noconfirm

# 2. Clonar o repositório (shallow clone para ser mais rápido)
if [ -d "MacTahoe-gtk-theme" ]; then
    echo "Repositório já existe, atualizando..."
    cd MacTahoe-gtk-theme
    git pull
else
    echo "Clonando repositório..."
    git clone https://github.com/vinceliuice/MacTahoe-gtk-theme.git --depth=1
    cd MacTahoe-gtk-theme
fi

# 3. Dar permissão de execução
chmod +x install.sh tweaks.sh

# 4. Instalar com suas opções
echo "Instalando tema com as configurações solicitadas..."
./install.sh \
  -c dark \
  -o solid \
  -t default \
  -t blue \
  -t grey \
  -s nord \
  -l \
  -HD \
  --shell -i arch

echo ""
echo "✅ Instalação concluída!"
echo ""
echo "Dicas pós-instalação:"
echo "1. Reinicie o GNOME Shell (Alt+F2 → r → Enter)"
echo "2. Use o GNOME Tweaks para selecionar:"
echo "   - Appearance → Themes → GTK Theme → MacTahoe (ou variante)"
echo "   - Shell (User Themes extension)"
echo "3. Recomendado instalar também o ícone e cursor do autor:"
echo "   https://github.com/vinceliuice/MacTahoe-icon-theme"
echo ""
echo "Para desinstalar: ./install.sh -r"
