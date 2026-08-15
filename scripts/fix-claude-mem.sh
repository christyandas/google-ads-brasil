#!/usr/bin/env bash
# Remove de vez o plugin claude-mem (marketplace thedotmack) do Claude Code.
#
# Motivo: o claude-mem registra um hook SessionStart que fala com um worker em
# background. Quando o worker morre (PC hiberna, Node atualiza, porta ocupada),
# o hook sai com erro e o Claude Code bloqueia o prompt — "claude-mem worker
# unreachable for N consecutive hooks". Reiniciar o worker resolve por algumas
# horas; remover o plugin resolve para sempre.
#
# Uso:
#   bash scripts/fix-claude-mem.sh              # remove o plugin, preserva as memorias salvas
#   bash scripts/fix-claude-mem.sh --purge-data # remove tambem o diretorio de dados do plugin
#   bash scripts/fix-claude-mem.sh --dry-run    # so mostra o que faria
#
# Idempotente: pode rodar quantas vezes quiser.

set -uo pipefail

PURGE_DATA=0
DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --purge-data) PURGE_DATA=1 ;;
    --dry-run)    DRY_RUN=1 ;;
    -h|--help)    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "opcao desconhecida: $arg" >&2; exit 2 ;;
  esac
done

CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$CONFIG_DIR/backups/fix-claude-mem-$STAMP"

say()  { printf '\033[1m==>\033[0m %s\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[33m    ! %s\033[0m\n' "$*"; }
run()  { if [ "$DRY_RUN" = 1 ]; then info "[dry-run] $*"; else eval "$@"; fi; }

if [ ! -d "$CONFIG_DIR" ]; then
  echo "Nao encontrei $CONFIG_DIR. Defina CLAUDE_CONFIG_DIR e rode de novo." >&2
  exit 1
fi

say "Config dir: $CONFIG_DIR"

# ---------------------------------------------------------------------------
# 1. Backup de tudo que vamos tocar
# ---------------------------------------------------------------------------
say "Backup em $BACKUP_DIR"
if [ "$DRY_RUN" = 0 ]; then
  mkdir -p "$BACKUP_DIR"
  for f in "$CONFIG_DIR"/settings.json "$CONFIG_DIR"/settings.local.json \
           "$CONFIG_DIR"/plugins/installed_plugins.json "$HOME"/.claude.json; do
    [ -f "$f" ] && cp "$f" "$BACKUP_DIR/$(echo "${f#$HOME/}" | tr '/' '_' | sed 's/^\.//')"
  done
  info "$(ls -1A "$BACKUP_DIR" 2>/dev/null | wc -l | tr -d ' ') arquivo(s) salvos"
fi

# ---------------------------------------------------------------------------
# 2. Matar qualquer worker do claude-mem ainda rodando (ou zumbi)
# ---------------------------------------------------------------------------
say "Encerrando workers do claude-mem"
if command -v pkill >/dev/null 2>&1; then
  run "pkill -f 'claude-mem.*worker-service' 2>/dev/null || true"
  run "pkill -f 'worker-service.cjs' 2>/dev/null || true"
  info "ok"
else
  warn "pkill indisponivel; se sobrar processo, encerre pelo gerenciador de tarefas"
fi

# ---------------------------------------------------------------------------
# 3. Caminho oficial: CLI do Claude Code (tolerante a falha)
# ---------------------------------------------------------------------------
say "Desinstalando pela CLI"
if command -v claude >/dev/null 2>&1; then
  keep_flag=""; [ "$PURGE_DATA" = 0 ] && keep_flag="--keep-data"
  for id in claude-mem@thedotmack claude-mem; do
    for scope in user project local; do
      run "claude plugin uninstall '$id' -s '$scope' -y $keep_flag >/dev/null 2>&1 || true"
    done
  done
  run "claude plugin marketplace remove thedotmack >/dev/null 2>&1 || true"
  info "comandos executados (falhas sao esperadas para escopos onde nao existia)"
else
  warn "CLI 'claude' nao esta no PATH; seguindo apenas com a limpeza manual"
fi

# ---------------------------------------------------------------------------
# 4. Limpeza de disco: cache do plugin e marketplace
# ---------------------------------------------------------------------------
say "Removendo arquivos do plugin"
for d in "$CONFIG_DIR/plugins/cache/thedotmack" \
         "$CONFIG_DIR/plugins/marketplaces/thedotmack" \
         "$CONFIG_DIR/plugins/repos/thedotmack"; do
  if [ -e "$d" ]; then
    run "rm -rf '$d'"
    [ "$DRY_RUN" = 0 ] && info "removido: $d"
  fi
done

if [ "$PURGE_DATA" = 1 ]; then
  for d in "$CONFIG_DIR"/plugins/data/*claude-mem*; do
    [ -e "$d" ] || continue
    run "rm -rf '$d'"
    info "removido (dados): $d"
  done
else
  for d in "$CONFIG_DIR"/plugins/data/*claude-mem*; do
    [ -e "$d" ] || continue
    info "preservado (memorias salvas): $d"
    info "use --purge-data para apagar tambem"
  done
fi

# ---------------------------------------------------------------------------
# 5. Cirurgia no JSON: tirar o plugin, o marketplace e hooks orfaos
# ---------------------------------------------------------------------------
say "Limpando settings.json"

NODE_BIN=""
for c in node nodejs; do command -v "$c" >/dev/null 2>&1 && { NODE_BIN="$c"; break; }; done

if [ -z "$NODE_BIN" ]; then
  warn "node nao encontrado; edite manualmente os arquivos abaixo e apague as entradas com 'claude-mem':"
  grep -rl "claude-mem" "$CONFIG_DIR"/settings*.json "$HOME/.claude.json" 2>/dev/null | sed 's/^/      /'
else
  CANDIDATES="$CONFIG_DIR/settings.json $CONFIG_DIR/settings.local.json $CONFIG_DIR/plugins/installed_plugins.json $HOME/.claude.json"
  [ -d .claude ] && CANDIDATES="$CANDIDATES .claude/settings.json .claude/settings.local.json"

  for f in $CANDIDATES; do
    [ -f "$f" ] || continue
    grep -q -e "claude-mem" -e "thedotmack" "$f" 2>/dev/null || continue

    if [ "$DRY_RUN" = 1 ]; then
      info "[dry-run] limparia $f"
      continue
    fi

    "$NODE_BIN" -e '
      const fs = require("fs");
      const file = process.argv[1];
      const HIT = /claude-?mem|thedotmack/i;
      let data;
      try { data = JSON.parse(fs.readFileSync(file, "utf8")); }
      catch (e) { console.error("    ! JSON invalido, pulando: " + file); process.exit(0); }

      let changed = 0;

      // Remove chaves cujo NOME cita o plugin (enabledPlugins, marketplaces, etc).
      const pruneKeys = (obj) => {
        if (!obj || typeof obj !== "object" || Array.isArray(obj)) return;
        for (const k of Object.keys(obj)) {
          if (HIT.test(k)) { delete obj[k]; changed++; continue; }
          pruneKeys(obj[k]);
        }
      };
      pruneKeys(data);

      // Remove hooks cujo COMANDO chama o plugin, e matchers que ficaram vazios.
      const pruneHooks = (hooks) => {
        if (!hooks || typeof hooks !== "object") return;
        for (const event of Object.keys(hooks)) {
          const entries = hooks[event];
          if (!Array.isArray(entries)) continue;
          for (const entry of entries) {
            if (!entry || !Array.isArray(entry.hooks)) continue;
            const before = entry.hooks.length;
            entry.hooks = entry.hooks.filter(
              (h) => !(h && typeof h.command === "string" && HIT.test(h.command))
            );
            changed += before - entry.hooks.length;
          }
          hooks[event] = entries.filter((e) => !e || !Array.isArray(e.hooks) || e.hooks.length > 0);
          if (hooks[event].length === 0) delete hooks[event];
        }
      };
      pruneHooks(data.hooks);
      for (const v of Object.values(data)) {
        if (v && typeof v === "object" && v.hooks) pruneHooks(v.hooks);
      }

      if (changed > 0) {
        fs.writeFileSync(file, JSON.stringify(data, null, 2) + "\n");
        console.log("    " + changed + " entrada(s) removida(s): " + file);
      } else {
        console.log("    nada a remover: " + file);
      }
    ' "$f"
  done
fi

# ---------------------------------------------------------------------------
# 6. Verificacao final
# ---------------------------------------------------------------------------
if [ "$DRY_RUN" = 1 ]; then
  echo
  say "Dry-run: nada foi alterado. Rode sem --dry-run para aplicar."
  exit 0
fi

say "Verificacao"
LEFT="$(grep -rl -e "claude-mem" -e "thedotmack" \
         "$CONFIG_DIR"/settings*.json \
         "$CONFIG_DIR"/plugins/installed_plugins.json \
         "$HOME"/.claude.json 2>/dev/null)"
LEFT_DIRS="$(ls -d "$CONFIG_DIR"/plugins/cache/thedotmack "$CONFIG_DIR"/plugins/marketplaces/thedotmack 2>/dev/null)"

if [ -z "$LEFT" ] && [ -z "$LEFT_DIRS" ]; then
  printf '\033[32m    limpo: nenhuma referencia ao claude-mem sobrou\033[0m\n'
  echo
  say "Pronto. Feche todas as janelas do Claude Code e abra de novo."
else
  warn "ainda ha referencias:"
  [ -n "$LEFT" ]      && echo "$LEFT"      | sed 's/^/      /'
  [ -n "$LEFT_DIRS" ] && echo "$LEFT_DIRS" | sed 's/^/      /'
  echo
  warn "backup em $BACKUP_DIR"
  warn "se o prompt continuar travando, abra com: claude --bare"
  exit 1
fi
