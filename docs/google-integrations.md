# Google Integrations — farpa.ai Ecosystem
> rff82/orchestrator-farpa · docs · v1.0 · 2026-04-13

---

## Mapa de Integração

| Ferramenta | Onde roda | Secret | Uso principal |
|---|---|---|---|
| Gemini API | GitHub Actions + Claude Code local | `GEMINI_API_KEY` | audit.yml Search Grounding, Workers |
| Imagen 3 | GitHub Actions | `GOOGLE_IMAGEN_API_KEY` | provision.yml hero images |
| Google Stitch | Claude Code local (MCP) | — (OAuth interno) | Design system + geração de telas |
| NotebookLM | Manual (browser) | — (sem API) | Briefings, análise de docs |

---

## Gemini API

### Configuração nos workflows (GitHub Actions)

Secret a adicionar no repo: `GEMINI_API_KEY`

```bash
gh secret set GEMINI_API_KEY --repo rff82/orchestrator-farpa
# Cole a key quando solicitado
```

### Onde é usado

**`audit.yml` — Search Grounding:**
```yaml
- name: Enrich with Gemini Search Grounding
  run: |
    curl -X POST \
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$GEMINI_API_KEY" \
      --data '{"contents": [...], "tools": [{"google_search": {}}]}'
```
Enriquece relatórios de auditoria com notícias de incidentes Cloudflare e mudanças de API em tempo real.

**`provision.yml` — Design brief generation:**
Claude usa Gemini via API para enriquecer o contexto visual antes de gerar o brief Stitch.

### Configuração nos Workers (wrangler secret)

Os Workers que precisam do Gemini já têm `GEMINI_API_KEY` mapeado em `farpa-secrets-map.sh`:
- `labs-farpa-ai` — Gemini + Claude para MVPs de IA
- `health-farpa-ai` — Gemini Vision para análise de imagens médicas
- `fintech-farpa.ai` — Gemini para análise de compliance

```bash
wrangler secret put GEMINI_API_KEY --name health-worker
wrangler secret put GEMINI_API_KEY --name labs-worker
wrangler secret put GEMINI_API_KEY --name fintech-worker
```

### Modelos e quando usar cada um

| Modelo | Contexto | Velocidade | Ideal para |
|---|---|---|---|
| `gemini-2.0-flash` | 1M tokens | Muito rápido | Default — Workers, audit |
| `gemini-1.5-pro` | 2M tokens | Moderado | Análise de docs longos |
| `gemini-2.0-flash-exp` | 1M tokens | Rápido | Multimodal (imagem+texto) |

### Search Grounding — Ativação

```json
{
  "tools": [{"google_search": {}}],
  "contents": [{"parts": [{"text": "sua pergunta"}]}]
}
```
Incluso no plano Google AI Studio pago — não gera custo adicional por busca.

---

## Imagen 3

### Configuração

Secret a adicionar: `GOOGLE_IMAGEN_API_KEY`

```bash
gh secret set GOOGLE_IMAGEN_API_KEY --repo rff82/orchestrator-farpa
```

### Onde é usado

**`provision.yml` — Hero image:**
Ao provisionar novo produto, gera automaticamente uma hero image 16:9
em `/assets/hero.png` no repo do produto.

### Endpoint e parâmetros

```bash
curl -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-001:predict?key=$KEY" \
  -H "Content-Type: application/json" \
  --data '{
    "instances": [{"prompt": "..."}],
    "parameters": {
      "sampleCount": 1,
      "aspectRatio": "16:9",
      "safetyFilterLevel": "block_some"
    }
  }'
```

### Prompt padrão farpa.ai

```
Minimal dark interface design for farpa {PRODUCT}, Brazilian AI platform,
indigo #4338CA and amber #F59E0B color palette, plus jakarta sans typography,
presentation-ready for executive audience, clean data visualization elements,
subtle gradient, professional aesthetic
```

---

## Google Stitch (MCP local)

### O que é

Ferramenta de geração de UI da Google. Aceita prompts de texto e gera
telas completas de interface. Integrado ao Claude Code via MCP.

### Fluxo no ecossistema farpa.ai

```
provision.yml
  → Gera stitch-design-brief.md no repo produto
  ↓
Claude Code local
  → Lê o brief
  → mcp__stitch__create_design_system (design system farpa)
  → mcp__stitch__generate_screen_from_text (tela por tela)
  → mcp__stitch__generate_variants (alto-contraste obrigatório)
  ↓
Resultado
  → Telas como referência visual
  → Código HTML/CSS gerado a partir das telas
```

### Design brief para Stitch — estrutura padrão farpa.ai

```json
{
  "designSystem": {
    "name": "farpa-design-system",
    "colors": {
      "primary": "#4338CA",
      "primaryLight": "#6366F1",
      "accent": "#F59E0B",
      "background": "#0F0F13",
      "surface": "#1A1A24",
      "border": "#2D2D3D",
      "text": "#F1F5F9",
      "textMuted": "#94A3B8"
    },
    "fonts": {
      "sans": "Plus Jakarta Sans",
      "mono": "JetBrains Mono"
    },
    "radii": {"sm": "4px", "md": "8px", "lg": "12px"},
    "shadows": {"card": "0 4px 24px rgba(0,0,0,0.4)"}
  },
  "requiredComponents": [
    "header com btn-alto-contraste sempre visível",
    "navigation",
    "data-card",
    "chart-container",
    "footer"
  ]
}
```

---

## NotebookLM

### Limitação: sem API pública

O NotebookLM não tem API programática ainda (2026). Toda integração é manual.

### Setup recomendado

1. Acesse notebooklm.google.com (login com conta Google paga)
2. Crie um notebook: **"farpa.ai — Ecosystem Context"**
3. Adicione fontes prioritárias:

```
Prioridade 1 (sempre ter atualizado):
  - farpa-reengenharia/00-visao/01-missao-e-posicionamento.md
  - farpa-reengenharia/00-visao/02-ecossistema.md

Prioridade 2 (por produto ativo):
  - farpa-reengenharia/01-produtos/01-farpa-principal.md
  - farpa-reengenharia/01-produtos/03-farpa-health.md
  - farpa-reengenharia/01-produtos/04-farpa-fintech.md

Prioridade 3 (arquitetura):
  - farpa-reengenharia/03-arquitetura/01-infra-e-stack.md
  - farpa-reengenharia/04-roadmap/01-roadmap-e-backlog.md
```

### Casos de uso

| Caso | Como usar |
|---|---|
| Briefing executivo | Audio Overview → gera podcast de 5-10min sobre o produto |
| Análise de roadmap | Perguntar ao notebook sobre próximas entregas e dependências |
| Onboarding | Novos colaboradores fazem perguntas ao notebook para entender o ecossistema |
| Revisão de ADRs | Perguntar consistência entre decisões de arquitetura |

### Manutenção

Atualizar o notebook NotebookLM sempre que:
- Novo produto for provisionado (após `provision.yml`)
- ADR novo for aprovado
- Roadmap for revisado

---

*farpa.ai · rff82/orchestrator-farpa · docs/google-integrations.md · v1.0 · 2026-04-13*
