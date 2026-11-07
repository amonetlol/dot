# term-hub

Execute `term-hub` em um terminal. O launcher fica em `~/.local/bin/term-hub`
e os arquivos de suporte em `~/.local/bin/term-hub.d/`.

Dependências: Python 3, tmux e OpenSSH. O atalho de edição usa Neovim.
O hub tem socket tmux próprio; não altera a configuração global do tmux.
As conexões são opcionais e não vêm preenchidas. Edite `ssh.conf` (permissão 600):

```text
Alias
Hostname
User
Pass
```

Blocos totalmente vazios são ignorados; `Pass` vazio permite usar chave SSH ou senha interativa.
Prefixo: Ctrl+b, soltar, depois a tecla. `?` exibe `atalhos.txt`; `e` edita os campos.
`t`/`m`/`v` alternam modos; `c` cria terminal; `s` abre conexões; `T` usa destino temporário.
`d` desconecta do hub preservando os processos.

Terminais iniciais: `term-1`, `term-2` e `term-3`. `term-hub top` abre o monitor; `term-hub status` gera a barra.
