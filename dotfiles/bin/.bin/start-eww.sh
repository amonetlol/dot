#!/bin/bash
# =============================================
# Script para iniciar eww + rainmeter_desktop
# =============================================

echo "🔄 Iniciando eww..."

# Mata qualquer instância anterior
eww kill 2>/dev/null

# Aguarda um pouco
sleep 0.5

# Inicia o daemon em background
eww daemon &

# Aguarda o daemon iniciar
sleep 0.8

# Abre o widget
eww open rainmeter_desktop

echo "✅ eww iniciado com sucesso!"
