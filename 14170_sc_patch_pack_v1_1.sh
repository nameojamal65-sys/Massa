#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="${ROOT:-$HOME/sovereign_core}"
UI="$ROOT/ui/server.py"
REPORT_DIR="$ROOT/logs"
TS="$(date +%Y%m%d_%H%M%S)"
REPORT="$REPORT_DIR/patch_v1_1_$TS.txt"

mkdir -p "$REPORT_DIR"

log(){ echo -e "$*" | tee -a "$REPORT"; }
hr(){ log "\n------------------------------------------------------------\n"; }

log "== Sovereign Patch Pack v1.1 (Import Lock + Docker Lock + Gunicorn) =="
log "Time: $(date)"
log "ROOT: $ROOT"
hr

[ -d "$ROOT" ] || { log "❌ لم أجد $ROOT"; exit 1; }
[ -f "$UI" ]   || { log "❌ لم أجد $UI"; exit 1; }

# ---------------------------------------------------------------------
# 1) Ensure sc_platform exists (should already from v1)
# ---------------------------------------------------------------------
if [ ! -d "$ROOT/sc_platform" ]; then
  log "⚠️  sc_platform غير موجود. هذا الباتش يفترض v1 موجود."
  log "   نفّذ أولًا: bash ~/sc_patch_pack_v1.sh"
  exit 1
fi

# ---------------------------------------------------------------------
# 2) Patch ui/server.py: add Import Lock (sys.path) with markers
#    - We do NOT rely on PYTHONPATH anymore.
# ---------------------------------------------------------------------
log "== Step 1: Patch ui/server.py (Import Lock) =="

python3 - <<'PY'
import pathlib, re

ui = pathlib.Path.home()/"sovereign_core"/"ui"/"server.py"
txt = ui.read_text(errors="ignore")

# If already patched with import lock marker, skip
if "SC_IMPORT_LOCK_BEGIN" in txt:
    print("✅ Import Lock already present (markers found).")
    raise SystemExit(0)

# We insert sys.path fix BEFORE sc_platform imports (inside Release Lock block if present).
# Preferred insertion point: immediately after the line "# --- SC_RELEASE_LOCK_BEGIN ---"
marker = "# --- SC_RELEASE_LOCK_BEGIN ---"
idx = txt.find(marker)
if idx == -1:
    print("❌ لم أجد SC_RELEASE_LOCK_BEGIN داخل ui/server.py. تأكد أنك مطبق v1.")
    raise SystemExit(1)

insert = r'''
# --- SC_IMPORT_LOCK_BEGIN ---
# Ensure project root is on sys.path even when running: python3 ui/server.py
import os as _os, sys as _sys
_sys.path.insert(0, _os.path.dirname(_os.path.dirname(__file__)))
# --- SC_IMPORT_LOCK_END ---
'''.lstrip("\n")

# Insert right AFTER marker line
# Find end-of-line for marker
m = re.search(r'^\s*#\s*---\s*SC_RELEASE_LOCK_BEGIN\s*---\s*$', txt, flags=re.M)
if not m:
    print("❌ لم أستطع تحديد سطر marker بشكل مضبوط.")
    raise SystemExit(1)

pos = m.end()
newtxt = txt[:pos] + "\n" + insert + txt[pos:]

ui.write_text(newtxt)
print("✅ Patched ui/server.py (Import Lock markers inserted).")
PY

log "✅ ui/server.py updated (or already had Import Lock)."
hr

# ---------------------------------------------------------------------
# 3) Docker: make sure entrypoint uses PYTHONPATH=/app
# ---------------------------------------------------------------------
log "== Step 2: Patch Docker prod entrypoint (PYTHONPATH=/app) =="

EP="$ROOT/infra/prod/entrypoint.sh"
if [ -f "$EP" ]; then
  # Replace the final exec line safely
  # We look for "exec python3 /app/ui/server.py" and rewrite it.
  perl -0777 -i -pe 's#exec\s+python3\s+/app/ui/server\.py#exec env PYTHONPATH=/app python3 /app/ui/server.py#g' "$EP" || true
  chmod +x "$EP"
  log "✅ Updated: $EP"
else
  log "⚠️  Not found: $EP (skipping)"
fi

hr

# ---------------------------------------------------------------------
# 4) Optional: provide gunicorn entrypoint script (doesn't break if unused)
# ---------------------------------------------------------------------
log "== Step 3: Add optional Gunicorn runner =="

GUNI="$ROOT/infra/prod/run_gunicorn.sh"
cat > "$GUNI" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

: "${HOST:=0.0.0.0}"
: "${PORT:=8080}"
: "${WORKERS:=1}"

# Ensure imports work even if launched from anywhere
export PYTHONPATH="/app"

# Gunicorn expects a WSGI app object.
# We expose it by importing ui.server and reading "app".
exec gunicorn -w "$WORKERS" -b "$HOST:$PORT" "ui.server:app"
SH
chmod +x "$GUNI"
log "✅ Added: $GUNI"
hr

# ---------------------------------------------------------------------
# 5) Quick local verification (doesn't start server permanently)
# ---------------------------------------------------------------------
log "== Step 4: Verification hints =="

log "1) Termux run (no PYTHONPATH needed now):"
log "   cd $ROOT"
log "   SC_NEW_UI=1 python3 ui/server.py"
log ""
log "2) Docker run (entrypoint already sets PYTHONPATH=/app):"
log "   docker compose -f $ROOT/infra/prod/docker-compose.yml up -d --build"
log ""
log "3) Optional gunicorn inside container (if installed):"
log "   /app/infra/prod/run_gunicorn.sh"
hr

log "✅ Patch Pack v1.1 applied."
log "Report: $REPORT"
