# orchestrator-farpa

Orquestrador central do ecossistema **farpa.ai** — roda inteiramente em GitHub Actions.
Sem instalação local. Deploy, sync, auditoria e provisionamento com Claude como agente de decisão.

## Workflows

| Workflow | Trigger | Função |
|---|---|---|
| **Audit** | Diário 07:00 UTC + manual | Health check Cloudflare → GitHub Issue |
| **Sync** | Segunda 08:00 UTC + manual | Valida estrutura de todos os repos |
| **Deploy** | Manual + repository_dispatch | Deploy Pages + Workers no Cloudflare |
| **Provision** | Manual | Cria novo produto end-to-end |

## Como usar

### Auditar infraestrutura
Actions → **Audit — Cloudflare Health Check** → Run workflow

### Deploiar um produto
Actions → **Deploy — farpa.ai Ecosystem** → Run workflow
- `product`: slug do repo (ex: `health-farpa-ai`) ou `all`
- `deploy_pages`: deploy Cloudflare Pages
- `deploy_workers`: deploy Workers
- `claude_review`: revisão de segurança pré-deploy

### Provisionar novo produto
Actions → **Provision — Create New Product** → Run workflow
- `product_name`: slug (ex: `radar`) → gerará `rff82/radar-farpa-ai`
- `subdomain`: (ex: `radar`) → gerará `radar.farpa.ai`
- `has_worker`, `has_d1`, `has_kv`: recursos a criar no Cloudflare

### Sincronizar / validar repos
Actions → **Sync — Validate All rff82 Repos** → Run workflow

## Secrets necessários

Configurar em: Settings → Secrets and variables → Actions

| Secret | Descrição |
|---|---|
| `ANTHROPIC_API_KEY` | Claude AI — usado em todos os workflows |
| `CF_API_TOKEN` | Cloudflare API Token (Pages + Workers + D1 + KV + DNS Edit) |
| `CF_ACCOUNT_ID` | Cloudflare Account ID |
| `CF_ZONE_ID` | Cloudflare Zone ID (farpa.ai) |
| `GH_PAT` | GitHub PAT com escopos `repo` + `workflow` |

## Ecossistema

Gerenciado via `config/ecosystem.json`. Produtos ativos:

- [farpa.ai](https://farpa.ai) — rff82/AI
- [labs.farpa.ai](https://labs.farpa.ai) — rff82/labs-farpa-ai
- [health.farpa.ai](https://health.farpa.ai) — rff82/health-farpa-ai
- [fintech.farpa.ai](https://fintech.farpa.ai) — rff82/fintech-farpa.ai
- [library.farpa.ai](https://library.farpa.ai) — rff82/libery-farpa-ai
- [docs.farpa.ai](https://docs.farpa.ai) — rff82/docs-farpa-ai

---

*farpa.ai · rff82/orchestrator-farpa · v1.0 · 2026*
