#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "☢️  SOVEREIGN ULTRA MASTER SCANNER — GOD MODE"
echo "======================================================"
echo "MODE: FULL AUTONOMOUS INTELLIGENCE EXTRACTION + PACK"
echo "======================================================"
echo ""

TS=$(date +%Y%m%d_%H%M%S)
BASE="$HOME/sovereign_ultra_$TS"
mkdir -p "$BASE"/{system,tree,source,api,db,engines,infra,net,proc,env,stats,report,artifacts}

log(){ echo -e "⚙️  $1"; }
ok(){ echo -e "   ✅ $1"; }
warn(){ echo -e "   ⚠️ $1"; }

# ---------- SYSTEM ----------
log "System fingerprint..."
uname -a > "$BASE/system/uname.txt"
id > "$BASE/system/identity.txt"
termux-info > "$BASE/system/termux.txt" 2>/dev/null || true
getprop > "$BASE/system/android_props.txt" 2>/dev/null || true

# ---------- ENV ----------
log "Environment dump..."
env | sort > "$BASE/env/env.txt"

# ---------- TREE ----------
log "Deep project tree scan..."
find "$HOME" -maxdepth 7 -type d > "$BASE/tree/dirs.txt"
find "$HOME" -maxdepth 7 -type f > "$BASE/tree/files.txt"

# ---------- SOURCE ----------
log "Indexing source files..."
find "$HOME" -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.sh" -o -name "*.php" -o -name "*.java" -o -name "*.dart" \) \
  > "$BASE/source/index.txt"

# ---------- API / ENDPOINTS ----------
log "Extracting API endpoints..."
grep -RniE "FastAPI|Flask|@app\.|express\(|router\.|app\.route|createServer|http\.Server" "$HOME" \
  > "$BASE/api/endpoints.txt" 2>/dev/null || true

# ---------- DATABASE ----------
log "Detecting databases..."
grep -RniE "sqlite|postgres|mysql|mongo|redis|sqlalchemy|psycopg2|pymongo|mongoose|prisma" "$HOME" \
  > "$BASE/db/databases.txt" 2>/dev/null || true

# ---------- ENGINES ----------
log "Detecting engines / cores / agents..."
grep -RniE "engine|core|orchestrator|agent|pipeline|model|ai|autonomous|sovereign" "$HOME" \
  > "$BASE/engines/engines.txt" 2>/dev/null || true

# ---------- INFRA ----------
log "Scanning infra (Docker, Compose, K8s)..."
find "$HOME" \( -iname "*docker*" -o -iname "*compose*" -o -iname "*k8s*" -o -iname "*terraform*" \) \
  > "$BASE/infra/infra_files.txt" 2>/dev/null || true

# ---------- NETWORK ----------
log "Ports & sockets..."
ss -tulpan > "$BASE/net/ports.txt" 2>/dev/null || netstat -tulpan > "$BASE/net/ports.txt" 2>/dev/null || true
ip addr > "$BASE/net/ip.txt" 2>/dev/null || true
ip route > "$BASE/net/routes.txt" 2>/dev/null || true

# ---------- PROCESSES ----------
log "Process intelligence..."
ps aux > "$BASE/proc/processes.txt"

# ---------- PACKAGES ----------
log "Python packages..."
pip list > "$BASE/stats/python_packages.txt" 2>/dev/null || true
log "Node packages..."
npm list -g --depth=0 > "$BASE/stats/node_packages.txt" 2>/dev/null || true

# ---------- RESOURCES ----------
log "Resource snapshots..."
df -h > "$BASE/stats/storage.txt"
free -h > "$BASE/stats/memory.txt" 2>/dev/null || true
top -bn1 | head -n 30 > "$BASE/stats/cpu.txt" 2>/dev/null || true

# ---------- ARCH MAP ----------
log "Generating architecture map..."
cat > "$BASE/report/ARCHITECTURE_MAP.txt" <<EOF
SOVEREIGN ULTRA — ARCHITECTURE MAP

LAYERS:
- UI / Dashboard
- API Gateway
- Orchestration & Agents
- AIigid AI Core
- Data Layer
- Security / Zero Trust
- Infra / Hybrid Cloud

FLOWS:
Client -> UI -> API -> Orchestrator -> Agents -> Data -> Security -> Response

STATUS:
Auto-generated snapshot @ $TS
EOF

# ---------- INTEL SUMMARY ----------
log "Building executive summary..."
cat > "$BASE/report/EXEC_SUMMARY.txt" <<EOF
SOVEREIGN ULTRA INTELLIGENCE SUMMARY

Tree:
  Dirs: $(wc -l < "$BASE/tree/dirs.txt")
  Files: $(wc -l < "$BASE/tree/files.txt")

Source:
  Files: $(wc -l < "$BASE/source/index.txt")

Endpoints:
  Count: $(wc -l < "$BASE/api/endpoints.txt")

Databases:
  Hits: $(wc -l < "$BASE/db/databases.txt")

Engines:
  Hits: $(wc -l < "$BASE/engines/engines.txt")

Infra:
  Files: $(wc -l < "$BASE/infra/infra_files.txt")

Generated @ $TS
EOF

# ---------- ARTIFACT PACK ----------
log "Building artifacts bundle..."
tar -czf "$BASE/artifacts/source_bundle.tgz" -T "$BASE/source/index.txt" 2>/dev/null || true

# ---------- FINAL ZIP ----------
log "Compressing full intelligence pack..."
cd "$HOME"
zip -r "SOVEREIGN_ULTRA_$TS.zip" "$(basename "$BASE")" >/dev/null 2>&1

ok "ULTRA SCAN COMPLETE"
echo ""
echo "📦 OUTPUT:"
echo "$HOME/SOVEREIGN_ULTRA_$TS.zip"
echo ""
echo "☢️ GOD MODE COMPLETE"
