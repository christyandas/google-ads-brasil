# =====================================================================
# PPC Stack — instalador para Claude Code
# Instala: 17 skills de Google Ads/GMC + servidor MCP gmc-mcp
# As skills sao baixadas dos repositorios originais dos autores.
# Uso: abra o PowerShell e rode  .\install.ps1
# =====================================================================

$ErrorActionPreference = "Stop"
$skills = "$env:USERPROFILE\.claude\skills"
$tmp = Join-Path $env:TEMP "ppc-stack-install"

Write-Host "== PPC Stack installer ==" -ForegroundColor Cyan

# --- Pre-requisitos ---
foreach ($cmd in @("git", "claude")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host "ERRO: '$cmd' nao encontrado. Instale antes de continuar." -ForegroundColor Red
        exit 1
    }
}
$hasPython = $null -ne (Get-Command pip -ErrorAction SilentlyContinue)
if (-not $hasPython) {
    Write-Host "AVISO: pip nao encontrado. Instale Python (winget install Python.Python.3.12)" -ForegroundColor Yellow
    Write-Host "       e rode este script de novo para a parte do gmc-mcp." -ForegroundColor Yellow
}

New-Item -ItemType Directory -Force $skills | Out-Null
if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
New-Item -ItemType Directory -Force $tmp | Out-Null

# --- 1. Skill merchant-approval (aprovacao/suspensao GMC, pt-BR) ---
Write-Host "`n[1/4] merchant-approval..." -ForegroundColor Cyan
git clone -q --depth 1 https://github.com/ablynow1/merchant-approval-skill "$tmp\ma"
if (-not (Test-Path "$skills\merchant-approval")) {
    Copy-Item -Recurse "$tmp\ma" "$skills\merchant-approval"
    Remove-Item -Recurse -Force "$skills\merchant-approval\.git"
}

# --- 2. Skills base de Google Ads (Apache-2.0) ---
Write-Host "[2/4] google-ads-skills (5 skills base)..." -ForegroundColor Cyan
git clone -q --depth 1 https://github.com/itallstartedwithaidea/google-ads-skills "$tmp\gas"
Get-ChildItem "$tmp\gas\skills" -Directory | ForEach-Object {
    if (-not (Test-Path "$skills\$($_.Name)")) { Copy-Item -Recurse $_.FullName "$skills\$($_.Name)" }
}

# --- 3. Skills PPC selecionadas do claude-googleadsagent ---
# (so as 11 relevantes para PPC; o plugin completo tem ~50 skills fora do tema)
Write-Host "[3/4] 11 skills PPC (pmax, shopping, keywords...)..." -ForegroundColor Cyan
git clone -q --depth 1 https://github.com/itallstartedwithaidea/claude-googleadsagent "$tmp\buddy"
$picks = @("pmax-optimization","shopping-ads","ad-copy-generation","keyword-research",
           "quality-score-optimization","budget-optimization","conversion-tracking",
           "audience-targeting","remarketing-strategy","competitor-analysis","landing-page-audit")
foreach ($p in $picks) {
    if (-not (Test-Path "$skills\$p")) { Copy-Item -Recurse "$tmp\buddy\skills\$p" "$skills\$p" }
}

# --- 4. gmc-mcp (servidor MCP do Google Merchant Center, 126 tools) ---
if ($hasPython) {
    Write-Host "[4/4] gmc-mcp (pip install)..." -ForegroundColor Cyan
    pip install --quiet gmc-mcp
    Write-Host "`nConfiguracao do Merchant Center (deixe em branco para pular):" -ForegroundColor Cyan
    $acct = Read-Host "  ID da conta Merchant Center (10 digitos)"
    if ($acct) {
        $key = Read-Host "  Caminho do JSON da service account (ex: C:\...\gmc-sa.json)"
        claude mcp add gmc --scope user -e "GMC_ACCOUNT_ID=$acct" -e "GMC_SERVICE_ACCOUNT_KEY=$key" -- gmc-mcp run
        Write-Host "  Servidor 'gmc' registrado. Rode tambem (uma vez):" -ForegroundColor Green
        Write-Host "  gmc-mcp register-gcp --developer-email SEU@EMAIL.com" -ForegroundColor Green
    } else {
        Write-Host "  Pulado. Veja docs\setup-gmc-mcp.md para configurar depois." -ForegroundColor Yellow
    }
}

Remove-Item -Recurse -Force $tmp
Write-Host "`nPronto! Reinicie o Claude Code para carregar as skills." -ForegroundColor Green
Write-Host "Skills instaladas em: $skills"
Write-Host "Nao esqueca dos scripts de protecao em google-ads-scripts\ (ver LEIA-ME.md)."
