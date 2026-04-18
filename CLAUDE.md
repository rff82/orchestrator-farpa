# CLAUDE.md — rff82/orchestrator-farpa
> Arquivo de contexto do Orquestrador Cloud · v1.1 · 2026-04-13
> Lido por Claude no início de cada step de workflow neste repositório.
> Submisso ao Orquestrador Masterizado: Projetos/CLAUDE.md

---

## O QUE ESTE REPO FAZ

Este é o **orquestrador central** do ecossistema farpa.ai. Roda inteiramente em
GitHub Actions — zero instalação local necessária. Gerencia deploy, sync, auditoria
e provisionamento de todos os produtos via quatro workflows:

| Workflow | Arquivo | Função |
|---|---|---|
| Audit | `audit.yml` | Health check diário → GitHub Issue (Gemini Search Grounding) |
| Sync | `sync.yml` | Valida/atualiza todos os repos rff82/* |
| Deploy | `deploy.yml` | Deploy Pages + Workers no Cloudflare |
| Provision | `provision.yml` | Cria novo produto end-to-end (Stitch + Imagen 3) |
| Design | `design.yml` | Gera telas via Stitch MCP (execução local) |

Claude age como **agente de decisão** em cada workflow — valida código, gera relatórios,
cria CLAUDE.md, detecta anomalias — usando `anthropic/claude-code-action`.

---

## ECOSSISTEMA DE PRODUTOS

| Produto | Repo | Subdomínio | CF Pages | Worker | D1 | KV |
|---|---|---|---|---|---|---|
| farpa.ai | rff82/AI | farpa.ai | farpa-main | farpa-proxy, api-leads | farpa-db | — |
| farpa Labs | rff82/labs-farpa-ai | labs.farpa.ai | labs-farpa-ai | — | — | — |
| farpa Health | rff82/health-farpa-ai | health.farpa.ai | health-farpa-ai | health-worker | health-farpa-ai-db | HEALTH_CACHE |
| farpa Fintech | rff82/fintech-farpa.ai | fintech.farpa.ai | fintech-farpa-ai | fintech-worker | fintech-farpa-ai-db | FINTECH_CACHE |
| farpa Library | rff82/libery-farpa-ai | library.farpa.ai | libery-farpa-ai | libery-worker | libery-farpa-ai-db | — |
| farpa Docs | rff82/docs-farpa-ai | docs.farpa.ai | docs-farpa-ai | — | — | — |

---

## LIMITES FREE TIER CLOUDFLARE (aplicar em toda decisão)

| Recurso | Limite Diário | Estratégia |
|---|---|---|
| Workers Requests | 100.000/dia | Nunca adicionar lógica que aumente volume de chamadas |
| D1 Reads | 5.000.000/dia | Sempre cache-first via KV |
| D1 Writes | 100.000/dia | Batch writes quando possível |
| KV Reads | 100.000/dia | Usar para dados frequentes e de mudança lenta |
| Pages Builds | Ilimitado | Atenção a deploys concorrentes conflitantes |

---

## REGRAS INEGOCIÁVEIS (nunca sobrescrever, aplicar a todos os produtos)

1. **Alto contraste é toggle secundário, sempre disponível no header** (`#btn-alto-contraste` → `.theme-alto-contraste`). NÃO é o tema padrão. Rodrigo tem baixa visão — precisa acessar em 1 clique. Tema padrão do produto segue tendência da categoria (regra 14).
2. **WCAG AA mínimo** — verificar contraste antes de qualquer sugestão de código
3. **API keys nunca no cliente** — sempre `wrangler secret put`, nunca em JS/HTML
4. **Cores nunca hardcoded** — sempre `var(--token-name)`
5. **Tipografia imutável** — Plus Jakarta Sans (UI/display) + JetBrains Mono (dados/código)
6. **Nunca modificar** `tokens.css` / `themes.css` / `theme-engine.js` sem versionar
7. **Vercel nunca em produção** — apenas Cloudflare Pages
8. **Presentation-ready** — toda página deve convencer executivo sem explicação verbal
9. **Cookies cross-site obrigatórios `SameSite=None; Secure; Partitioned`** — Pages e Workers ficam em origens distintas; `SameSite=Lax` quebra o login. Ver `farpa-reengenharia/03-arquitetura/02-fluxos-e-apis.md` → seção "Autenticação Pages ↔ Worker".
10. **Logo system unificado** — todo produto usa o mesmo componente `farpa-logo` (mark + wordmark "farpa" + sublabel), trocando só `--logo-mark-bg`. Nunca criar SVG próprio. Ver `farpa-reengenharia/02-design-system/03-logo-system.md`.
11. **Ícones SVG line, nunca emojis** como ícones funcionais — usar Lucide Icons inline. Emoji só em microcopy (toast, saudação). Ver `farpa-reengenharia/02-design-system/02-identidade-visual.md` § Iconografia.
12. **Carrossel de produtos na landing do principal** — `rff82/AI/index.html` consome `/data/products.json` gerado do `ecosystem.yaml`. Adicionar produto novo = editar YAML + rodar `regen-docs.py`. Ver `farpa-reengenharia/02-design-system/04-product-carousel.md`.
13. **Números públicos precisam de fonte real** — nunca colocar stats inventadas (`500+ usuários`) em landing. Ou puxa de D1, ou não mostra.
14. **Paleta por tendência de categoria** — antes de definir cores de qualquer produto novo, rodar pesquisa em WGSN + Mobbin (top-tier da categoria) + Dribbble + Awwwards. Índigo `#4338CA` é cor mestre farpa, só vira *primary* em IdP/admin. Demais produtos têm primary on-trend da categoria. Metodologia + mapa vigente de paletas: `farpa-reengenharia/02-design-system/05-trend-research.md`.
15. **CI self-healing obrigatório** — todo `ci.yml` de produto deve capturar logs (`tee + upload-artifact`) e ter job `record-failure` (`needs: [...]` + `if: failure()`) que apende a falha em `## HISTÓRICO DE FALHAS DE CI` do `CLAUDE.md` local com commit `[skip ci]` + issue automática `ci-failure`. Nenhuma falha pode sumir. Ver `farpa-reengenharia/06-operacional/09-ci-self-healing.md`.

---

## NAMING CONVENTIONS

| Recurso | Padrão | Exemplo |
|---|---|---|
| GitHub repo | `rff82/{produto}-farpa-ai` | `rff82/radar-farpa-ai` *(exceção: rff82/AI)* |
| CF Pages project | `{produto}-farpa-ai` | `radar-farpa-ai` |
| Subdomínio | `{produto}.farpa.ai` | `radar.farpa.ai` |
| Worker | `{produto}-worker` | `radar-worker` |
| D1 database | `{produto}-farpa-ai-db` | `radar-farpa-ai-db` |
| KV namespace | `{PRODUTO}_CACHE` | `RADAR_CACHE` |
| D1 binding em wrangler | `DB` | — |
| KV binding em wrangler | `CACHE` | — |
| AI binding em wrangler | `AI` | — |

---

## COMMIT CONVENTIONS

```
feat:      nova funcionalidade
fix:       correção de bug
redesign:  mudança visual sem alteração de comportamento
refactor:  melhoria de código sem mudança de comportamento
chore:     configuração, CI, dependências
content:   texto, copy, traduções
docs:      documentação
infra:     infraestrutura, provisionamento, orquestração
```

---

## SECRETS NESTE REPO

| Secret | Origem | Usado por |
|---|---|---|
| `ANTHROPIC_API_KEY` | console.anthropic.com | `claude-code-action` em todos os workflows |
| `CF_API_TOKEN` | CF → API Tokens (Pages+Workers+D1+KV+DNS Edit) | deploy.yml, audit.yml, provision.yml |
| `CF_ACCOUNT_ID` | CF dashboard → sidebar direita | Todas as chamadas wrangler |
| `CF_ZONE_ID` | CF → farpa.ai → Overview | provision.yml (criar DNS) |
| `GH_PAT` | GitHub → Settings → PAT (escopos: `repo` + `workflow`) | sync.yml, provision.yml, repository_dispatch |

> Cada repo produto também precisa de `GH_PAT` para o job `notify-orchestrator`.
> Os secrets `CLOUDFLARE_API_TOKEN` e `CLOUDFLARE_ACCOUNT_ID` já existem nos repos produto — não remover.

---

## INSTRUÇÕES POR WORKFLOW

### Quando AUDITANDO (`audit.yml`)
- Cruzar estado real do CF contra `config/cloudflare-resources.json`
- Agrupar findings em: **Crítico** (recurso ausente/down) / **Warning** (inesperado) / **OK**
- Para cada item Crítico, fornecer o comando wrangler exato de correção
- Só criar Issue se houver Crítico ou Warning — não criar para estado 100% OK
- Formato do Issue: Markdown, labels `audit infrastructure automated`

### Quando SINCRONIZANDO (`sync.yml`)
- Verificar presença de: `CLAUDE.md`, `.github/workflows/ci.yml`, `wrangler.jsonc` (se tem worker)
- Detectar padrões de secret exposto: `sk-ant-`, `ANTHROPIC_API_KEY\s*=`, `cfut_`
- Reportar no Step Summary — nunca commitar nada nos repos produto

### Quando DEPLOYANDO (`deploy.yml`)
- Validar ausência de secrets antes de qualquer push
- Deploy Pages ANTES dos Workers (Pages pode depender de rotas do Worker)
- Após deploy, verificar endpoint `/health` para produtos com Worker
- Respeitar `max-parallel: 3` para evitar conflitos de build no CF

### Quando PROVISIONANDO (`provision.yml`)
1. Validar naming convention antes de criar qualquer recurso
2. Verificar conflito com produtos em `config/ecosystem.json`
3. Capturar IDs retornados pelo wrangler (d1 database_id, kv namespace_id) e salvar em ecosystem.json
4. Gerar CLAUDE.md usando `templates/CLAUDE.md.tmpl` — preencher TODAS as seções
5. Issue final deve incluir checklist de steps manuais pós-provisionamento

---

## DESIGN SYSTEM (referência)

```
Paleta:     Índigo #4338CA (primary) + Âmbar #F59E0B (accent)
Tipografia: Plus Jakarta Sans · JetBrains Mono
Temas:      Claro · Escuro · Sépia · Alto Contraste · Trader
CSS core:   tokens.css → themes.css → components.css → theme-engine.js
```

---

---

## INTEGRAÇÕES GOOGLE

### Stitch MCP (uso local — Claude Code)
Ferramenta de geração de telas e design system da Google. Disponível via MCP localmente.
**NÃO roda em GitHub Actions** — usar interativamente no Claude Code.

| Tool MCP | Quando usar |
|---|---|
| `create_design_system` | Ao criar o design system farpa.ai central no Stitch |
| `generate_screen_from_text` | Ao provisionar novo produto — gerar wireframes da home |
| `generate_variants` | Gerar variações de temas (claro/escuro/alto-contraste) |
| `edit_screens` | Ajustar telas geradas para seguir tokens do ecossistema |
| `apply_design_system` | Aplicar design system farpa.ai em novas telas |

**Design System Stitch farpa.ai** — quando criar via MCP, usar:
- Paleta: Índigo #4338CA (primary), Âmbar #F59E0B (accent), backgrounds neutros
- Tipografia: Plus Jakarta Sans (UI), JetBrains Mono (dados)
- Componentes: header com alto-contraste-btn, cards de dados, navegação lateral

**Workflow de uso:**
1. Provision.yml gera um `design-brief.md` com especificações do novo produto
2. Localmente, você usa Claude Code + Stitch MCP para gerar as telas
3. As telas geradas servem como referência visual para o `index.html` inicial

---

### Gemini API (Google AI Studio)
Disponível localmente via MCP (`google-gemini` em settings.json) e nos workflows via HTTP direto.

**Modelos disponíveis no ecossistema:**
| Modelo | Uso recomendado |
|---|---|
| `gemini-2.0-flash` | Default — rápido e eficiente, uso geral nos Workers |
| `gemini-1.5-pro` | Análise de documentos longos, contexto extenso |
| `gemini-2.0-flash-exp` | Experimental — multimodal avançado (imagens + texto) |

**Search Grounding (Gemini + Google Search em tempo real):**
- Ativar passando `tools: [{googleSearch: {}}]` na chamada da API
- Usado em `audit.yml` para enriquecer relatórios com contexto de mercado
- Usado em Workers de news/markets do farpa.ai para dados atualizados
- Não conta como chamada de Search separada — incluso no plano Gemini pago

**Secret nos workflows:** `GEMINI_API_KEY`
**Endpoint:** `https://generativelanguage.googleapis.com/v1beta/models/`

---

### Imagen 3 (geração de imagens)
API de geração de imagens da Google — qualidade fotorrealista e de design.

**Uso no ecossistema:**
- `provision.yml` → gera hero image para novo produto (OG image + banner)
- Workers de health → análise de imagens médicas (Vision, não geração)
- Geração de thumbnails para conteúdo educacional (library)

**Secret nos workflows:** `GOOGLE_IMAGEN_API_KEY`
**Endpoint:** `https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-001:predict`

**Prompt padrão para hero images:**
> "Minimal dark interface design for {product_name}, Brazilian fintech/health/AI platform,
> indigo and amber color palette, plus jakarta sans typography, presentation-ready,
> executive audience, clean data visualization elements"

---

### NotebookLM (uso manual — sem API pública)
O NotebookLM não tem API pública. Integração é via workflow manual:

**Workflow recomendado:**
1. `sync.yml` exporta docs do farpa-reengenharia para Google Drive (via API)
2. No NotebookLM, adicionar os docs do Drive como fonte
3. Usar o NotebookLM para gerar podcasts de briefing e análises de produto
4. Os sumários gerados voltam para os Issues do GitHub via copy-paste

**Docs que devem estar no NotebookLM:**
- `farpa-reengenharia/00-visao/` — missão e posicionamento
- `farpa-reengenharia/01-produtos/` — specs de cada produto
- `farpa-reengenharia/04-roadmap/` — fases e backlog

---

## SECRETS NESTE REPO

### Anthropic + GitHub
| Secret | Origem | Usado por |
|---|---|---|
| `ANTHROPIC_API_KEY` | console.anthropic.com | `claude-code-action` — todos os workflows |
| `GH_PAT` | GitHub → Settings → PAT (`repo` + `workflow`) | sync.yml, provision.yml, repository_dispatch |

### Cloudflare — segregados por escopo mínimo

| Secret | Permissões CF | Usado por | Por que separado |
|---|---|---|---|
| `CF_TOKEN_READ` | Pages:Read · Workers:Read · D1:Read · KV:Read | `audit.yml` | Só lê — se vazar, não destrói nada |
| `CF_TOKEN_DEPLOY` | Pages:Edit · Workers Scripts:Edit | `deploy.yml` | Deploy não precisa criar recursos |
| `CF_TOKEN_PROVISION` | Pages:Edit · Workers:Edit · D1:Edit · KV:Edit | `provision.yml` (wrangler) | Cria recursos, não mexe em DNS |
| `CF_TOKEN_DNS` | DNS:Edit (zona farpa.ai) | `provision.yml` (curl API) | DNS é zona-level, isolado |
| `CF_ACCOUNT_ID` | — | Todos os workflows CF | Não é secret mas necessário |

> **Como criar no Cloudflare:** dash.cloudflare.com → My Profile → API Tokens → Create Token → Custom Token

### Google
| Secret | Origem | Custo | Usado por |
|---|---|---|---|
| `GEMINI_API_KEY` | aistudio.google.com → Get API Key | Free tier | audit.yml (Search Grounding) |
| `GOOGLE_IMAGEN_API_KEY` | Mesma key do Gemini | ~$0.04/imagem | provision.yml (opcional, default off) |

> **MCP Local (Claude Code):** Gemini API em `~/.claude/settings.json` · Stitch configurado via Claude Desktop

---

*farpa.ai · rff82/orchestrator-farpa · CLAUDE.md · v1.1 · 2026-04-13*
