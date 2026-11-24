# Kit de projeto para agentes

Um modelo de projeto e um conjunto de regras para desenvolver software com
agentes de código, tirados de um projeto real em que o dono decide e aprova
e um modelo de IA planeja, escreve o código, os testes e a documentação.
Funciona com Claude Code, Claude desktop, Codex CLI, ChatGPT desktop, Pi e
outros agentes que leem `AGENTS.md`.

O conteúdo do modelo está em inglês. Os relatórios ao dono e o painel
saem no idioma que você escolher ao iniciar o projeto (o painel tem inglês
e português do Brasil).

## Começo rápido

```sh
git clone https://github.com/brahm/project-template agent-kit
agent-kit/user-level/install-user.sh          # uma vez por computador: regras, skills, seus padrões
cp -R agent-kit/project-template meu-projeto  # uma vez por projeto
cd meu-projeto && git init
claude                                         # ou codex, pi, gemini...
```

Depois diga ao agente, com as suas palavras, o que você quer construir.
Ele faz o resto e relata o que assumiu.

## O que vem no pacote

| Pasta | O que é | Para quê |
| --- | --- | --- |
| `project-template/` | Um repositório para começar projetos novos: `AGENTS.md` (a fonte única das regras), `CLAUDE.md` apontando para ele, `docs/` (objetivos, decisões, arquitetura, roteiro, verificação, padrões de engenharia, especificações, inventário, pendências, log do projeto, lições, estilo de escrita, painel e o Second Brain), `HISTORY.md`, `CONTRIBUTING.md`, doze skills, hooks de sessão, scripts, modelos de PR e de issue, CI com revisão automática de cada pull request, `REUSE.toml` e `init-project.sh` | Cada repositório novo |
| `user-level/` | As regras de trabalho para o seu usuário (todos os projetos), os seus padrões para projetos novos e `install-user.sh`, que os instala com as skills no Claude Code, no Codex e no Pi sem sobrescrever seus arquivos | Seu computador, uma vez |
| `desktop/` | Texto para colar nas instruções de um Projeto do Claude ou do ChatGPT, e cada skill em .zip para enviar ao Claude | Apps de conversa, sem repositório |
| `tools/`, `AGENTS.md`, `HISTORY.md` | Para trabalhar no próprio kit: as regras, o script que refaz os .zip, o teste que cria um projeto a partir do modelo e as versões do kit | Quem altera o kit |

## Como ele funciona

O kit não é um harness. Ele não diz ao agente como planejar nem como
programar: um bom modelo faz isso bem sozinho, e um método imposto tira
dele justamente o julgamento. O kit diz o que não pode ser esquecido
quando uma pessoa trabalha com um agente, e garante que não seja: com uma
verificação automática onde ela resolve, com uma skill curta no momento
certo, e com uma regra só quando nada mais serve.

- **Você nunca invoca uma skill.** O `AGENTS.md` lista o momento de cada
  uma, e o agente abre a skill quando o momento chega. Um repositório
  recém-criado a partir do modelo diz "não iniciado", e o agente planeja
  o projeto a partir da sua primeira mensagem.
- **O agente decide o que você deixou em aberto, e avisa.** O objetivo, o
  escopo e o que não tem volta são seus. O que você não especificou, o
  agente resolve, registra como decisão assumida e lista no relatório e
  no painel, para você confirmar ou substituir.
- **A sessão começa pelo estado, não por leitura.** O `scripts/status.py`
  mostra em umas vinte linhas a fase, o que vem a seguir, as pendências e
  o que espera por você; o Claude Code roda sozinho.
- **O que vive sendo esquecido vira verificação.** Link quebrado, id que
  não existe, painel sem registro, mudança sem linha no HISTORY: o
  `scripts/check-all.sh` e o CI falham.
- **Todo pull request é revisado antes do merge.** Um modelo que não
  escreveu a mudança lê o código em busca de bugs, problemas de segurança
  e otimizações, e comenta no pull request o que precisa ser corrigido,
  ou que tudo passou. Um apontamento bloqueante faz a verificação falhar,
  e o merge não acontece por engano. Precisa da sua chave de API como
  segredo do repositório.
- **O que o projeto aprende fica guardado e é achado em segundos.** O
  Second Brain (`docs/brain/`) tem uma nota em Markdown por assunto: como
  uma parte funciona, os fatos do domínio, as manias de um serviço, a
  causa de um problema. O agente escreve enquanto aprende, um hook
  lembra, e `scripts/brain.py find PALAVRAS` busca nas notas e em todos
  os registros de uma vez. Decisões, datas e mudanças ficam nos seus
  logs; as notas citam o id em vez de copiar.
- **Suas correções viram proteções.** Quando você precisa corrigir o
  agente, ele registra a lição, cria o que a evita e propõe levar ao
  modelo quando serve para qualquer projeto.

## As regras, em resumo

- **Começar pelo estado** (`scripts/status.py`) **e pelo que já se sabe**
  (`scripts/brain.py find`); **as skills se aplicam sozinhas**.
- **Anotar o que foi aprendido** na nota do assunto no Second Brain,
  citando os registros em vez de copiá-los.
- **Quem decide**: o dono, o objetivo e o escopo; o agente, com registro,
  o que ficou em aberto; o agente, o como.
- **Priorizar antes de executar**, e dizer a ordem.
- **Consultar antes de conflitar** com uma decisão do dono; nunca escolher
  um lado em silêncio.
- **Especificar antes de construir**, na medida do trabalho: critérios de
  aceitação que um teste confere, e o que o dono costuma deixar de fora.
- **Padrões de engenharia** (`docs/engineering.md`): o desenho mais
  simples, lógica separada de entrada e saída, falhas tratadas, nenhum
  segredo no repositório, um motivo para cada dependência.
- **Validar contra uma referência** e registrar o resultado.
- **Nada some em silêncio**: o que fica sem fazer ou muda de fase vai para
  o registro de pendências (`docs/backlog/deferred.tsv`), e o relatório diz
  qual item e para qual fase foi.
- **Uma fase só fecha com as pendências zeradas** (`scripts/check-backlog.py --phase`).
- **Ao fim de cada conjunto de atividades**, atualizar o inventário, o
  painel (`scripts/dashboard.py --record`), o log do projeto (o quê, por
  quê, desdobramentos, consequências) e o `HISTORY.md` (uma linha por
  mudança, no estilo do HISTORY do Textpattern).
- **As decisões são do dono**, registradas com id, nunca apagadas.
- **Testes**: os da mudança durante o trabalho, todos uma vez no fim; um
  bug se corrige com um teste que falha primeiro; nunca afrouxados para
  passar.
- **Trabalhar enxuto, na tarefa**: ler só o que a tarefa toca; tokens e a
  atenção do dono fazem parte do custo. Um `TODO` encontrado no caminho é
  informação, não tarefa.
- **Nenhuma nota velha**: todo `TODO`, `FIXME`, `XXX` ou `HACK` cita uma
  pendência aberta, `TODO(B-012)`, e sai quando ela fecha
  (`scripts/check-backlog.py`).
- **Uma lição vira proteção**: uma verificação antes de uma regra, uma
  regra mais precisa antes de uma nova.
- **Comentários e escrita**: um comentário de módulo por arquivo, um de
  documentação por item público, o porquê do que não é óbvio; palavras
  simples, resultado primeiro.

## As skills

O agente aplica cada uma no seu momento; você não precisa chamá-las.

| Skill | Quando |
| --- | --- |
| `start-project` | Repositório recém-criado a partir do modelo, ou briefing de projeto novo: marcadores, objetivos, decisões, inventário, roteiro, verificação, e as regras, skills e verificações ajustadas à tecnologia |
| `plan-task-set` | Antes de qualquer trabalho: achar no plano, ver as decisões, achar o que não foi dito, priorizar |
| `specify-work` | Item cujo comportamento nenhuma referência define: critérios de aceitação, lacunas, suposições |
| `record-decision` | O dono decidiu, uma tarefa conflita com uma decisão, ou o agente resolveu o que ficou em aberto |
| `defer-work` | Algo ficou sem fazer ou mudou de fase |
| `validate-against-reference` | Antes de dar um comportamento por pronto |
| `close-task-set` | Fim de um PR, fase ou conversa: revisão, registros, verificações e relatório |
| `close-phase` | Fim de fase: pendências zeradas, verificações, previsão, decisões assumidas, lições |
| `report-to-owner` | Qualquer relatório ou descrição de PR |
| `capture-lesson` | O dono corrigiu o agente, ou um erro se repetiu: a lição e a proteção |
| `update-brain` | O agente aprendeu algo que a próxima sessão vai precisar: a nota do assunto no Second Brain |
| `update-from-template` | O modelo mudou, ou uma lição merece ir para ele |

Skills de fora não vêm no pacote. O `docs/kit.md` do modelo diz quando
vale a pena adicionar uma (por exemplo a `webapp-testing`, do
[anthropics/skills](https://github.com/anthropics/skills), num projeto com
interface web), como a licença é conferida e registrada, e que ela é lida
inteira antes, como código de um desconhecido. A `start-project` adiciona
só o que a tecnologia do projeto pede.

## Instalação

### O que é preciso

- `bash`, `git` e Python 3.11 ou mais novo. Os scripts não usam mais nada.
- Opcional: o [`reuse`](https://reuse.software) para a verificação de
  licenças (`pipx install reuse`) e o `gh`, a linha de comando do GitHub,
  para a lista de pull requests no painel. Sem eles, esses dois passos
  são pulados.

### 1. Baixar o kit

```sh
git clone https://github.com/brahm/project-template agent-kit
```

Para começar projetos pelo botão "Use this template" do GitHub em vez de
copiar uma pasta, crie uma vez um repositório só com a pasta do modelo:

```sh
cp -R agent-kit/project-template meu-modelo && cd meu-modelo
git init -b main && git add -A && git commit -m "Agent project template"
gh repo create meu-modelo --private --source . --push
```

Depois marque "Template repository" nas configurações dele no GitHub. Não
use "Use this template" no repositório do kit: isso copia o kit inteiro, e
não o modelo de projeto.

### 2. Instalar para o seu usuário (uma vez por computador)

```sh
agent-kit/user-level/install-user.sh          # --dry-run para ver antes; --tools claude,codex para escolher
```

Ele acrescenta as regras de trabalho entre duas linhas marcadoras em
`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` e `~/.pi/agent/AGENTS.md`, copia
as skills para `~/.claude/skills`, `~/.codex/skills` e `~/.pi/agent/skills`,
e pergunta uma única vez os seus padrões para projetos novos (seu nome, os
idiomas, o fuso horário, a licença, a conta do GitHub), que grava abaixo
das regras para que nenhum projeto pergunte de novo. Edite ali quando
quiser. Ele nunca sobrescreve um arquivo seu: rodar de novo substitui só o
bloco das regras e mantém os seus padrões e as skills que você já tem.
Quando o kit mudar, `--replace-skills` troca as skills dele pela versão
nova. Todas as opções: `install-user.sh --help`.

Este passo é opcional. Ele leva as regras e as skills a projetos que não
vieram do modelo, e poupa ao agente uma ou duas perguntas nos que vieram.

### 3. Começar um projeto

```sh
cp -R agent-kit/project-template meu-projeto  # ou "Use this template" no seu repositório de modelo
cd meu-projeto && git init                    # sem git init depois de "Use this template"
```

Abra o agente na pasta e diga o que você quer construir. Ele vê que o
projeto não foi iniciado, roda o `init-project.sh` com o que já sabe (o seu
briefing, os seus padrões, o usuário e o remoto do git), pergunta só o que
trava o plano, escreve os objetivos, as decisões, o inventário e o
roteiro, ajusta as verificações e as skills à sua tecnologia e relata o
que assumiu. Você nunca precisa citar uma skill.

Para preencher os marcadores à mão antes, rode `./init-project.sh`: ele
pergunta nome, dono, idiomas, fuso horário e licença
(`./init-project.sh --help` lista as opções). Ele também prepara cada
agente (`--tools all` por padrão, ou uma lista como `--tools claude,codex`):

| Agente | O que ele lê | O que o script faz |
| --- | --- | --- |
| Claude Code | `CLAUDE.md` (que importa o `AGENTS.md`), `.claude/skills/` e `.claude/settings.json` (os hooks que mostram o estado no início da sessão e lembram do Second Brain quando o agente para, e os scripts de verificação liberados) | Mantém |
| Codex CLI (e o Codex no ChatGPT) | `AGENTS.md`; skills em `.agents/skills/` | Liga `.agents/skills` a `.claude/skills` |
| Pi | `AGENTS.md`; skills em `.pi/skills/` | Liga `.pi/skills` a `.claude/skills` |
| Gemini CLI | `GEMINI.md` por padrão | Cria `.gemini/settings.json` para ele ler o `AGENTS.md` |
| GitHub Copilot | `.github/copilot-instructions.md` e `AGENTS.md` | Cria um apontador |
| Cursor | `AGENTS.md` e `.cursor/rules/` | Cria uma regra apontando para ele |
| Outros (Aider, Zed, Amp, Jules...) | Em geral `AGENTS.md`; se não, aponte para ele (Aider: `--read AGENTS.md`) | Nada |

No Windows, use `--copy` em vez de links. O Claude Code pergunta uma vez
se você confia na pasta; aceite, senão os scripts liberados do projeto
continuam pedindo permissão. Só o Claude Code roda o relatório de estado
sozinho; os outros agentes rodam `python3 scripts/status.py` primeiro,
como diz a regra 1 do `AGENTS.md`.

### Claude desktop e ChatGPT desktop (sem repositório)

1. Claude: Configurações > Capacidades > Skills, e envie cada .zip de
   `desktop/claude-skills/`. Os Projetos do ChatGPT não aceitam skills:
   peça para seguir uma skill pelo nome e anexe o `SKILL.md` dela.
2. Num Projeto, cole `desktop/project-instructions.md` (abaixo da linha)
   nas instruções e adicione como arquivos as páginas de `docs` que usar.
3. A aba Claude Code do Claude desktop, e o Codex, trabalham num
   repositório: use o modelo como acima.

## Uso

Você conversa com o agente como faria com um colega. O kit garante que o
que uma pessoa sozinha costuma esquecer não seja esquecido.

| Você | O agente |
| --- | --- |
| Diz o que quer, com as suas palavras | Acha no plano, prioriza, escreve critérios de aceitação onde nada define o comportamento, constrói, testa e mantém os registros |
| Lê o relatório | Começa pelo resultado, depois o que conferiu, as decisões que assumiu, e o que ficou sem fazer e para qual fase foi |
| Confirma ou troca uma decisão assumida ("a D-007 está ok", "use Postgres, não SQLite") | Registra, e muda o plano, a especificação e o código que dependiam dela |
| Corrige o agente | Corrige o erro, registra a lição em `docs/lessons.md` e cria a verificação ou a regra que o evita |
| Diz que uma fase acabou, ou deixa ela terminar | Zera as pendências da fase, corrige a previsão e pergunta sobre as decisões ainda assumidas |
| Diz que o modelo mudou | Traz as regras, skills e verificações novas para o projeto sem perder o que foi ajustado nele |

O que você vai olhar, além dos relatórios:

- **O painel**: `python3 scripts/dashboard.py --out painel.html` e abra o
  arquivo. Itens prontos por frente e por fase, o que acabou de ser feito,
  o que vem a seguir, as pendências, as decisões aguardando você, a
  previsão, o histórico e uma lista com filtros, em inglês ou português
  (`docs/dashboard/config.toml`). O `.github/workflows/dashboard.yml`
  publica no GitHub Pages; `--artifact` gera um fragmento para uma página
  hospedada, como um Artifact do claude.ai.
- **O estado em poucas linhas**: `python3 scripts/status.py`, o mesmo
  resumo que o agente lê ao começar uma sessão.
- **Todas as verificações**: `scripts/check-all.sh`, as mesmas do CI. Falha
  com teste quebrado, link quebrado, id que não existe, painel sem
  registro, mudança sem linha no HISTORY ou sem entrada no log do projeto,
  e arquivo sem licença.
- **A revisão automática**: um comentário em cada pull request,
  atualizado a cada push: aprovada, aprovada com pontos para ler, ou
  bloqueada, com o arquivo, a linha e a correção de cada apontamento.
  Para ligar, adicione o segredo `ANTHROPIC_API_KEY` ao repositório
  (Settings > Secrets and variables > Actions), torne obrigatória a
  verificação `Review` na `main` e ligue "Require review from Code
  Owners", para que um pull request não consiga desligar a revisão para
  si mesmo (`docs/kit.md` do modelo, "The automatic review"). Sem o
  segredo, a revisão é pulada com um aviso.
- **Os registros**: `docs/decisions.md`, `docs/backlog/deferred.tsv`,
  `docs/project-log.md`, `docs/lessons.md` e `HISTORY.md`.
- **O que o projeto sabe**: `python3 scripts/brain.py find PALAVRAS`, ou
  o índice de notas em `docs/brain/README.md`. As notas são Markdown
  puro, então também abrem como cofre no Obsidian ou em qualquer editor.

Para manter um projeto em dia com o kit, atualize o kit (`git -C agent-kit
pull`) e diga ao agente, no projeto, que o modelo mudou. Para os arquivos
do seu usuário, rode `install-user.sh --replace-skills` de novo.

## Alterar o kit

O `AGENTS.md` da raiz tem as regras para trabalhar no kit, e o
`HISTORY.md` as versões. Depois de uma mudança, `tools/build-kit.py`
refaz os .zip das skills e a cópia da revisão automática do próprio kit
(os pull requests do kit são revisados como os de um projeto, depois que o
secret `ANTHROPIC_API_KEY` for cadastrado no repositório do kit), e `tools/test-kit.sh` cria um projeto a partir
do modelo numa pasta temporária, roda as verificações e testa cada
proteção contra o erro que ela existe para pegar. O CI roda o mesmo
teste.

## Confira os caminhos de cada ferramenta

Os agentes mudam com frequência onde leem instruções e skills. O pacote foi
conferido em 16/11/2026; se um agente não pegar o seu arquivo, veja onde
ele lê hoje e mude o link.

## De onde veio, e o que ficou de fora

As regras, os documentos, o registro de pendências, o painel e o script
vêm do repositório do Desk, tornados genéricos. Ficou de fora o que é só
daquele projeto: objetivos e decisões, inventários e matrizes de paridade,
arquitetura e regras de camadas, catálogo de extensões ODF, testes de
interface, fuzzing, Flatpak, site e mockups. Aparecem aqui só como a regra
geral que seguiam ("padrões primeiro, toda extensão documentada";
"respeitar as fronteiras da arquitetura"). O Desk não tinha um guia de tom
de voz separado: o `docs/writing-style.md` foi escrito a partir do estilo
dos documentos dele e das suas regras de relatório. Também não tinha
modelos de PR e de issue: os daqui seguem o CONTRIBUTING.md dele.

## Licença

O kit está sob a [licença MIT](LICENSE). Um projeto criado a partir do
modelo não fica preso a ela: o `init-project.sh` pergunta a licença do
próprio projeto e a registra no `REUSE.toml` e em `LICENSES/` do projeto.
