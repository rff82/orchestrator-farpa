#!/bin/bash
# ══════════════════════════════════════════════════════════════════
#  audit-cloudflare.sh — Audita recursos Cloudflare do ecossistema
#  · Compara estado real vs config/cloudflare-resources.json
#  · HTTP check de todos os subdomínios
#  · Output: /tmp/audit-report.json
#
#  Chamado por: .github/workflows/audit.yml
#  Requer: wrangler autenticado via CF_API_TOKEN + CF_ACCOUNT_ID
# ══════════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EXPECTED_FILE="$REPO_ROOT/config/cloudflare-resources.json"
OUTPUT_FILE="/tmp/audit-report.json"

echo "=== Auditoria Cloudflare farpa.ai ==="
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ── 1. Coletar estado real do Cloudflare ──────────────────────────

echo "Coletando Pages projects..."
PAGES_RAW=$(npx wrangler pages project list --json 2>/dev/null || echo "[]")
PAGES_FOUND=$(echo "$PAGES_RAW" | jq -r '[.[].name] // []' 2>/dev/null || echo "[]")

echo "Coletando D1 databases..."
D1_RAW=$(npx wrangler d1 list --json 2>/dev/null || echo "[]")
D1_FOUND=$(echo "$D1_RAW" | jq -r '[.[].name] // []' 2>/dev/null || echo "[]")

echo "Coletando KV namespaces..."
KV_RAW=$(npx wrangler kv namespace list --json 2>/dev/null || echo "[]")
KV_FOUND=$(echo "$KV_RAW" | jq -r '[.[].title] // []' 2>/dev/null || echo "[]")

echo "Coletando Workers..."
WORKERS_FOUND=$(npx wrangler workers list --json 2>/dev/null \
  | jq -r '[.[].id] // []' 2>/dev/null || echo "[]")

# ── 2. HTTP check dos subdomínios ─────────────────────────────────

echo "Verificando subdomínios HTTP..."
SUBDOMAINS=$(jq -r '.subdomains[]' "$EXPECTED_FILE")
SUBDOMAIN_STATUS="{}"

for domain in $SUBDOMAINS; do
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time 15 --connect-timeout 10 \
    "https://$domain" 2>/dev/null || echo "000")
  SUBDOMAIN_STATUS=$(echo "$SUBDOMAIN_STATUS" | \
    jq --arg d "$domain" --arg c "$code" '. + {($d): ($c | tonumber)}')
  echo "  $domain → HTTP $code"
done

# ── 3. Cruzar com estado esperado ─────────────────────────────────

EXPECTED_PAGES=$(jq -r '[.pages_projects[]]' "$EXPECTED_FILE")
EXPECTED_D1=$(jq -r '[.d1_databases[]]' "$EXPECTED_FILE")
EXPECTED_KV=$(jq -r '[.kv_namespaces[]]' "$EXPECTED_FILE")
EXPECTED_WORKERS=$(jq -r '[.workers[]]' "$EXPECTED_FILE")

# ── 4. Gerar relatório JSON ───────────────────────────────────────

jq -n \
  --argjson ts "$(date -u +%s)" \
  --argjson exp_pages "$EXPECTED_PAGES" \
  --argjson found_pages "$PAGES_FOUND" \
  --argjson exp_d1 "$EXPECTED_D1" \
  --argjson found_d1 "$D1_FOUND" \
  --argjson exp_kv "$EXPECTED_KV" \
  --argjson found_kv "$KV_FOUND" \
  --argjson exp_workers "$EXPECTED_WORKERS" \
  --argjson found_workers "$WORKERS_FOUND" \
  --argjson subdomain_status "$SUBDOMAIN_STATUS" \
  '{
    timestamp: ($ts | todate),
    pages: {
      expected: $exp_pages,
      found: $found_pages,
      missing: ($exp_pages - $found_pages),
      unexpected: ($found_pages - $exp_pages)
    },
    d1: {
      expected: $exp_d1,
      found: $found_d1,
      missing: ($exp_d1 - $found_d1),
      unexpected: ($found_d1 - $exp_d1)
    },
    kv: {
      expected: $exp_kv,
      found: $found_kv,
      missing: ($exp_kv - $found_kv),
      unexpected: ($found_kv - $exp_kv)
    },
    workers: {
      expected: $exp_workers,
      found: $found_workers,
      missing: ($exp_workers - $found_workers),
      unexpected: ($found_workers - $exp_workers)
    },
    subdomains: $subdomain_status
  }' > "$OUTPUT_FILE"

echo ""
echo "Relatório salvo em: $OUTPUT_FILE"
echo ""

# ── 5. Resumo de saída ────────────────────────────────────────────

MISSING_PAGES=$(jq -r '.pages.missing | length' "$OUTPUT_FILE")
MISSING_D1=$(jq -r '.d1.missing | length' "$OUTPUT_FILE")
MISSING_KV=$(jq -r '.kv.missing | length' "$OUTPUT_FILE")
MISSING_WORKERS=$(jq -r '.workers.missing | length' "$OUTPUT_FILE")
DOWN_DOMAINS=$(jq -r '[.subdomains | to_entries[] | select(.value != 200 and .value != 301 and .value != 302)] | length' "$OUTPUT_FILE")

echo "=== RESUMO ==="
echo "Pages faltando:   $MISSING_PAGES"
echo "D1 faltando:      $MISSING_D1"
echo "KV faltando:      $MISSING_KV"
echo "Workers faltando: $MISSING_WORKERS"
echo "Domínios down:    $DOWN_DOMAINS"

TOTAL_ISSUES=$((MISSING_PAGES + MISSING_D1 + MISSING_KV + MISSING_WORKERS + DOWN_DOMAINS))
if [ "$TOTAL_ISSUES" -eq 0 ]; then
  echo "STATUS: OK — Nenhum problema encontrado"
  exit 0
else
  echo "STATUS: ISSUES ENCONTRADOS — Ver $OUTPUT_FILE"
  exit 1
fi
