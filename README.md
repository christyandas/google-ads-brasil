# PPC Stack para Claude Code

Setup completo de Google Ads + Google Merchant Center para Claude Code:
**17 skills de PPC/GMC**, o servidor MCP **gmc-mcp** (126 ferramentas do Merchant
Center) e **4 scripts de proteção** para colar no Google Ads.

Montado para operações de e-commerce com Search, PMax e Demand Gen (EU/US),
lojas Shopify com e sem Merchant Center.

## Instalação

Pré-requisitos: [Claude Code](https://claude.com/claude-code), Git e Python 3.10+
(Windows: `winget install Python.Python.3.12` · Mac: `brew install python`).

**Mac / Linux:**
```bash
git clone <URL-DESTE-REPO>
cd ppc-stack
chmod +x install.sh && ./install.sh
```

**Windows (PowerShell):**
```powershell
git clone <URL-DESTE-REPO>
cd ppc-stack
.\install.ps1
```

O instalador baixa as skills **direto dos repositórios originais dos autores**
(nada é redistribuído aqui — só automação de instalação) e registra o servidor
MCP. Depois, reinicie o Claude Code.

## O que é instalado

| Componente | Fonte | Licença |
|---|---|---|
| 5 skills base (analysis, audit, math, mcp, write) | [google-ads-skills](https://github.com/itallstartedwithaidea/google-ads-skills) | Apache-2.0 |
| 11 skills PPC (pmax, shopping, keywords, QS, budget, conversão, audiências, remarketing, concorrência, landing pages, ad copy) | [claude-googleadsagent](https://github.com/itallstartedwithaidea/claude-googleadsagent) | ver repo |
| merchant-approval (aprovação/suspensão GMC, pt-BR) | [merchant-approval-skill](https://github.com/ablynow1/merchant-approval-skill) | ver repo |
| gmc-mcp — 126 tools do Merchant Center | [PyPI](https://pypi.org/project/gmc-mcp/) / [repo](https://github.com/kiwoongeom/gmc-mcp) | MIT |
| 4 scripts de proteção (pasta `google-ads-scripts/`) | MIT + original | MIT |

## Configurar o Merchant Center (gmc-mcp)

Cada pessoa usa **suas próprias credenciais** — veja o passo a passo completo em
[docs/setup-gmc-mcp.md](docs/setup-gmc-mcp.md) (service account no Google Cloud,
acesso Admin no Merchant Center, registro na API).

## Scripts de proteção (`google-ads-scripts/`)

Não são instalados na máquina — são colados no painel do Google Ads
(Ferramentas → Scripts) e no script.google.com. Instruções em
[google-ads-scripts/LEIA-ME.md](google-ads-scripts/LEIA-ME.md):

- `anomaly-detection.js` — alerta de anomalias de gasto/performance por e-mail
- `budget-manager.js` — trava de orçamento diário por rótulo de campanha
- `negative-keyword-conflict-resolver.js` — negativas bloqueando suas keywords (Search)
- `out-of-stock-shopify.js` — vigia de produtos esgotados em lojas Shopify
  (evita mismatch de disponibilidade no GMC / Misrepresentation)

## Primeiro uso

Depois de reiniciar o Claude Code, experimente:

- *"audita minha conta GMC"* — issues, produtos desaprovados, checklist de políticas
- *"analisa a estrutura das minhas campanhas PMax"*
- *"cruza o estoque da Shopify com o feed do Merchant"*

## Créditos

Skills e scripts de Google Ads por [John Williams](https://github.com/itallstartedwithaidea)
(googleadsagent.ai). Skill merchant-approval por [ablynow1](https://github.com/ablynow1).
Servidor gmc-mcp por [kiwoongeom](https://github.com/kiwoongeom). Curadoria,
instalador e script de out-of-stock desta pasta: originais deste repositório.
