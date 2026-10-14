#!/usr/bin/env bash

# Inicia comandos desacoplados do terminal atual.
# Uso: run.sh comando [argumentos...]

if (($# == 0)); then
  printf 'Uso: %s comando [argumentos...]\n' "${0##*/}" >&2
  exit 2
fi

if ! command -v "$1" >/dev/null 2>&1; then
  printf 'Comando não encontrado: %s\n' "$1" >&2
  exit 127
fi

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/run-sh"
mkdir -p "$state_dir" || {
  printf 'Não foi possível criar o diretório de logs: %s\n' "$state_dir" >&2
  exit 1
}

command_name="${1##*/}"
command_name="${command_name//[^[:alnum:]_.-]/_}"
log_file="$state_dir/${command_name}-$(date +%Y%m%d-%H%M%S)-$$.log"

nohup "$@" >"$log_file" 2>&1 < /dev/null &
pid=$!

printf 'Iniciado em background. PID: %s\n' "$pid"
printf 'Log: %s\n' "$log_file"
