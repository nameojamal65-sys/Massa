#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/sovereign_core"
UI="$ROOT/ui/server.py"
OPS="$ROOT/sc_ops"

echo "== Patch Pack v3: Enterprise Ops API + React wiring (Zero-Break) =="

[ -d "$ROOT" ] || { echo "❌ لم أجد $ROOT"; exit 1; }
[ -f "$UI" ] || { echo "❌ لم أجد $UI"; exit 1; }

mkdir -p "$OPS" "$OPS/store"

# ---------------- sc_ops core ----------------
cat > "$OPS/__init__.py" <<'PY'
# Sovereign Enterprise Ops layer (Zero-Break)
PY

cat > "$OPS/flags.py" <<'PY'
import os
def flag(name: str, default: str="0") -> bool:
    return os.getenv(name, default).strip() in ("1","true","True","yes","YES")
SC_OPS_API = flag("SC_OPS_API", "0")   # master switch for /api/ops/*
PY

cat > "$OPS/models.py" <<'PY'
from dataclasses import dataclass, asdict, field
from typing import Any, Dict, List, Optional
import time, uuid

def now_ms() -> int:
    return int(time.time() * 1000)

@dataclass
class Job:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    created_at: int = field(default_factory=now_ms)
    updated_at: int = field(default_factory=now_ms)
    status: str = "queued"        # queued|running|done|failed
    title: str = ""
    request: Dict[str, Any] = field(default_factory=dict)
    result: Dict[str, Any] = field(default_factory=dict)
    error: Optional[str] = None
    correlation_id: Optional[str] = None

    def to_dict(self):
        return asdict(self)

@dataclass
class Approval:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    created_at: int = field(default_factory=now_ms)
    status: str = "pending"       # pending|approved|rejected
    job_id: Optional[str] = None
    reason: str = ""
    payload: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self):
        return asdict(self)

@dataclass
class AuditEvent:
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    ts: int = field(default_factory=now_ms)
    kind: str = "event"
    actor: str = "system"
    job_id: Optional[str] = None
    data: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self):
        return asdict(self)
PY

cat > "$OPS/store/memory.py" <<'PY'
from typing import Dict, List, Optional
from ..models import Job, Approval, AuditEvent, now_ms

class MemoryStore:
    def __init__(self):
        self.jobs: Dict[str, Job] = {}
        self.approvals: Dict[str, Approval] = {}
        self.audit: List[AuditEvent] = []
        self.tenants = {"default": {"id":"default","plan":"rc","quota_daily_jobs":200,"used_jobs_today":0}}

    # ---- jobs ----
    def create_job(self, title: str, request: dict, correlation_id: str) -> Job:
        j = Job(title=title, request=request or {}, correlation_id=correlation_id)
        self.jobs[j.id] = j
        self._audit("job.created", job_id=j.id, data={"title": title})
        self.tenants["default"]["used_jobs_today"] += 1
        return j

    def list_jobs(self) -> List[Job]:
        return sorted(self.jobs.values(), key=lambda x: x.created_at, reverse=True)

    def get_job(self, job_id: str) -> Optional[Job]:
        return self.jobs.get(job_id)

    def update_job_status(self, job_id: str, status: str, result: dict=None, error: str=None):
        j = self.jobs.get(job_id)
        if not j: return None
        j.status = status
        j.updated_at = now_ms()
        if result is not None: j.result = result
        if error is not None: j.error = error
        self._audit("job.updated", job_id=j.id, data={"status": status})
        return j

    # ---- approvals ----
    def create_approval(self, job_id: str, reason: str, payload: dict=None) -> Approval:
        a = Approval(job_id=job_id, reason=reason or "", payload=payload or {})
        self.approvals[a.id] = a
        self._audit("approval.created", job_id=job_id, data={"approval_id": a.id})
        return a

    def list_approvals(self) -> List[Approval]:
        return sorted(self.approvals.values(), key=lambda x: x.created_at, reverse=True)

    def set_approval(self, approval_id: str, status: str):
        a = self.approvals.get(approval_id)
        if not a: return None
        a.status = status
        self._audit("approval.updated", job_id=a.job_id, data={"approval_id": a.id, "status": status})
        return a

    # ---- audit ----
    def _audit(self, kind: str, job_id: str=None, data: dict=None, actor: str="system"):
        self.audit.append(AuditEvent(kind=kind, actor=actor, job_id=job_id, data=data or {}))

    def list_audit(self, limit: int=200) -> List[AuditEvent]:
        return list(reversed(self.audit[-limit:]))

    # ---- quotas/tenants ----
    def get_tenants(self):
        return list(self.tenants.values())

STORE = MemoryStore()
PY

cat > "$OPS/api.py" <<'PY'
from flask import Blueprint, jsonify, request, g, Response
import json, time
from .flags import SC_OPS_API
from .store.memory import STORE

bp = Blueprint("sc_ops", __name__)

def _enabled():
    return SC_OPS_API

def _not_found():
    return jsonify({"ok": False, "error": {"code":"OPS_DISABLED","message":"SC_OPS_API is disabled","details":{}},
                    "correlation_id": getattr(g, "correlation_id", "-")}), 404

@bp.before_request
def _guard():
    if not _enabled():
        return _not_found()

@bp.get("/api/ops/ping")
def ping():
    return jsonify({"ok": True, "service": "sc_ops", "enabled": True})

@bp.get("/api/ops/status")
def ops_status():
    # proxy to existing /api/status semantics would be ideal,
    # but we cannot call internal route safely here; client can still use /api/status.
    # We provide a minimal envelope:
    return jsonify({"ok": True, "hint": "Use /api/status for legacy status. Ops endpoints provide enterprise views."})

@bp.post("/api/ops/jobs")
def create_job():
    payload = request.get_json(force=True, silent=True) or {}
    title = payload.get("title","")
    req = payload.get("request", {})
    cid = getattr(g, "correlation_id", "-")
    j = STORE.create_job(title=title, request=req, correlation_id=cid)
    return jsonify({"ok": True, "job": j.to_dict()})

@bp.get("/api/ops/jobs")
def list_jobs():
    jobs = [j.to_dict() for j in STORE.list_jobs()]
    return jsonify({"ok": True, "jobs": jobs})

@bp.get("/api/ops/jobs/<job_id>")
def get_job(job_id: str):
    j = STORE.get_job(job_id)
    if not j:
        return jsonify({"ok": False, "error": {"code":"NOT_FOUND","message":"job not found","details":{"job_id":job_id}},
                        "correlation_id": getattr(g, "correlation_id", "-")}), 404
    return jsonify({"ok": True, "job": j.to_dict()})

@bp.post("/api/ops/approvals")
def create_approval():
    payload = request.get_json(force=True, silent=True) or {}
    job_id = payload.get("job_id")
    reason = payload.get("reason","")
    a = STORE.create_approval(job_id=job_id, reason=reason, payload=payload.get("payload") or {})
    return jsonify({"ok": True, "approval": a.to_dict()})

@bp.get("/api/ops/approvals")
def list_approvals():
    approvals = [a.to_dict() for a in STORE.list_approvals()]
    return jsonify({"ok": True, "approvals": approvals})

@bp.post("/api/ops/approvals/<approval_id>/decision")
def decide(approval_id: str):
    payload = request.get_json(force=True, silent=True) or {}
    status = payload.get("status","").lower()
    if status not in ("approved","rejected"):
        return jsonify({"ok": False, "error": {"code":"BAD_REQUEST","message":"status must be approved|rejected","details":{}},
                        "correlation_id": getattr(g, "correlation_id", "-")}), 400
    a = STORE.set_approval(approval_id, status)
    if not a:
        return jsonify({"ok": False, "error": {"code":"NOT_FOUND","message":"approval not found","details":{"approval_id":approval_id}},
                        "correlation_id": getattr(g, "correlation_id", "-")}), 404
    return jsonify({"ok": True, "approval": a.to_dict()})

@bp.get("/api/ops/audit")
def audit():
    limit = int(request.args.get("limit","200"))
    events = [e.to_dict() for e in STORE.list_audit(limit=limit)]
    return jsonify({"ok": True, "events": events})

@bp.get("/api/ops/tenants")
def tenants():
    return jsonify({"ok": True, "tenants": STORE.get_tenants()})

@bp.get("/api/ops/stream/status")
def stream_status():
    # SSE stream using legacy /api/status fetched client-side is also fine,
    # but here we provide a heartbeat stream for “live” readiness.
    def gen():
        while True:
            data = {"ts": int(time.time()), "ok": True}
            yield f"event: heartbeat\ndata: {json.dumps(data)}\n\n"
            time.sleep(1)
    return Response(gen(), mimetype="text/event-stream")
PY

# ---------------- patch ui/server.py (register blueprint) ----------------
python3 - <<'PY'
import pathlib, re

ui = pathlib.Path.home()/"sovereign_core"/"ui"/"server.py"
txt = ui.read_text(errors="ignore")

if "SC_OPS_BEGIN" in txt:
    print("✅ Ops API already integrated (markers found).")
    raise SystemExit(0)

# Insert after app = Flask(...)
m = re.search(r'^\s*app\s*=\s*Flask\([^\n]*\)\s*$', txt, flags=re.M)
if not m:
    print("❌ لم أجد app = Flask(...) داخل ui/server.py")
    raise SystemExit(1)

insert = r'''
# --- SC_OPS_BEGIN ---
# Enterprise Ops API (Zero-Break) - behind SC_OPS_API=0 by default
try:
    from sc_ops.api import bp as sc_ops_bp
    app.register_blueprint(sc_ops_bp)
except Exception as _e:
    # Ops layer is optional; do not break legacy startup
    pass
# --- SC_OPS_END ---
'''.lstrip("\n")

pos = m.end()
ui.write_text(txt[:pos] + "\n" + insert + txt[pos:])
print("✅ Integrated Ops Blueprint into ui/server.py")
PY

# ---------------- update React pages (if v2 exists) ----------------
DASH="$ROOT/apps/dashboard"
if [ -d "$DASH" ]; then
  echo "== Updating React pages to use /api/ops/* =="
  mkdir -p "$DASH/src/lib" "$DASH/src/pages"

  cat > "$DASH/src/lib/ops.ts" <<'TS'
export async function opsGet(path: string) {
  const r = await fetch(path, { headers: { "X-Client": "dash" } });
  const ct = r.headers.get("content-type") || "";
  if (ct.includes("application/json")) return await r.json();
  return { ok: false, error: { code: "NON_JSON", message: await r.text() } };
}

export async function opsPost(path: string, body: any) {
  const r = await fetch(path, {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-Client": "dash" },
    body: JSON.stringify(body ?? {}),
  });
  const ct = r.headers.get("content-type") || "";
  if (ct.includes("application/json")) return await r.json();
  return { ok: false, error: { code: "NON_JSON", message: await r.text() } };
}
TS

  cat > "$DASH/src/pages/Jobs.tsx" <<'TSX'
import { useEffect, useState } from "react";
import { opsGet, opsPost } from "../lib/ops";

export default function Jobs() {
  const [jobs, setJobs] = useState<any[]>([]);
  const [err, setErr] = useState<string>("");

  const load = async () => {
    const res: any = await opsGet("/api/ops/jobs");
    if (res?.ok) { setErr(""); setJobs(res.jobs || []); }
    else setErr(res?.error?.message || "Ops API disabled. Enable SC_OPS_API=1");
  };

  useEffect(() => { load(); const t = setInterval(load, 2000); return () => clearInterval(t); }, []);

  const create = async () => {
    const res: any = await opsPost("/api/ops/jobs", { title: "RC Job", request: { note: "created from dashboard" } });
    if (res?.ok) load();
    else setErr(res?.error?.message || "create failed");
  };

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>Jobs</h1>
      <p style={{ color: "#666" }}>Enterprise layer: <code>/api/ops/jobs</code> (RC in-memory).</p>

      <button onClick={create} style={{ padding:"10px 12px", borderRadius:12, border:"1px solid #ddd", cursor:"pointer" }}>
        + Create Job
      </button>

      {err && <pre style={{ marginTop: 12, padding: 12, borderRadius: 12, border: "1px solid #fca5a5", background: "#fff1f2" }}>{err}</pre>}

      <div style={{ marginTop: 12, display: "grid", gap: 10 }}>
        {jobs.map((j) => (
          <div key={j.id} style={{ border: "1px solid #eee", borderRadius: 12, padding: 12 }}>
            <div style={{ fontWeight: 700 }}>{j.title || j.id}</div>
            <div style={{ color: "#666" }}>status: {j.status} • created: {j.created_at}</div>
            <pre style={{ margin: "8px 0 0 0" }}>{JSON.stringify(j.request, null, 2)}</pre>
          </div>
        ))}
      </div>
    </div>
  );
}
TSX

  cat > "$DASH/src/pages/Approvals.tsx" <<'TSX'
import { useEffect, useState } from "react";
import { opsGet, opsPost } from "../lib/ops";

export default function Approvals() {
  const [items, setItems] = useState<any[]>([]);
  const [err, setErr] = useState<string>("");

  const load = async () => {
    const res: any = await opsGet("/api/ops/approvals");
    if (res?.ok) { setErr(""); setItems(res.approvals || []); }
    else setErr(res?.error?.message || "Ops API disabled. Enable SC_OPS_API=1");
  };

  useEffect(() => { load(); const t = setInterval(load, 2500); return () => clearInterval(t); }, []);

  const decide = async (id: string, status: "approved" | "rejected") => {
    const res: any = await opsPost(`/api/ops/approvals/${id}/decision`, { status });
    if (res?.ok) load();
    else setErr(res?.error?.message || "decision failed");
  };

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>Approvals (HITL)</h1>
      <p style={{ color: "#666" }}>Enterprise layer: <code>/api/ops/approvals</code>.</p>

      {err && <pre style={{ marginTop: 12, padding: 12, borderRadius: 12, border: "1px solid #fca5a5", background: "#fff1f2" }}>{err}</pre>}

      <div style={{ marginTop: 12, display: "grid", gap: 10 }}>
        {items.map((a) => (
          <div key={a.id} style={{ border: "1px solid #eee", borderRadius: 12, padding: 12 }}>
            <div style={{ fontWeight: 700 }}>{a.reason || "Approval"}</div>
            <div style={{ color: "#666" }}>status: {a.status} • job: {a.job_id || "-"}</div>
            <div style={{ marginTop: 8, display: "flex", gap: 8 }}>
              <button onClick={() => decide(a.id, "approved")} style={{ padding:"8px 10px", borderRadius:12, border:"1px solid #ddd" }}>Approve</button>
              <button onClick={() => decide(a.id, "rejected")} style={{ padding:"8px 10px", borderRadius:12, border:"1px solid #ddd" }}>Reject</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
TSX

  cat > "$DASH/src/pages/Audit.tsx" <<'TSX'
import { useEffect, useState } from "react";
import { opsGet } from "../lib/ops";

export default function Audit() {
  const [events, setEvents] = useState<any[]>([]);
  const [err, setErr] = useState<string>("");

  useEffect(() => {
    let alive = true;
    const load = async () => {
      const res: any = await opsGet("/api/ops/audit?limit=120");
      if (!alive) return;
      if (res?.ok) { setErr(""); setEvents(res.events || []); }
      else setErr(res?.error?.message || "Ops API disabled. Enable SC_OPS_API=1");
    };
    load();
    const t = setInterval(load, 2500);
    return () => { alive = false; clearInterval(t); };
  }, []);

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>Audit</h1>
      <p style={{ color: "#666" }}>Enterprise layer: <code>/api/ops/audit</code> (RC).</p>
      {err && <pre style={{ marginTop: 12, padding: 12, borderRadius: 12, border: "1px solid #fca5a5", background: "#fff1f2" }}>{err}</pre>}
      <div style={{ marginTop: 12, border: "1px solid #eee", borderRadius: 12, padding: 12 }}>
        <pre style={{ margin: 0 }}>{JSON.stringify(events, null, 2)}</pre>
      </div>
    </div>
  );
}
TSX

  cat > "$DASH/src/pages/Quotas.tsx" <<'TSX'
import { useEffect, useState } from "react";
import { opsGet } from "../lib/ops";

export default function Quotas() {
  const [tenants, setTenants] = useState<any[]>([]);
  const [err, setErr] = useState<string>("");

  useEffect(() => {
    const load = async () => {
      const res: any = await opsGet("/api/ops/tenants");
      if (res?.ok) { setErr(""); setTenants(res.tenants || []); }
      else setErr(res?.error?.message || "Ops API disabled. Enable SC_OPS_API=1");
    };
    load();
    const t = setInterval(load, 5000);
    return () => clearInterval(t);
  }, []);

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>Quotas / Tenants</h1>
      <p style={{ color: "#666" }}>Enterprise layer: <code>/api/ops/tenants</code> (RC in-memory).</p>
      {err && <pre style={{ marginTop: 12, padding: 12, borderRadius: 12, border: "1px solid #fca5a5", background: "#fff1f2" }}>{err}</pre>}
      <div style={{ marginTop: 12, display: "grid", gap: 10 }}>
        {tenants.map((t) => (
          <div key={t.id} style={{ border:"1px solid #eee", borderRadius:12, padding:12 }}>
            <div style={{ fontWeight:700 }}>{t.id}</div>
            <div style={{ color:"#666" }}>plan: {t.plan} • daily_jobs: {t.quota_daily_jobs} • used_today: {t.used_jobs_today}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
TSX

  echo "== Rebuild dashboard and deploy to ui/static/dash =="
  cd "$DASH"
  npm run build >/dev/null
  rm -rf "$ROOT/ui/static/dash"
  mkdir -p "$ROOT/ui/static/dash"
  cp -r dist/* "$ROOT/ui/static/dash/"
fi

echo ""
echo "✅ v3 installed."
echo "Enable Ops API (enterprise endpoints):"
echo "  export SC_OPS_API=1"
echo ""
echo "Test endpoints:"
echo "  curl -s http://127.0.0.1:8080/api/ops/ping"
echo "  curl -s http://127.0.0.1:8080/api/ops/jobs"
echo ""
echo "Dashboard:"
echo "  export SC_NEW_UI=1"
echo "  open http://127.0.0.1:8080/dash/"
