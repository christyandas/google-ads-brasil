/**
 * Out-of-Stock Scanner para lojas Shopify (Google Apps Script)
 *
 * Lê o endpoint público /products.json de cada loja, encontra produtos
 * sem nenhuma variante disponível e grava numa planilha Google.
 * Use a lista para pausar anúncios / corrigir o feed antes que o GMC
 * detecte mismatch de disponibilidade (risco de Misrepresentation).
 *
 * Setup:
 * 1. script.google.com -> Novo projeto -> cole este arquivo.
 * 2. Preencha STORES e SHEET_ID abaixo.
 * 3. Rode uma vez para autorizar; depois execute createDailyTrigger().
 */

var STORES = [
  // 'https://sualoja.com'  (domínio da loja Shopify, sem barra no final)
];
var SHEET_ID = 'YOUR_SHEET_ID'; // ID da planilha Google de destino
var SHEET_NAME = 'OutOfStock';
var PAGE_LIMIT = 250; // máximo da API

function scanShopifyOutOfStock() {
  var results = [];
  STORES.forEach(function (store) {
    var page = 1;
    while (true) {
      var url = store + '/products.json?limit=' + PAGE_LIMIT + '&page=' + page;
      var resp = UrlFetchApp.fetch(url, { muteHttpExceptions: true });
      if (resp.getResponseCode() !== 200) break;
      var products = JSON.parse(resp.getContentText()).products || [];
      if (products.length === 0) break;
      products.forEach(function (p) {
        var anyAvailable = (p.variants || []).some(function (v) { return v.available; });
        if (!anyAvailable) {
          results.push([store, p.title, p.handle, store + '/products/' + p.handle,
                        new Date()]);
        }
      });
      if (products.length < PAGE_LIMIT) break;
      page++;
    }
  });

  var sheet = SpreadsheetApp.openById(SHEET_ID).getSheetByName(SHEET_NAME) ||
              SpreadsheetApp.openById(SHEET_ID).insertSheet(SHEET_NAME);
  sheet.clear();
  sheet.appendRow(['Loja', 'Produto', 'Handle', 'URL', 'Verificado em']);
  results.forEach(function (r) { sheet.appendRow(r); });
  Logger.log(results.length + ' produtos esgotados encontrados.');
}

function createDailyTrigger() {
  ScriptApp.newTrigger('scanShopifyOutOfStock').timeBased().everyHours(6).create();
}
