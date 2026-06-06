# ~/.bashrc
# Configuração principal do Bash

# ============================================================
# SOMENTE SHELL INTERATIVO
# ============================================================
 [[ $- != *i* ]] && return


# ============================================================
# BASH COMPLETION
# Pacote: bash-completion
# ============================================================
if [[ -f /usr/share/bash-completion/bash_completion ]]; then
    . /usr/share/bash-completion/bash_completion
fi


# ============================================================
# PATH
# ============================================================
case ":$PATH:" in
    *":$HOME/.bin:"*) ;;
    *) export PATH="$HOME/.bin:$PATH" ;;
esac

# ============================================================
# FUNÇÕES
# ============================================================

# Carrega funções
[[ -f "$HOME/.functions" ]] && . "$HOME/.functions"


# Detecta distro depois de carregar as funções
DISTRO="$(detect_distro)"


# ============================================================
# ALIASES
# ============================================================

# Aliases comuns
[[ -f "$HOME/.aliases" ]] && . "$HOME/.aliases"
[[ -f "$HOME/.aliases.sh" ]] && . "$HOME/.aliases.sh"

# Aliases especifícos da distro
case "$DISTRO" in
    arch)
        [[ -f "$HOME/.aliases-arch" ]] && . "$HOME/.aliases-arch"
        ;;
    debian)
        [[ -f "$HOME/.aliases-debian" ]] && . "$HOME/.aliases-debian"
        ;;
    nixos)
        [[ -f "$HOME/.aliases-nixos" ]] && . "$HOME/.aliases-nixos"
        ;;
    fedora)
        [[ -f "$HOME/.aliases-fedora" ]] && . "$HOME/.aliases-fedora"
        ;;
    opensuse)
        [[ -f "$HOME/.aliases-opensuse" ]] && . "$HOME/.aliases-opensuse"
        ;;
    solus)
        [[ -f "$HOME/.aliases-solus" ]] && . "$HOME/.aliases-solus"
        ;;
    unknown)
        # Descomente para debug:
        # echo "[AVISO] Distro não reconhecida."
        ;;
esac

# Debug opcional
# echo "[INFO] Distro detectada: $DISTRO"

# ============================================================
# HISTÓRICO
# ============================================================
export HISTFILESIZE=10000
export HISTSIZE=10000
export HISTTIMEFORMAT="%F %T "
export HISTCONTROL=erasedups:ignoredups:ignorespace

shopt -s histappend
shopt -s checkwinsize

# Salva histórico da sessão e lê histórico da sessão novo de outros terminais
PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"


# ============================================================
# PROMPT / FERRAMENTAS INTERATIVAS
# ============================================================
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi
