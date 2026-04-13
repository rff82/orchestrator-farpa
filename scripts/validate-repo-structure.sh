#!/bin/bash
# ══════════════════════════════════════════════════════════════════
#  validate-repo-structure.sh — Valida estrutura de um repo produto
#  · Verifica presença de arquivos essenciais
#  · Detecta padrões de secrets expostos
#  · Output: JSON com resultado por repo
#
#  Uso: ./validate-repo-structure.sh <repo_dir> <repo_name> <has_worker>
#  Chamado por: .github/workflows/sync.yml
# ══════════════════════════════════════════════════════════════════
set -euo pipefail

REPO_DIR="${1:?Diretório do repo obrigatório}"
REPO_NAME="${2:?Nome do repo obrigatório}"
HAS_WORKER="${3:-false}"

ISSUES=()
WARNINGS=()

# ── 1. Arquivos obrigatórios ──────────────────────────────────────

if [ ! -f "$REPO_DIR/CLAUDE.md" ]; then
  ISSUES+=("CLAUDE.md ausente")
fi

if [ ! -f "$REPO_DIR/.github/workflows/ci.yml" ]; then
  ISSUES+=(".github/workflows/ci.yml ausente")
fi

if [ ! -f "$REPO_DIR/index.html" ]; then
  WARNINGS+=("index.html ausente na raiz")
fi

# ── 2. Verificar Worker (se aplicável) ───────────────────────────

if [ "$HAS_WORKER" = "true" ]; then
  WRANGLER_FOUND=$(find "$REPO_DIR" -name "wrangler.jsonc" -o -name "wrangler.toml" 2>/dev/null | head -1)
  if [ -z "$WRANGLER_FOUND" ]; then
    ISSUES+=("wrangler.jsonc ausente (produto com Worker)")
  fi
fi

# ── 3. Detectar secrets expostos ─────────────────────────────────

SECRET_PATTERNS=(
  "sk-ant-"
  "ANTHROPIC_API_KEY\s*="
  "cfut_"
  "CF_API_TOKEN\s*="
  "ghp_"
  "github_pat_"
)

for pattern in "${SECRET_PATTERNS[@]}"; do
  FOUND=$(grep -r --include="*.js" --include="*.ts" --include="*.html" \
    --include="*.json" --include="*.sh" \
    -l "$pattern" "$REPO_DIR" 2>/dev/null \
    | grep -v ".git" | grep -v "node_modules" || true)
  if [ -n "$FOUND" ]; then
    ISSUES+=("SECRET EXPOSTO ($pattern) em: $FOUND")
  fi
done

# ── 4. Alto contraste no HTML ─────────────────────────────────────

HTML_FILES=$(find "$REPO_DIR" -maxdepth 1 -name "*.html" 2>/dev/null | head -5)
for html in $HTML_FILES; do
  if ! grep -q "alto-contraste\|btn-alto-contraste" "$html" 2>/dev/null; then
    WARNINGS+=("Botão alto-contraste ausente em $(basename $html)")
  fi
done

# ── 5. Gerar output JSON ──────────────────────────────────────────

ISSUES_JSON=$(printf '%s\n' "${ISSUES[@]+"${ISSUES[@]}"}" | jq -R . | jq -s .)
WARNINGS_JSON=$(printf '%s\n' "${WARNINGS[@]+"${WARNINGS[@]}"}" | jq -R . | jq -s .)
STATUS="ok"
[ ${#ISSUES[@]} -gt 0 ] && STATUS="critical"
[ ${#WARNINGS[@]} -gt 0 ] && [ "$STATUS" = "ok" ] && STATUS="warning"

jq -n \
  --arg repo "$REPO_NAME" \
  --arg status "$STATUS" \
  --argjson issues "$ISSUES_JSON" \
  --argjson warnings "$WARNINGS_JSON" \
  '{
    repo: $repo,
    status: $status,
    issues: $issues,
    warnings: $warnings,
    timestamp: now | todate
  }'

# Exit code baseado em issues críticos
[ ${#ISSUES[@]} -gt 0 ] && exit 1 || exit 0
