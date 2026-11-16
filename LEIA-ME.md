# Kit de projeto para agentes

Um modelo de projeto e um conjunto de regras para desenvolver software com
agentes de código, tirados de um projeto real em que o dono decide e aprova
e um modelo de IA planeja, escreve o código, os testes e a documentação.
Funciona com Claude Code, Claude desktop, Codex CLI, ChatGPT desktop, Pi e
outros agentes que leem `AGENTS.md`.

O conteúdo do modelo está em inglês. Os relatórios ao dono e o painel
saem no idioma que você escolher ao iniciar o projeto (o painel tem inglês
e português do Brasil).

## O que vem no pacote

| Pasta | O que é | Para quê |
| --- | --- | --- |
| `project-template/` | Um repositório para começar projetos novos: `AGENTS.md` (a fonte única das regras), `CLAUDE.md` apontando para ele, `docs/` (objetivos, decisões, arquitetura, roteiro, verificação, padrões de engenharia, especificações, inventário, pendências, log do projeto, lições, estilo de escrita, painel), `HISTORY.md`, `CONTRIBUTING.md`, onze skills, um hook de início de sessão, scripts, modelos de PR e de issue, CI, `REUSE.toml` e `init-project.sh` | Cada repositório novo |
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
- **Suas correções viram proteções.** Quando você precisa corrigir o
  agente, ele registra a lição, cria o que a evita e propõe levar ao
  modelo quando serve para qualquer projeto.

## As regras, em resumo

- **Começar pelo estado** (`scripts/status.py`); **as skills se aplicam
  sozinhas**.
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
- **Trabalhar enxuto**: ler só o que a tarefa toca; tokens e a atenção do
  dono fazem parte do custo.
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
| `update-from-template` | O modelo mudou, ou uma lição merece ir para ele |

Skills de fora não vêm no pacote. O `docs/kit.md` do modelo diz quando
vale a pena adicionar uma (por exemplo a `webapp-testing`, do
[anthropics/skills](https://github.com/anthropics/skills), num projeto com
interface web), como a licença é conferida e registrada, e que ela é lida
inteira antes, como código de um desconhecido. A `start-project` adiciona
só o que a tecnologia do projeto pede.

## Instalação

### Projeto novo (qualquer agente)

```sh
cp -R project-template meu-projeto     # ou suba no GitHub e marque como "Template repository"
cd meu-projeto && git init
```

Depois abra o agente na pasta e diga o que você quer construir. Ele vê
que o projeto não foi iniciado, roda o `init-project.sh` com o que já
sabe (o seu briefing, os seus padrões, o usuário e o remoto do git),
pergunta só o que trava o plano, escreve o plano, ajusta o kit à sua
tecnologia e relata o que assumiu. Se preferir preencher os marcadores
você mesmo antes, rode `./init-project.sh`, que pergunta nome, dono,
idiomas, fuso horário e licença.

O `init-project.sh` preenche todos os `{{MARCADORES}}` e prepara cada
agente (`--tools all` por padrão, ou uma lista como `--tools claude,codex`):

| Agente | O que ele lê | O que o script faz |
| --- | --- | --- |
| Claude Code | `CLAUDE.md` (que importa o `AGENTS.md`), `.claude/skills/` e `.claude/settings.json` (o hook de início de sessão e os scripts de verificação liberados) | Mantém |
| Codex CLI (e o Codex no ChatGPT) | `AGENTS.md`; skills em `.agents/skills/` | Liga `.agents/skills` a `.claude/skills` |
| Pi | `AGENTS.md`; skills em `.pi/skills/` | Liga `.pi/skills` a `.claude/skills` |
| Gemini CLI | `GEMINI.md` por padrão | Cria `.gemini/settings.json` para ele ler o `AGENTS.md` |
| GitHub Copilot | `.github/copilot-instructions.md` e `AGENTS.md` | Cria um apontador |
| Cursor | `AGENTS.md` e `.cursor/rules/` | Cria uma regra apontando para ele |
| Outros (Aider, Zed, Amp, Jules...) | Em geral `AGENTS.md`; se não, aponte para ele (Aider: `--read AGENTS.md`) | Nada |

No Windows, use `--copy` em vez de links. As skills são Markdown simples,
e o `AGENTS.md` dá o caminho e o momento de cada uma, então um agente sem
suporte a skills também as segue. Só o Claude Code roda o relatório de
estado sozinho; os outros agentes rodam `python3 scripts/status.py`
primeiro, como diz a regra 1.

### Para o seu usuário, em todos os projetos

```sh
user-level/install-user.sh             # ou --tools claude,codex,pi ; --dry-run para ver antes
```

Ele acrescenta as regras de trabalho entre duas linhas marcadoras em
`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` e `~/.pi/agent/AGENTS.md` (rodar
de novo substitui o bloco) e copia as skills para `~/.claude/skills`,
`~/.codex/skills` e `~/.pi/agent/skills`, sem mexer nas que você já tem
(`--replace-skills` troca as do kit pela versão nova). Também pergunta,
uma única vez, os seus padrões para projetos novos (seu nome, os idiomas,
o fuso horário, a licença, a conta do GitHub) e os grava abaixo das
regras, para que o agente não pergunte de novo a cada projeto; edite ali
quando quiser.

### Claude desktop

1. Configurações > Capacidades > Skills: envie cada .zip de `desktop/claude-skills/`.
2. Num Projeto, cole `desktop/project-instructions.md` (abaixo da linha)
   nas instruções e adicione como arquivos as páginas de `docs` que usar.
3. A aba Claude Code do app trabalha num repositório: use o modelo como
   acima.

### ChatGPT desktop

1. Num Projeto, cole `desktop/project-instructions.md` nas instruções e
   adicione as páginas de `docs` como arquivos. Os Projetos do ChatGPT não
   aceitam skills: peça para seguir uma skill pelo nome e anexe o `SKILL.md`.
2. O Codex (no ChatGPT ou no terminal) lê o `AGENTS.md` direto do repositório.

## O painel

`scripts/dashboard.py` monta uma página HTML a partir do repositório: itens
prontos por frente e por fase, o que acabou de ser feito, o que vem a
seguir, pendências, decisões aguardando o dono, previsão, histórico e uma
lista com filtros. Python
3.11, sem dependências; em inglês ou português (`docs/dashboard/config.toml`).
`--out` grava uma página, `--artifact` um fragmento para uma página
hospedada como um Artifact do claude.ai, e `--record` guarda os números e
as mudanças do dia. `.github/workflows/dashboard.yml` publica no GitHub Pages.

## Alterar o kit

O `AGENTS.md` da raiz tem as regras para trabalhar no kit, e o
`HISTORY.md` as versões. Depois de uma mudança, `tools/build-kit.py`
refaz os .zip das skills e `tools/test-kit.sh` cria um projeto a partir
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
