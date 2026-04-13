#!/bin/bash
# ══════════════════════════════════════════════════════════════════
#  provision-product.sh — Provisiona recursos Cloudflare de novo produto
#  · Cria Cloudflare Pages project
#  · Cria D1 database (opcional)
#  · Cria KV namespace (opcional)
#  · Outputs: IDs capturados em /tmp/provision-ids.json
#
#  Uso: ./provision-product.sh <product_name> [has_d1] [has_kv]
#  Chamado por: .github/workflows/provision.yml
#  Requer: wrangler autenticado via CF_API_TOKEN + CF_ACCOUNT_ID
# ══════════════════════════════════════════════════════════════════
set -euo pipefail

PRODUCT_NAME="${1:?Nome do produto obrigatório (ex: radar)}"
HAS_D1="${2:-false}"
HAS_KV="${3:-false}"

REPO_NAME="${PRODUCT_NAME}-farpa-ai"
CF_PAGES_PROJECT="${PRODUCT_NAME}-farpa-ai"
D1_NAME="${PRODUCT_NAME}-farpa-ai-db"
KV_NAME="${PRODUCT_NAME^^}_CACHE"

IDS_FILE="/tmp/provision-ids.json"
echo "{}" > "$IDS_FILE"

echo "=== Provisionamento: $PRODUCT_NAME ==="
echo "Repo:          rff82/$REPO_NAME"
echo "Pages project: $CF_PAGES_PROJECT"
echo "D1:            $HAS_D1 ($D1_NAME)"
echo "KV:            $HAS_KV ($KV_NAME)"

# ── 1. Cloudflare Pages ───────────────────────────────────────────

echo ""
echo "→ Criando Cloudflare Pages project: $CF_PAGES_PROJECT"
npx wrangler pages project create "$CF_PAGES_PROJECT" \
  --production-branch main 2>&1 | tee /tmp/pages-output.txt || true

# Verificar se criou ou já existia
if npx wrangler pages project list --json 2>/dev/null \
    | jq -e --arg p "$CF_PAGES_PROJECT" '.[] | select(.name == $p)' > /dev/null 2>&1; then
  echo "✓ Pages project pronto: $CF_PAGES_PROJECT"
else
  echo "ERRO: Falha ao criar Pages project"
  exit 1
fi

# ── 2. D1 Database ────────────────────────────────────────────────

if [ "$HAS_D1" = "true" ]; then
  echo ""
  echo "→ Criando D1 database: $D1_NAME"
  D1_OUTPUT=$(npx wrangler d1 create "$D1_NAME" --json 2>/dev/null || \
              npx wrangler d1 create "$D1_NAME" 2>&1 || true)

  D1_ID=$(echo "$D1_OUTPUT" | jq -r '.uuid // empty' 2>/dev/null || \
          echo "$D1_OUTPUT" | grep -oP '"uuid":\s*"\K[^"]+' || echo "")

  if [ -n "$D1_ID" ]; then
    echo "✓ D1 criado: $D1_NAME (ID: $D1_ID)"
    jq --arg id "$D1_ID" --arg name "$D1_NAME" \
      '. + {"d1_id": $id, "d1_name": $name}' "$IDS_FILE" > /tmp/ids-tmp.json
    mv /tmp/ids-tmp.json "$IDS_FILE"
  else
    echo "AVISO: D1 criado mas ID não capturado. Verificar manualmente com: wrangler d1 list"
  fi
fi

# ── 3. KV Namespace ───────────────────────────────────────────────

if [ "$HAS_KV" = "true" ]; then
  echo ""
  echo "→ Criando KV namespace: $KV_NAME"
  KV_OUTPUT=$(npx wrangler kv namespace create "$KV_NAME" --json 2>/dev/null || \
              npx wrangler kv namespace create "$KV_NAME" 2>&1 || true)

  KV_ID=$(echo "$KV_OUTPUT" | jq -r '.id // empty' 2>/dev/null || \
          echo "$KV_OUTPUT" | grep -oP '"id":\s*"\K[^"]+' || echo "")

  if [ -n "$KV_ID" ]; then
    echo "✓ KV criado: $KV_NAME (ID: $KV_ID)"
    jq --arg id "$KV_ID" --arg name "$KV_NAME" \
      '. + {"kv_id": $id, "kv_name": $name}' "$IDS_FILE" > /tmp/ids-tmp.json
    mv /tmp/ids-tmp.json "$IDS_FILE"
  else
    echo "AVISO: KV criado mas ID não capturado. Verificar com: wrangler kv namespace list"
  fi
fi

echo ""
echo "=== IDs capturados ==="
cat "$IDS_FILE"
echo ""
echo "=== Provisionamento CF concluído: $PRODUCT_NAME ==="
