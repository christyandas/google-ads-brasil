#!/usr/bin/env bash
# =====================================================================
# PPC Stack — instalador para Claude Code (macOS / Linux)
# Instala: 17 skills de Google Ads/GMC + servidor MCP gmc-mcp
# As skills sao baixadas dos repositorios originais dos autores.
# Uso: chmod +x install.sh && ./install.sh
# =====================================================================
set -euo pipefail

SKILLS="$HOME/.claude/skills"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "== PPC Stack installer =="

# --- Pre-requisitos ---
for cmd in git claude; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERRO: '$cmd' nao encontrado. Instale antes de continuar." >&2
    exit 1
  fi
done
PIP=""
if command -v pip3 >/dev/null 2>&1; then PIP=pip3
elif command -v pip >/dev/null 2>&1; then PIP=pip
else
  echo "AVISO: pip nao encontrado. Instale Python 3 (brew install python)"
  echo "       e rode este script de novo para a parte do gmc-mcp."
fi

mkdir -p "$SKILLS"

# --- 1. Skill merchant-approval (aprovacao/suspensao GMC, pt-BR) ---
echo
echo "[1/4] merchant-approval..."
git clone -q --depth 1 https://github.com/ablynow1/merchant-approval-skill "$TMP/ma"
if [ ! -d "$SKILLS/merchant-approval" ]; then
  cp -R "$TMP/ma" "$SKILLS/merchant-approval"
  rm -rf "$SKILLS/merchant-approval/.git"
fi

# --- 2. Skills base de Google Ads (Apache-2.0) ---
echo "[2/4] google-ads-skills (5 skills base)..."
git clone -q --depth 1 https://github.com/itallstartedwithaidea/google-ads-skills "$TMP/gas"
for d in "$TMP/gas/skills"/*/; do
  name="$(basename "$d")"
  [ -d "$SKILLS/$name" ] || cp -R "$d" "$SKILLS/$name"
done

# --- 3. Skills PPC selecionadas do claude-googleadsagent ---
# (so as 11 relevantes para PPC; o plugin completo tem ~50 skills fora do tema)
echo "[3/4] 11 skills PPC (pmax, shopping, keywords...)..."
git clone -q --depth 1 https://github.com/itallstartedwithaidea/claude-googleadsagent "$TMP/buddy"
PICKS="pmax-optimization shopping-ads ad-copy-generation keyword-research \
quality-score-optimization budget-optimization conversion-tracking \
audience-targeting remarketing-strategy competitor-analysis landing-page-audit"
for p in $PICKS; do
  [ -d "$SKILLS/$p" ] || cp -R "$TMP/buddy/skills/$p" "$SKILLS/$p"
done

# --- 4. gmc-mcp (servidor MCP do Google Merchant Center, 126 tools) ---
if [ -n "$PIP" ]; then
  echo "[4/4] gmc-mcp (pip install)..."
  "$PIP" install --quiet gmc-mcp
  echo
  echo "Configuracao do Merchant Center (deixe em branco para pular):"
  read -r -p "  ID da conta Merchant Center (10 digitos): " ACCT
  if [ -n "$ACCT" ]; then
    read -r -p "  Caminho do JSON da service account: " KEY
    claude mcp add gmc --scope user -e "GMC_ACCOUNT_ID=$ACCT" -e "GMC_SERVICE_ACCOUNT_KEY=$KEY" -- gmc-mcp run
    echo "  Servidor 'gmc' registrado. Rode tambem (uma vez):"
    echo "  gmc-mcp register-gcp --developer-email SEU@EMAIL.com"
  else
    echo "  Pulado. Veja docs/setup-gmc-mcp.md para configurar depois."
  fi
fi

echo
echo "Pronto! Reinicie o Claude Code para carregar as skills."
echo "Skills instaladas em: $SKILLS"
echo "Nao esqueca dos scripts de protecao em google-ads-scripts/ (ver LEIA-ME.md)."
