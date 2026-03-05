#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

MASTER="$HOME/tremix_master.py"
TS="$(date +%Y%m%d_%H%M%S)"
BK="$HOME/tremix_master_backup_cluster_${TS}.py"

if [ ! -f "$MASTER" ]; then
  echo "❌ tremix_master.py not found"
  exit 1
fi

cp -f "$MASTER" "$BK"
echo "🧷 Backup: $BK"

python3 - <<'PY'
import os
path = os.path.expanduser("~/tremix_master.py")
src = open(path, "r", encoding="utf-8", errors="ignore").read()

CLUSTER_BLOCK = r'''
# ================= CLUSTER MODE =================
CLUSTER_NODES_FILE = os.path.join(BASE_DIR, "cluster_nodes.json")

def load_cluster_nodes():
    return load_json(CLUSTER_NODES_FILE, {})

def save_cluster_nodes(nodes):
    save_json(CLUSTER_NODES_FILE, nodes)

def register_node(node_id, role="worker"):
    nodes = load_cluster_nodes()
    nodes[node_id] = {
        "role": role,
        "last_heartbeat": datetime.now().isoformat()
    }
    save_cluster_nodes(nodes)

def heartbeat(node_id):
    nodes = load_cluster_nodes()
    if node_id in nodes:
        nodes[node_id]["last_heartbeat"] = datetime.now().isoformat()
        save_cluster_nodes(nodes)

def active_workers():
    nodes = load_cluster_nodes()
    active = []
    for nid, info in nodes.items():
        try:
            last = datetime.fromisoformat(info["last_heartbeat"])
            if (datetime.now() - last).total_seconds() < 15:
                if info.get("role") == "worker":
                    active.append(nid)
        except:
            pass
    return active

@app.post("/cluster/register")
def cluster_register(node_id: str = Form(...), role: str = Form(default="worker")):
    register_node(node_id, role)
    return {"ok": True}

@app.post("/cluster/heartbeat")
def cluster_heartbeat(node_id: str = Form(...)):
    heartbeat(node_id)
    return {"ok": True}

@app.get("/cluster/status")
def cluster_status():
    return {
        "nodes": load_cluster_nodes(),
        "active_workers": active_workers()
    }

def distribute_task(task):
    workers = active_workers()
    if not workers:
        return False
    # Simple round-robin simulation
    target = workers[0]
    task["assigned_to"] = target
    return True
'''

if "CLUSTER MODE" not in src:
    src += "\n\n" + CLUSTER_BLOCK

open(path, "w").write(src)
print("OK")
PY

echo "✅ Cluster mode added."
echo "🔁 Restart dashboard:"
echo "  pkill -f tremix_master.py"
echo "  python3 ~/tremix_master.py dashboard"
