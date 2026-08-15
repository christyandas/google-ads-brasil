# Remove de vez o plugin claude-mem (marketplace thedotmack) do Claude Code no Windows.
#
# Motivo: o claude-mem registra um hook SessionStart que fala com um worker em
# background. Quando o worker morre, o hook sai com erro e o Claude Code bloqueia
# o prompt - "claude-mem worker unreachable for N consecutive hooks".
#
# Uso (PowerShell):
#   powershell -ExecutionPolicy Bypass -File .\scripts\fix-claude-mem.ps1
#
# Idempotente. Faz backup de ~/.claude antes de mexer em qualquer coisa.

$ErrorActionPreference = 'Continue'

if ($env:CLAUDE_CONFIG_DIR) { $C = $env:CLAUDE_CONFIG_DIR }
else { $C = Join-Path $env:USERPROFILE '.claude' }

if (-not (Test-Path $C)) {
  Write-Host "Nao encontrei $C" -ForegroundColor Red
  exit 1
}
Write-Host "==> Config dir: $C" -ForegroundColor Cyan

# 1. Backup ---------------------------------------------------------------
$stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = "$C.bak-$stamp"
Copy-Item -Path $C -Destination $backup -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "==> Backup: $backup" -ForegroundColor Cyan

# 2. Encerrar workers do claude-mem ---------------------------------------
Write-Host '==> Encerrando workers do claude-mem' -ForegroundColor Cyan
$killed = 0
try {
  Get-CimInstance Win32_Process -Filter "Name='node.exe' OR Name='bun.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'claude-mem|worker-service' } |
    ForEach-Object {
      Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
      $killed++
    }
} catch { }
Write-Host "    $killed processo(s) encerrado(s)"

# 3. Desinstalar pela CLI (tolerante a falha) ------------------------------
Write-Host '==> Desinstalando pela CLI' -ForegroundColor Cyan
foreach ($id in @('claude-mem@thedotmack', 'claude-mem')) {
  foreach ($scope in @('user', 'project', 'local')) {
    try { & claude plugin uninstall $id -s $scope -y --keep-data 2>&1 | Out-Null } catch { }
  }
}
try { & claude plugin marketplace remove thedotmack 2>&1 | Out-Null } catch { }
Write-Host '    ok (falhas em escopos inexistentes sao esperadas)'

# 4. Apagar cache e marketplace do disco -----------------------------------
Write-Host '==> Removendo arquivos do plugin' -ForegroundColor Cyan
foreach ($d in @("$C\plugins\cache\thedotmack", "$C\plugins\marketplaces\thedotmack", "$C\plugins\repos\thedotmack")) {
  if (Test-Path $d) {
    Remove-Item -Path $d -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "    removido: $d"
  }
}
Get-ChildItem -Path "$C\plugins\data" -Filter '*claude-mem*' -ErrorAction SilentlyContinue |
  ForEach-Object { Write-Host "    preservado (memorias salvas): $($_.FullName)" }

# 5. Cirurgia nos settings.json --------------------------------------------
Write-Host '==> Limpando settings.json' -ForegroundColor Cyan

$js = @'
const fs = require("fs");
const HIT = /claude-?mem|thedotmack/i;
let touched = 0;
for (const file of process.argv.slice(2)) {
  if (!fs.existsSync(file)) continue;
  let data;
  try { data = JSON.parse(fs.readFileSync(file, "utf8")); }
  catch (e) { console.log("  PULOU (json invalido): " + file); continue; }
  let changed = 0;
  const pruneKeys = (obj) => {
    if (!obj || typeof obj !== "object" || Array.isArray(obj)) return;
    for (const k of Object.keys(obj)) {
      if (HIT.test(k)) { delete obj[k]; changed++; }
      else pruneKeys(obj[k]);
    }
  };
  pruneKeys(data);
  const pruneHooks = (hooks) => {
    if (!hooks || typeof hooks !== "object") return;
    for (const ev of Object.keys(hooks)) {
      if (!Array.isArray(hooks[ev])) continue;
      for (const g of hooks[ev]) {
        if (!g || !Array.isArray(g.hooks)) continue;
        const n = g.hooks.length;
        g.hooks = g.hooks.filter(h => !(h && typeof h.command === "string" && HIT.test(h.command)));
        changed += n - g.hooks.length;
      }
      hooks[ev] = hooks[ev].filter(g => !g || !Array.isArray(g.hooks) || g.hooks.length > 0);
      if (hooks[ev].length === 0) delete hooks[ev];
    }
  };
  pruneHooks(data.hooks);
  for (const v of Object.values(data)) {
    if (v && typeof v === "object" && v.hooks) pruneHooks(v.hooks);
  }
  if (changed > 0) {
    fs.writeFileSync(file, JSON.stringify(data, null, 2) + "\n");
    console.log("  limpo (" + changed + " entrada(s)): " + file);
    touched += changed;
  }
}
console.log(touched > 0 ? "  total removido: " + touched : "  nada encontrado nos settings");
'@

$tmp = Join-Path $env:TEMP 'claude-mem-prune.js'
Set-Content -Path $tmp -Value $js -Encoding UTF8

$targets = @(@(
  "$C\settings.json",
  "$C\settings.local.json",
  "$C\plugins\installed_plugins.json",
  (Join-Path $env:USERPROFILE '.claude.json')
) | Where-Object { Test-Path $_ })

if ($targets.Count -gt 0) { & node $tmp @targets }
Remove-Item $tmp -Force -ErrorAction SilentlyContinue

# 6. Verificacao ------------------------------------------------------------
Write-Host '==> Verificacao' -ForegroundColor Cyan
$left = Select-String -Path $targets -Pattern 'claude-mem|thedotmack' -List -ErrorAction SilentlyContinue
$leftDirs = @("$C\plugins\cache\thedotmack", "$C\plugins\marketplaces\thedotmack") | Where-Object { Test-Path $_ }

if (-not $left -and -not $leftDirs) {
  Write-Host '    limpo: nenhuma referencia ao claude-mem sobrou' -ForegroundColor Green
  Write-Host ''
  Write-Host '==> Pronto. Feche TODAS as janelas do Claude Code e abra de novo.' -ForegroundColor Cyan
} else {
  Write-Host '    ainda ha referencias:' -ForegroundColor Yellow
  $left | ForEach-Object { Write-Host "      $($_.Path)" }
  $leftDirs | ForEach-Object { Write-Host "      $_" }
  Write-Host "    backup em $backup" -ForegroundColor Yellow
  Write-Host '    se o prompt continuar travando, abra com: claude --bare' -ForegroundColor Yellow
  exit 1
}
