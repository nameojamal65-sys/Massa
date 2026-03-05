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

log "System fingerprint..."
uname -a > "$BASE/system/uname.txt"
id > "$BASE/system/identity.txt"
termux-info > "$BASE/system/termux.txt" 2>/dev/null || true
getprop > "$BASE/system/android_props.txt" 2>/dev/null || true

log "Environment dump..."
env | sort > "$BASE/env/env.txt"

log "Deep project tree scan..."
find "$HOME" -maxdepth 7 -type d > "$BASE/tree/dirs.txt"
find "$HOME" -maxdepth 7 -type f > "$BASE/tree/files.txt"

log "Indexing source files..."
find "$HOME" -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.sh" -o -name "*.php" -o -name "*.java" -o -name "*.dart" \) \
  > "$BASE/source/index.txt"

log "Extracting API endpoints..."
grep -RniE "FastAPI|Flask|@app\.|express\(|router\.|app\.route|createServer|http\.Server" "$HOME" \
  > "$BASE/api/endpoints.txt" 2>/dev/null || true

log "Detecting databases..."
grep -RniE "sqlite|postgres|mysql|mongo|redis|sqlalchemy|psycopg2|pymongo|mongoose|prisma" "$HOME" \
  > "$BASE/db/databases.txt" 2>/dev/null || true

log "Detecting engines / cores / agents..."
grep -RniE "engine|core|orchestrator|agent|pipeline|model|ai|autonomous|sovereign" "$HOME" \
  > "$BASE/engines/engines.txt" 2>/dev/null || true

log "Scanning infra..."
find "$HOME" \( -iname "*docker*" -o -iname "*compose*" -o -iname "*k8s*" -o -iname "*terraform*" \) \
  > "$BASE/infra/infra_files.txt" 2>/dev/null || true

log "Network snapshot..."
ss -tulpan > "$BASE/net/ports.txt" 2>/dev/null || netstat -tulpan > "$BASE/net/ports.txt" 2>/dev/null || true
ip addr > "$BASE/net/ip.txt" 2>/dev/null || true
ip route > "$BASE/net/routes.txt" 2>/dev/null || true

log "Process intelligence..."
ps aux > "$BASE/proc/processes.txt"

log "Packages snapshot..."
pip list > "$BASE/stats/python_packages.txt" 2>/dev/null || true
npm list -g --depth=0 > "$BASE/stats/node_packages.txt" 2>/dev/null || true

log "Resource snapshot..."
df -h > "$BASE/stats/storage.txt"
free -h > "$BASE/stats/memory.txt" 2>/dev/null || true
top -bn1 | head -n 30 > "$BASE/stats/cpu.txt" 2>/dev/null || true

log "Generating architecture map..."
cat > "$BASE/report/ARCHITECTURE_MAP.txt" <<EOM
SOVEREIGN ULTRA — ARCHITECTURE MAP

LAYERS:
- UI / Dashboard
- API Gateway
- Orchestration & Agents
- AI Core
- Data Layer
- Security / Zero Trust
- Infra / Hybrid Cloud

FLOW:
Client -> UI -> API -> Orchestrator -> Agents -> Data -> Security -> Response

Generated @ $TS
EOM

log "Executive summary..."
cat > "$BASE/report/EXEC_SUMMARY.txt" <<EOM
SUMMARY

Dirs: $(wc -l < "$BASE/tree/dirs.txt")
Files: $(wc -l < "$BASE/tree/files.txt")
Source Files: $(wc -l < "$BASE/source/index.txt")
Endpoints: $(wc -l < "$BASE/api/endpoints.txt")
DB Hits: $(wc -l < "$BASE/db/databases.txt")
Engine Hits: $(wc -l < "$BASE/engines/engines.txt")
Infra Files: $(wc -l < "$BASE/infra/infra_files.txt")

Generated @ $TS
EOM

log "Building source artifact..."
tar -czf "$BASE/artifacts/source_bundle.tgz" -T "$BASE/source/index.txt" 2>/dev/null || true

log "Compressing final intelligence pack..."
cd "$HOME"
zip -r "SOVEREIGN_ULTRA_$TS.zip" "$(basename "$BASE")" >/dev/null 2>&1

ok "ULTRA SCAN COMPLETE"
echo ""
echo "📦 OUTPUT:"
echo "$HOME/SOVEREIGN_ULTRA_$TS.zip"
echo ""
echo "☢️ GOD MODE COMPLETE"
