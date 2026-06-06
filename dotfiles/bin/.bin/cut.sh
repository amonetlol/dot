#!/bin/bash

# 1. Solicita o nome do vídeo original
echo "------------------------------------------------"
echo "Passo 1: Nome do arquivo original"
read -r -p "> " INPUT_FILE

# Verifica se o arquivo existe (importante para nomes com espaços)
if [ ! -f "$INPUT_FILE" ]; then
    echo "Erro: O arquivo '$INPUT_FILE' não foi encontrado."
    exit 1
fi

# 2. Solicita o tempo de início
echo "Passo 2: Tempo de INÍCIO (ex: 01:19:28)"
read -r -p "> " START_TIME

# 3. Solicita o tempo final
echo "Passo 3: Tempo FINAL (ex: 01:19:50)"
read -r -p "> " END_TIME

# 4. Solicita o nome do output
echo "Passo 4: Nome do arquivo de SAÍDA (sem extensão)"
read -r -p "> " OUTPUT_NAME

# Executa o corte mantendo codecs originais e forçando container mp4
ffmpeg -ss "$START_TIME" -to "$END_TIME" -i "$INPUT_FILE" -c copy "${OUTPUT_NAME}.mp4"

echo "------------------------------------------------"
echo "Sucesso! Arquivo gerado: ${OUTPUT_NAME}.mp4"
