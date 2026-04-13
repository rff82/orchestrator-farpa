# CLAUDE.md — rff82/orchestrator-farpa
> Arquivo de contexto do Orquestrador Cloud · v1.0 · 2026-04-13
> Lido por Claude no início de cada step de workflow neste repositório.
> Submisso ao Orquestrador Masterizado: Projetos/CLAUDE.md

---

## O QUE ESTE REPO FAZ

Este é o **orquestrador central** do ecossistema farpa.ai. Roda inteiramente em
GitHub Actions — zero instalação local necessária. Gerencia deploy, sync, auditoria
e provisionamento de todos os produtos via quatro workflows:

| Workflow | Arquivo | Função |
|---|---|---|
| Audit | `audit.yml` | Health check diário → GitHub Issue |
| Sync | `sync.yml` | Valida/atualiza todos os repos rff82/* |
| Deploy | `deploy.yml` | Deploy Pages + Workers no Cloudflare |
| Provision | `provision.yml` | Cria novo produto end-to-end |

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

1. **Alto contraste sempre visível** — botão no header de toda página. Rodrigo tem baixa visão. Isso é requisito de existência.
2. **WCAG AA mínimo** — verificar contraste antes de qualquer sugestão de código
3. **API keys nunca no cliente** — sempre `wrangler secret put`, nunca em JS/HTML
4. **Cores nunca hardcoded** — sempre `var(--token-name)`
5. **Tipografia imutável** — Plus Jakarta Sans (UI/display) + JetBrains Mono (dados/código)
6. **Nunca modificar** `tokens.css` / `themes.css` / `theme-engine.js` sem versionar
7. **Vercel nunca em produção** — apenas Cloudflare Pages
8. **Presentation-ready** — toda página deve convencer executivo sem explicação verbal

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

*farpa.ai · rff82/orchestrator-farpa · CLAUDE.md · v1.0 · 2026-04-13*
