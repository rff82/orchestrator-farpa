# Configuração MCPs Locais — farpa.ai
> rff82/orchestrator-farpa · docs · v1.0 · 2026-04-13
> MCPs rodam apenas no Claude Code local — não em GitHub Actions

---

## O que são MCPs aqui

Model Context Protocol servers são extensões que permitem ao Claude Code interagir com
serviços externos diretamente (Gemini API, Stitch, Cloudflare, GitHub, etc.) durante
suas sessões de trabalho. Não afetam os workflows de Actions.

---

## 1. Gemini API MCP

**Arquivo:** `~/.claude/settings.json`

```json
{
  "mcpServers": {
    "google-gemini": {
      "command": "npx",
      "args": ["-y", "@google/generative-language-mcp"],
      "env": {
        "GEMINI_API_KEY": "SUA_GEMINI_API_KEY_AQUI"
      }
    }
  }
}
```

**O que habilita no Claude Code:**
- Chamar modelos Gemini diretamente durante a conversa
- Search Grounding (Gemini + Google Search em tempo real)
- Análise de imagens com gemini-2.0-flash-exp
- Processar documentos longos com gemini-1.5-pro (contexto de 1M tokens)

**Onde obter a key:** aistudio.google.com → Get API Key

---

## 2. Google Stitch MCP

O Stitch MCP já está disponível nesta instalação do Claude Code (aparece como
`mcp__stitch__*` nas ferramentas disponíveis).

**Ferramentas disponíveis:**

| Ferramenta | Uso no ecossistema farpa.ai |
|---|---|
| `mcp__stitch__create_design_system` | Criar o design system central farpa.ai |
| `mcp__stitch__generate_screen_from_text` | Gerar telas de novo produto |
| `mcp__stitch__generate_variants` | Variações claro/escuro/alto-contraste |
| `mcp__stitch__edit_screens` | Ajustar telas para seguir tokens |
| `mcp__stitch__apply_design_system` | Aplicar design system em telas existentes |
| `mcp__stitch__list_projects` | Ver projetos Stitch existentes |
| `mcp__stitch__get_screen` | Inspecionar tela gerada |

**Workflow típico para novo produto:**
```
1. Rodar provision.yml → gera stitch-design-brief.md no repo produto
2. No Claude Code: ler o brief
3. mcp__stitch__create_design_system (se não existir "farpa-design-system")
4. mcp__stitch__generate_screen_from_text (para cada tela do brief)
5. mcp__stitch__generate_variants (gerar tema alto-contraste)
6. Exportar como referência visual para codificar o index.html
```

---

## 3. Cloudflare MCP (já configurado)

O MCP Cloudflare (`mcp__2e189f75-*`) já está ativo nesta sessão.
Permite operar D1, KV, Workers, R2 diretamente no Claude Code.

**Secrets necessários no Claude Code:** configurar via `claude mcp add cloudflare`
ou adicionar em `~/.claude/settings.json`:

```json
"cloudflare": {
  "command": "npx",
  "args": ["-y", "@cloudflare/mcp-server-cloudflare"],
  "env": {
    "CLOUDFLARE_API_TOKEN": "SUA_CF_API_TOKEN",
    "CLOUDFLARE_ACCOUNT_ID": "SEU_CF_ACCOUNT_ID"
  }
}
```

---

## 4. GitHub MCP (já configurado via plugin)

O plugin GitHub já está instalado. Para usar o MCP completo:

```json
"github": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "SEU_GH_PAT"
  }
}
```

---

## settings.json completo (após configurar tokens)

```json
{
  "mcpServers": {
    "google-gemini": {
      "command": "npx",
      "args": ["-y", "@google/generative-language-mcp"],
      "env": {
        "GEMINI_API_KEY": "SUA_GEMINI_API_KEY"
      }
    },
    "cloudflare": {
      "command": "npx",
      "args": ["-y", "@cloudflare/mcp-server-cloudflare"],
      "env": {
        "CLOUDFLARE_API_TOKEN": "USE_CF_TOKEN_PROVISION_OU_READ",
        "CLOUDFLARE_ACCOUNT_ID": "SEU_CF_ACCOUNT_ID"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "SEU_GH_PAT"
      }
    }
  }
}
```

---

## NotebookLM — Uso Manual

O NotebookLM **não tem API pública**. Integração é manual:

1. Acessar notebooklm.google.com
2. Criar notebook "farpa.ai Ecosystem"
3. Adicionar fontes:
   - Exportar docs de `farpa-reengenharia/` como PDF
   - Upload direto ou via Google Drive
4. Usar para:
   - Gerar briefings de produto (Audio Overview)
   - Análise de consistência entre documentos
   - Perguntas sobre arquitetura e roadmap

**Documentos prioritários para upload:**
- `farpa-reengenharia/00-visao/01-missao-e-posicionamento.md`
- `farpa-reengenharia/01-produtos/` (todos os arquivos)
- `farpa-reengenharia/04-roadmap/01-roadmap-e-backlog.md`
- `farpa-reengenharia/03-arquitetura/01-infra-e-stack.md`

---

*farpa.ai · rff82/orchestrator-farpa · docs/mcp-local-setup.md · v1.0 · 2026-04-13*
