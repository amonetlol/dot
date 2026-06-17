#!/usr/bin/env bash
# =====================================================
# Script de execução automática para configuração
# =====================================================

# Dar permissão de execução nos scripts
chmod +x gnome_shortcuts.sh
chmod +x install-mactahoe-gkt-theme.sh
chmod +x set-mactahoe-gkt-theme.sh
chmod +x vmware_shared_folder.sh

echo "🚀 Iniciando sequência de execução..."
echo ""

# 1. Configurar atalhos GNOME
echo "📌 [1/4] Executando gnome_shortcuts.sh..."
bash "$PWD/gnome_shortcuts.sh"
if [ $? -eq 0 ]; then
    echo "✅ gnome_shortcuts.sh concluído"
else
    echo "❌ Erro ao executar gnome_shortcuts.sh"
    exit 1
fi

echo ""

# 2. Instalar tema MacTahoe
echo "🎨 [2/4] Executando install-mactahoe-gkt-theme.sh..."
bash "$PWD/install-mactahoe-gkt-theme.sh"
if [ $? -eq 0 ]; then
    echo "✅ install-mactahoe-gkt-theme.sh concluído"
else
    echo "❌ Erro ao executar install-mactahoe-gkt-theme.sh"
    exit 1
fi

echo ""

# 3. Aplicar tema MacTahoe
echo "🎯 [3/4] Executando set-mactahoe-gkt-theme.sh..."
bash "$PWD/set-mactahoe-gkt-theme.sh"
if [ $? -eq 0 ]; then
    echo "✅ set-mactahoe-gkt-theme.sh concluído"
else
    echo "❌ Erro ao executar set-mactahoe-gkt-theme.sh"
    exit 1
fi

echo ""

# 4. Configurar pasta compartilhada VMware
echo "🖥️ [4/4] Executando vmware_shared_folder.sh..."
bash "$PWD/vmware_shared_folder.sh"
if [ $? -eq 0 ]; then
    echo "✅ vmware_shared_folder.sh concluído"
else
    echo "❌ Erro ao executar vmware_shared_folder.sh"
    exit 1
fi

echo ""
echo "🎉 Sequência concluída com sucesso!"