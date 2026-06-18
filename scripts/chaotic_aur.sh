#!/bin/bash
# =============================================
# Script para adicionar Chaotic-AUR no Arch Linux
# =============================================

set -e  # Para o script em caso de erro

echo "=== Adicionando Chaotic-AUR ==="

# 1. Adicionar a chave primária
echo "→ Recebendo chave GPG..."
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB

# 2. Instalar keyring e mirrorlist diretamente dos servidores do Chaotic
echo "→ Instalando chaotic-keyring e chaotic-mirrorlist..."
sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# 3. Adicionar o repositório no final do pacman.conf
echo "→ Configurando /etc/pacman.conf..."
if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    echo -e "\n[chaotic-aur]" | sudo tee -a /etc/pacman.conf > /dev/null
    echo "SigLevel = Optional TrustedOnly" | sudo tee -a /etc/pacman.conf > /dev/null
    echo "Include = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf > /dev/null
    echo "✅ Repositório Chaotic-AUR adicionado com sucesso!"
else
    echo "⚠️  Chaotic-AUR já está configurado no pacman.conf"
fi

# 4. Atualizar o sistema
echo "→ Atualizando banco de dados e sistema..."
sudo pacman -Syu --noconfirm

echo ""
echo "🎉 Chaotic-AUR foi adicionado com sucesso!"
echo "Você agora pode instalar pacotes com: sudo pacman -S pacote"
echo "Exemplo: sudo pacman -S firedragon"
