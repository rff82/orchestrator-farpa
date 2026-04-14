# orchestrator-farpa

Orquestrador central do ecossistema **farpa.ai** — roda inteiramente em GitHub Actions.
Sem instalação local. Deploy, sync, auditoria e provisionamento com Claude + Gemini como agentes de decisão.

## Workflows

| Workflow | Trigger | Função |
|---|---|---|
| **Audit** | Diário 07:00 UTC + manual | Health check Cloudflare + Gemini Search Grounding → GitHub Issue |
| **Sync** | Segunda 08:00 UTC + manual | Valida estrutura de todos os repos |
| **Deploy** | Manual + repository_dispatch | Deploy Pages + Workers no Cloudflare |
| **Provision** | Manual | Cria novo produto end-to-end + Imagen 3 hero + Stitch brief |
| **Design** | Manual | Gera design brief para uso local com Stitch MCP |

## Como usar

### Auditar infraestrutura
Actions → **Audit — Cloudflare Health Check** → Run workflow
- Verifica Pages, Workers, D1, KV, DNS e HTTP status de todos os subdomínios
- Gemini Search Grounding enriquece o relatório com alertas externos em tempo real
- Cria GitHub Issue apenas se houver problemas

### Deploiar um produto
Actions → **Deploy — farpa.ai Ecosystem** → Run workflow
- `product`: slug do repo (ex: `health-farpa-ai`) ou `all`
- `deploy_pages`: deploy Cloudflare Pages
- `deploy_workers`: deploy Workers
- `claude_review`: revisão de segurança pré-deploy com Claude

### Provisionar novo produto
Actions → **Provision — Create New Product** → Run workflow
- `product_name`: slug (ex: `radar`) → gera `rff82/radar-farpa-ai`
- `subdomain`: (ex: `radar`) → gera `radar.farpa.ai`
- `has_worker`, `has_d1`, `has_kv`: recursos a criar no Cloudflare
- `generate_hero_image`: gera hero 16:9 com Imagen 3
- `generate_stitch_brief`: gera brief para uso local com Stitch MCP

### Gerar telas com Stitch
Actions → **Design — Stitch Brief Generator** → Run workflow (gera o brief)
Depois localmente: Claude Code + ferramentas `mcp__stitch__*`
→ Ver `docs/mcp-local-setup.md`

### Sincronizar / validar repos
Actions → **Sync — Validate All rff82 Repos** → Run workflow

## Secrets necessários

Configurar em: **Settings → Secrets and variables → Actions**

### Anthropic + GitHub

| Secret | Descrição | Onde obter |
|---|---|---|
| `ANTHROPIC_API_KEY` | Claude AI — todos os workflows | console.anthropic.com |
| `GH_PAT` | GitHub PAT escopos: `repo` + `workflow` | github.com → Settings → Developer settings → PAT |

### Cloudflare — 4 tokens segregados por escopo mínimo

> Criar em: dash.cloudflare.com → My Profile → API Tokens → **Create Token → Custom Token**

| Secret | Permissões necessárias | Nível | Workflow |
|---|---|---|---|
| `CF_TOKEN_READ` | Pages:Read, Workers Scripts:Read, D1:Read, Workers KV Storage:Read | Account | `audit.yml` |
| `CF_TOKEN_DEPLOY` | Cloudflare Pages:Edit, Workers Scripts:Edit | Account | `deploy.yml` |
| `CF_TOKEN_PROVISION` | Pages:Edit, Workers Scripts:Edit, D1:Edit, Workers KV Storage:Edit | Account | `provision.yml` |
| `CF_TOKEN_DNS` | DNS:Edit | Zone → farpa.ai | `provision.yml` |
| `CF_ACCOUNT_ID` | — (não é token, é ID público) | — | Todos |

### Google (opcionais mas recomendados)

| Secret | Descrição | Custo | Onde obter |
|---|---|---|---|
| `GEMINI_API_KEY` | Gemini + Search Grounding no audit | **Free tier** | aistudio.google.com → Get API Key |
| `GOOGLE_IMAGEN_API_KEY` | Imagen 3 no provision (default off) | ~$0.04/img | Mesma key do Gemini |
| `CF_ZONE_ID` | Zone ID do domínio farpa.ai — DNS no provision | — | dash.cloudflare.com → farpa.ai → Overview |

## MCPs Locais (Claude Code)

Configure em `~/.claude/settings.json` para usar Gemini e Stitch interativamente.
→ Ver `docs/mcp-local-setup.md`

**Stitch** já está disponível como MCP nesta instalação (ferramentas `mcp__stitch__*`).
**Gemini** requer adicionar a key no settings.json.

## Ecossistema

Gerenciado via `config/ecosystem.json`. Produtos ativos:

| Produto | Subdomínio | Status |
|---|---|---|
| rff82/AI | [farpa.ai](https://farpa.ai) | ✅ Live |
| rff82/labs-farpa-ai | [labs.farpa.ai](https://labs.farpa.ai) | 🔨 Em construção |
| rff82/health-farpa-ai | [health.farpa.ai](https://health.farpa.ai) | 🔨 Em construção |
| rff82/fintech-farpa.ai | [fintech.farpa.ai](https://fintech.farpa.ai) | 🔨 Em construção |
| rff82/libery-farpa-ai | [library.farpa.ai](https://library.farpa.ai) | 🔨 Em construção |
| rff82/docs-farpa-ai | [docs.farpa.ai](https://docs.farpa.ai) | 📋 Planejado |

## Documentação

- `docs/mcp-local-setup.md` — Como configurar Gemini e Stitch MCP localmente
- `docs/google-integrations.md` — Gemini, Imagen 3, Stitch e NotebookLM em detalhe

---

*farpa.ai · rff82/orchestrator-farpa · v1.1 · 2026*
