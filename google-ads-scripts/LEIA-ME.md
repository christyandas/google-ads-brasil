# Scripts Google Ads — instalação e configuração

Scripts revisados (fonte: github.com/itallstartedwithaidea, licença MIT).
Nenhum envia dados para fora da sua conta Google — apenas e-mail para você e planilhas suas.

## Onde colar os 3 primeiros (scripts de Google Ads)

Google Ads → **Ferramentas → Operações em massa → Scripts** → botão **+** → colar o código → Autorizar → agendar.
Instale em **cada conta** que quiser proteger (moeda do limite = moeda da conta).

### 1. anomaly-detection.js — detector de anomalias
- Edite no topo: `SPREADSHEET_URL` (crie uma planilha vazia e cole a URL) e `EMAIL_RECIPIENT`.
- Agendar: **a cada hora**.
- Compara gasto/cliques/conversões de hoje com o histórico e envia alerta por e-mail.

### 2. budget-manager.js — trava de orçamento diário
- Edite `CONFIG`: `BUDGET_THRESHOLD` (teto diário na moeda da conta), `CAMPAIGN_LABEL` (padrão "gaa"), `REENABLE_HOUR` (hora de religar, padrão 6).
- Aplique o rótulo "gaa" nas campanhas que o script pode pausar.
- Agendar: **a cada hora**.
- Quando o gasto do dia da conta passa do teto, pausa os grupos das campanhas rotuladas e religa no dia seguinte. Não mexe no que você pausou manualmente.

### 3. negative-keyword-conflict-resolver.js — conflito de negativas (só Search)
- Edite `CONFIG` no topo (e-mail, modo relatório vs. auto-correção — comece em modo relatório).
- Agendar: **diário**.
- Detecta palavras-negativas que bloqueiam suas próprias keywords ativas.

## 4. out-of-stock-shopify.js — produtos esgotados (Apps Script, NÃO Google Ads)

Versão reescrita (a original do repo não funcionava com Shopify).
- Onde colar: **script.google.com** → Novo projeto.
- Edite `STORES` (domínios das lojas) e `SHEET_ID` (planilha de destino).
- Rode `scanShopifyOutOfStock` uma vez para autorizar, depois `createDailyTrigger`.
- Lista produtos sem nenhuma variante disponível — use para pausar anúncios e evitar
  mismatch de disponibilidade no Merchant Center (Misrepresentation).
- Para lojas COM Merchant Center, o Claude também faz essa checagem sob demanda
  (ferramentas gmc_diff_with_shopify / Shopify MCP) — o script serve como vigia automático.
