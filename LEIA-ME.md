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
| `project-template/` | Um repositório para começar projetos novos: `AGENTS.md` (a fonte única das regras), `CLAUDE.md` apontando para ele, `docs/` (objetivos, decisões, arquitetura, roteiro, verificação, inventário, pendências, log do projeto, estilo de escrita, painel), `HISTORY.md`, `CONTRIBUTING.md`, oito skills, scripts, modelos de PR e de issue, CI, `REUSE.toml` e `init-project.sh` | Cada repositório novo |
| `user-level/` | As regras de trabalho para o seu usuário (todos os projetos) e `install-user.sh`, que as instala com as skills no Claude Code, no Codex e no Pi sem sobrescrever seus arquivos | Seu computador, uma vez |
| `desktop/` | Texto para colar nas instruções de um Projeto do Claude ou do ChatGPT, e cada skill em .zip para enviar ao Claude | Apps de conversa, sem repositório |

## As regras, em resumo

- **Priorizar antes de executar**, e dizer a ordem.
- **Consultar antes de conflitar** com uma decisão do dono; nunca escolher
  um lado em silêncio.
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
- **Testes**: os da mudança durante o trabalho, todos uma vez no fim;
  nunca afrouxados para passar.
- **Comentários e escrita**: um comentário de módulo por arquivo, um de
  documentação por item público, o porquê do que não é óbvio; palavras
  simples, resultado primeiro.

## As skills

| Skill | Quando |
| --- | --- |
| `start-project` | Projeto novo a partir de um briefing: objetivos, decisões, inventário, roteiro, verificação |
| `plan-task-set` | Antes de qualquer trabalho: achar no plano, ver as decisões, priorizar |
| `defer-work` | Algo ficou sem fazer ou mudou de fase |
| `record-decision` | O dono decidiu, ou uma tarefa conflita com uma decisão |
| `validate-against-reference` | Antes de dar um comportamento por pronto |
| `close-task-set` | Fim de um PR, fase ou conversa: registros e relatório |
| `close-phase` | Fim de fase: pendências zeradas, verificações, previsão |
| `report-to-owner` | Qualquer relatório ou descrição de PR |

## Instalação

### Projeto novo (qualquer agente)

```sh
cp -R project-template meu-projeto     # ou suba no GitHub e marque como "Template repository"
cd meu-projeto && git init
./init-project.sh                      # pergunta nome, dono, idiomas, fuso horário e licença
```

O `init-project.sh` preenche todos os `{{MARCADORES}}` e prepara cada
agente (`--tools all` por padrão, ou uma lista como `--tools claude,codex`):

| Agente | O que ele lê | O que o script faz |
| --- | --- | --- |
| Claude Code | `CLAUDE.md` (que importa o `AGENTS.md`) e `.claude/skills/` | Mantém |
| Codex CLI (e o Codex no ChatGPT) | `AGENTS.md`; skills em `.agents/skills/` | Liga `.agents/skills` a `.claude/skills` |
| Pi | `AGENTS.md`; skills em `.pi/skills/` | Liga `.pi/skills` a `.claude/skills` |
| Gemini CLI | `GEMINI.md` por padrão | Cria `.gemini/settings.json` para ele ler o `AGENTS.md` |
| GitHub Copilot | `.github/copilot-instructions.md` e `AGENTS.md` | Cria um apontador |
| Cursor | `AGENTS.md` e `.cursor/rules/` | Cria uma regra apontando para ele |
| Outros (Aider, Zed, Amp, Jules...) | Em geral `AGENTS.md`; se não, aponte para ele (Aider: `--read AGENTS.md`) | Nada |

No Windows, use `--copy` em vez de links. Depois peça ao agente para usar a
skill `start-project` com o seu briefing, ou preencha o `docs/` à mão. As
skills são Markdown simples: um agente sem suporte a skills pode receber
"siga `.claude/skills/close-task-set/SKILL.md`".

### Para o seu usuário, em todos os projetos

```sh
user-level/install-user.sh             # ou --tools claude,codex,pi ; --dry-run para ver antes
```

Ele acrescenta as regras de trabalho entre duas linhas marcadoras em
`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md` e `~/.pi/agent/AGENTS.md` (rodar
de novo substitui o bloco) e copia as skills para `~/.claude/skills`,
`~/.codex/skills` e `~/.pi/agent/skills`, sem mexer nas que você já tem.

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
seguir, pendências, previsão, histórico e uma lista com filtros. Python
3.11, sem dependências; em inglês ou português (`docs/dashboard/config.toml`).
`--out` grava uma página, `--artifact` um fragmento para uma página
hospedada como um Artifact do claude.ai, e `--record` guarda os números e
as mudanças do dia. `.github/workflows/dashboard.yml` publica no GitHub Pages.

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
