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

Acompanhamento: `Ctrl+b f` acompanha `/tmp/ff-install.log`, `/tmp/ff-scripts.log` e
`/tmp/ff-downloads.log`; `Ctrl+b F` acompanha os arquivos existentes
`/tmp/ff-DISTRO.log` (um para cada distro). O hub usa painéis livres ou cria novos, preservando os que estão em uso. As sessões independentes no socket padrão são acessíveis com
`tmux attach -t ff` e `tmux attach -t ffd`. Para criar os logs com os nomes
das distros durante a instalação, execute `bash tmux-attach-ff_ffd.sh fedora debian` do repo sh.
O script cria as sessões sem anexar, para você escolher como acompanhar.

Ao executar cada instalador, grave sua saída no log geral e no da distro:

```bash
set -o pipefail
bash instalador.sh 2>&1 | tee -a /tmp/ff-install.log /tmp/ff-fedora.log
```

Use o nome da distro correspondente em cada instalação. Para preparar os
monitores antecipadamente, execute no início da instalação:

```bash
bash tmux-attach-ff_ffd.sh fedora debian
```
