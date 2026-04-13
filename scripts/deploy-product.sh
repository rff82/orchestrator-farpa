#!/bin/bash
# ══════════════════════════════════════════════════════════════════
#  deploy-product.sh — Faz deploy de um produto no Cloudflare
#  · Deploy de Cloudflare Pages (opcional)
#  · Deploy de Workers via wrangler (opcional)
#  · Lê metadados de config/ecosystem.json
#
#  Uso: ./deploy-product.sh <repo_name> [deploy_pages] [deploy_workers]
#  Chamado por: .github/workflows/deploy.yml
#  Requer: wrangler autenticado, repo produto já clonado em $GITHUB_WORKSPACE
# ══════════════════════════════════════════════════════════════════
set -euo pipefail

REPO_NAME="${1:?Nome do repo obrigatório (ex: health-farpa-ai)}"
DEPLOY_PAGES="${2:-true}"
DEPLOY_WORKERS="${3:-true}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ECOSYSTEM="$REPO_ROOT/config/ecosystem.json"

# ── Ler metadados do produto ──────────────────────────────────────

PRODUCT=$(jq --arg r "$REPO_NAME" '.products[] | select(.repo == $r)' "$ECOSYSTEM")
if [ -z "$PRODUCT" ]; then
  echo "ERRO: Produto '$REPO_NAME' não encontrado em ecosystem.json"
  exit 1
fi

CF_PAGES_PROJECT=$(echo "$PRODUCT" | jq -r '.cf_pages_project')
HAS_WORKER=$(echo "$PRODUCT" | jq -r '.has_worker')
WORKER_DIR=$(echo "$PRODUCT" | jq -r '.worker_dir')
WORKERS=$(echo "$PRODUCT" | jq -r '.workers[]' 2>/dev/null || true)

# Produto checado em: $GITHUB_WORKSPACE/product/
PRODUCT_DIR="${GITHUB_WORKSPACE:-/workspace}/product"

echo "=== Deploy: $REPO_NAME ==="
echo "Pages project: $CF_PAGES_PROJECT"
echo "Deploy Pages:   $DEPLOY_PAGES"
echo "Deploy Workers: $DEPLOY_WORKERS"
echo "Has Worker:     $HAS_WORKER"

# ── Deploy Pages ──────────────────────────────────────────────────

if [ "$DEPLOY_PAGES" = "true" ]; then
  echo ""
  echo "→ Deploying Cloudflare Pages: $CF_PAGES_PROJECT"
  cd "$PRODUCT_DIR"
  npx wrangler pages deploy . \
    --project-name "$CF_PAGES_PROJECT" \
    --branch main \
    --commit-dirty=true
  PAGES_URL="https://${CF_PAGES_PROJECT}.pages.dev"
  echo "PAGES_URL=$PAGES_URL" >> "${GITHUB_OUTPUT:-/dev/null}"
  echo "✓ Pages deployed: $PAGES_URL"
fi

# ── Deploy Workers ────────────────────────────────────────────────

if [ "$DEPLOY_WORKERS" = "true" ] && [ "$HAS_WORKER" = "true" ] && [ -n "$WORKERS" ]; then
  echo ""
  echo "→ Deploying Workers..."
  while IFS= read -r worker; do
    [ -z "$worker" ] && continue
    WORKER_PATH="$PRODUCT_DIR/$WORKER_DIR"
    if [ ! -d "$WORKER_PATH" ]; then
      echo "  AVISO: Diretório do worker não encontrado: $WORKER_PATH"
      continue
    fi
    echo "  Deploying worker: $worker"
    cd "$WORKER_PATH"
    if [ -f "package.json" ]; then
      npm ci --silent
    fi
    npx wrangler deploy
    echo "  ✓ Worker deployed: $worker"
  done <<< "$WORKERS"
fi

# ── Verificar health endpoint ─────────────────────────────────────

if [ "$HAS_WORKER" = "true" ] && [ "$DEPLOY_WORKERS" = "true" ]; then
  SUBDOMAIN=$(echo "$PRODUCT" | jq -r '.subdomain')
  echo ""
  echo "→ Verificando health endpoint: https://$SUBDOMAIN/health"
  sleep 5
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time 15 "https://$SUBDOMAIN/health" 2>/dev/null || echo "000")
  echo "  HTTP Status: $HTTP_CODE"
  if [ "$HTTP_CODE" != "200" ]; then
    echo "  AVISO: /health retornou $HTTP_CODE (pode ser propagação DNS)"
  else
    echo "  ✓ Worker respondendo normalmente"
  fi
fi

echo ""
echo "=== Deploy concluído: $REPO_NAME ==="
