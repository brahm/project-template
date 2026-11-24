# Instalar e atualizar o kit

(English: [INSTALL.md](INSTALL.md).)

Este manual cobre os três casos: um projeto novo, um projeto que já está
em andamento, e manter o kit e os seus projetos atualizados. O jeito mais
simples é um prompt para o seu agente de código; por baixo, tudo é feito
por um script só, o `install.sh`, no seu próprio computador.

## O que é preciso

- `bash`, `git` e Python 3.11 ou mais novo, no Linux, no macOS, ou no
  Windows dentro do WSL (veja "Windows", abaixo).
- A linha de comando do GitHub, o [`gh`](https://cli.github.com), para a
  parte do GitHub (o repositório, o segredo e as regras da `main`). Se ele
  não estiver logado, o instalador roda o `gh auth login` para você, e
  acrescenta a permissão `workflow`, que o envio dos workflows do kit
  exige.
- O Claude Code, para o `claude setup-token`, se você quer que a revisão
  automática de cada pull request rode no seu plano Claude Pro ou Max. Sem
  ele, o instalador pede para colar um token feito em outro computador, ou
  pula esse passo.
- Opcional: o [`reuse`](https://reuse.software), para a verificação de
  licenças (`pipx install reuse`).

## A partir de um prompt (o mais simples)

Abra o Claude Code (ou outro agente de código) na pasta do projeto: uma
pasta vazia para um projeto novo, ou o projeto que você já tem. Cole:

```text
Instale o agent project kit nesta pasta. Clone
https://github.com/brahm/project-template numa pasta temporária e siga o
INSTALL-AGENT.md dele. O que eu quero construir: ...
```

(Num projeto em andamento, deixe de fora a última frase.) O agente
confere as ferramentas e o seu login no GitHub, vê se a pasta é um
projeto novo ou um em andamento, pergunta uma vez só o que não consegue
deduzir, roda o `install.sh` com todos os valores e, na mesma conversa,
começa o projeto a partir do seu briefing ou adota o kit no seu código.
Para atualizar, cole o mesmo prompt num projeto que já tem o kit: ele roda
o `install.sh update` e a skill `update-from-template`.

Dois passos ficam com você, num terminal seu, porque são interativos e o
agente não consegue digitar neles:

- `gh auth login -h github.com -s workflow`, só se o `gh` não estiver
  logado (o agente avisa).
- `scripts/setup-github.sh`, na raiz do projeto, para salvar o token do
  seu plano Claude para a revisão automática. Ele oferece rodar o `claude
  setup-token` e lê o token sem mostrá-lo, então o token nunca passa pela
  conversa. Não cole o token no chat.

O procedimento que o agente segue está no
[INSTALL-AGENT.md](INSTALL-AGENT.md). As seções abaixo são os mesmos
passos à mão.

## Como pegar o instalador

Uma linha, num terminal:

```sh
curl -fsSL https://raw.githubusercontent.com/brahm/project-template/main/install.sh | sh
```

Ele confere o `git`, o `bash` e o `python3` (e diz como instalar o que
faltar), guarda o kit em `~/.agent-kit` (ou `AGENT_KIT_HOME`), atualizando
se ele já estiver lá, cria o comando `agent-kit` em `~/.local/bin` e
pergunta o que fazer na pasta atual: começar um projeto novo, colocar o
kit no projeto que está ali, ou atualizar. Para já dizer o que quer,
acrescente o comando depois de `sh -s --`:

```sh
curl -fsSL https://raw.githubusercontent.com/brahm/project-template/main/install.sh | sh -s -- new meu-projeto
```

Daqui em diante, `install.sh` quer dizer o comando `agent-kit`, ou o
`install.sh` de uma cópia do kit (`git clone
https://github.com/brahm/project-template agent-kit`), se você preferir
uma.

## Windows

O kit roda no WSL, o Linux de dentro do Windows. Uma vez, no PowerShell:

```powershell
wsl --install
```

Reinicie se ele pedir, abra o "Ubuntu" pelo menu Iniciar, instale as
ferramentas (`sudo apt install git python3`, e o `gh` como manda
https://cli.github.com) e rode a linha acima lá. Guarde os seus projetos
na sua pasta do WSL (`cd ~`): em `/mnt/c` eles funcionam, mas mais
devagar. O Claude Code, o VS Code e os outros agentes abrem pastas do WSL
direto. O instalador recusa o Git Bash, o MSYS e o Cygwin e explica isso.

## Um projeto novo

```sh
install.sh new meu-projeto
```

Na ordem, ele:

1. Copia o modelo para a pasta `meu-projeto` e roda nela o
   `init-project.sh`. Nome, dono, idiomas, fuso horário e licença vêm dos
   seus padrões (veja "O seu usuário", abaixo) ou das opções que você der;
   o que ainda faltar, ele pergunta.
2. Faz o primeiro commit, na `main`.
3. Cria o repositório `sua-conta/meu-projeto` no GitHub, privado, e envia
   a `main` para ele.
4. Liga a revisão automática (`scripts/setup-github.sh`, abaixo): oferece
   rodar o `claude setup-token`, pede para você colar o token sem
   mostrá-lo na tela, salva como o segredo `CLAUDE_CODE_OAUTH_TOKEN` e
   protege a `main`.
5. Oferece instalar as regras e as skills do kit para o seu usuário, se
   ainda não estiverem lá.

Depois abra o agente na pasta e diga o que você quer construir:

```sh
cd meu-projeto && claude
```

Ele vê que o projeto não foi iniciado e o planeja com você (a skill
`start-project`).

Opções úteis: `--public` para um repositório público, `--github-owner ORG`
para criá-lo numa organização, `--no-github` para ficar só no seu
computador, `--summary "uma ferramenta que ..."`, `--tools claude,codex`
para os agentes que você usa, `--copy` se os links derem problema. `install.sh --help`
lista todas.

Se algo falhar no meio (sem rede, um erro no token), corrija e rode o
mesmo comando de novo: os passos já feitos são mantidos.

## Um projeto em andamento

Na pasta do projeto (um repositório git), ou indicando a pasta:

```sh
install.sh existing            # ou: install.sh existing caminho/do/projeto
```

Ele nunca sobrescreve um arquivo seu:

| O seu arquivo | O que o instalador faz |
| --- | --- |
| Não existe | Acrescenta o do kit |
| `AGENTS.md` | Acrescenta as regras do kit no fim, entre linhas marcadoras |
| `CLAUDE.md` | Acrescenta a importação do `AGENTS.md`, se não tiver |
| `.claude/settings.json` | Junta as permissões e os hooks do kit aos seus |
| `.gitignore`, `.github/CODEOWNERS` | Acrescenta as linhas que faltam |
| Um workflow com o nome de um do kit (`checks.yml`) | Acrescenta o do kit como `kit-checks.yml` |
| Qualquer outro arquivo (`README.md`, `docs/README.md`...) | Mantém o seu e o lista |

Com a árvore de trabalho limpa, o kit vai para um branch novo,
`agent-kit`; nada é commitado. Se o repositório está no GitHub, a parte do
GitHub roda também; ela pergunta antes de proteger a `main`, porque daí
em diante a `main` só muda por pull request.

Depois abra o agente no projeto e diga "adote o kit neste projeto". Ele lê
o seu código e o README como briefing, escreve os objetivos, as decisões,
o inventário e o roteiro a partir do que existe, junta os arquivos que o
instalador manteve com os do kit, faz as verificações passarem no seu
código e abre um pull request.

## Só a parte do GitHub

Para um projeto feito de outro jeito, ou para trocar o token quando ele
vencer (cerca de um ano):

```sh
install.sh github                       # no projeto: o que estiver faltando
scripts/setup-github.sh --replace-token # num projeto do kit: um token novo
```

O que ele configura no repositório:

- O segredo `CLAUDE_CODE_OAUTH_TOKEN`. O token vai do seu terminal para o
  `gh secret set` por um pipe: nunca para um arquivo, nunca numa linha de
  comando. Um segredo que já existe é mantido, a não ser com
  `--replace-token`.
- O ruleset `agent-kit: main` no branch padrão: as mudanças chegam por
  pull request; as verificações `Review` e as do `checks.yml` precisam
  passar; uma mudança em `.github/` ou no script da revisão espera pelo
  dono (Code Owners). Nenhuma aprovação mínima é exigida, porque uma conta
  pessoal não consegue aprovar o próprio pull request; quando uma mudança
  espera por você como Code Owner, você faz o merge com o bypass, que só
  funciona por pull request, nunca com um push direto.

O GitHub Free não tem rulesets para repositórios privados. Nesse caso o
script avisa e segue: a revisão continua comentando em cada pull request,
mas não consegue impedir um merge. Torne o repositório público, ou passe
para o GitHub Pro, e rode de novo.

## O seu usuário

```sh
install.sh user
```

Acrescenta as regras de trabalho do kit em `~/.claude/CLAUDE.md`,
`~/.codex/AGENTS.md` e `~/.pi/agent/AGENTS.md` (entre linhas marcadoras),
copia as skills, e pergunta uma única vez os seus padrões para projetos
novos: nome, idiomas, fuso horário, licença e conta do GitHub. O
`install.sh new` e o `existing` usam esses padrões, e assim perguntam
menos. Ele nunca sobrescreve um arquivo seu; edite os padrões onde ele os
gravou. `install.sh user --help` lista as opções.

## Atualizar

```sh
install.sh update                       # num projeto, ou: install.sh update caminho/do/projeto
```

1. Atualiza a sua cópia do kit (`git pull` em `~/.agent-kit`, ou na sua
   cópia).
2. Se o kit está instalado para o seu usuário, troca as regras e as
   skills dele pela versão nova, mantendo os seus padrões.
3. Num projeto, compara a versão do kit dele (`docs/kit.md`) com a mais
   nova e diz o que fazer.

O projeto em si é atualizado pelo agente dele: diga "atualize o kit". Ele
lê o `HISTORY.md` do kit a partir da versão do projeto, traz cada mudança
sem perder o que foi ajustado ao projeto (a skill `update-from-template`),
roda as verificações e abre um pull request.

## Começar pelo "Use this template" do GitHub

Se você prefere o botão, crie uma vez um repositório só com a pasta do
modelo:

```sh
cp -R agent-kit/project-template meu-modelo && cd meu-modelo
git init -b main && git add -A && git commit -m "Agent project template"
gh repo create meu-modelo --private --source . --push
```

e marque "Template repository" nas configurações dele. Um projeto criado
pelo botão é preenchido pelo agente quando você o abre pela primeira vez;
rode `scripts/setup-github.sh` nele para ligar a revisão. Não use o botão
no próprio repositório do kit: isso copia o kit inteiro.
