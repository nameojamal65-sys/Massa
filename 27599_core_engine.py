import json
from core.logger import log
from core.parser import parse_command
from core.human_gate import require_human_approval
from security.rbac import authorize
from platform_services.identity import require_token
from policy.engine import is_denied, is_allowed, diffusion_requires_admin
from commercial.quota import check
from platform_services.audit_chain import append
from security.signing import verify

from orchestrator.task_manager import TaskManager

def _action_for(task_type: str):
    return {
      "code": "run_code",
      "video": "run_video",
      "voice": "run_voice",
      "automation": "run_automation",
    }.get(task_type, "unknown")

class SovereignCoreEngine:
    def __init__(self):
        self.running = False
        self.tm = TaskManager()

    def start(self, role="operator"):
        if not authorize(role,"start"):
            return {"status":"blocked","reason":"rbac"}
        self.running = True
        log("Engine started")
        append({"type":"engine_start","role":role})
        return {"status":"started"}

    def stop(self, role="operator"):
        if not authorize(role,"stop"):
            return {"status":"blocked","reason":"rbac"}
        self.running = False
        log("Engine stopped")
        append({"type":"engine_stop","role":role})
        return {"status":"stopped"}

    def restart(self, role="operator"):
        if not authorize(role,"restart"):
            return {"status":"blocked","reason":"rbac"}
        self.stop(role=role)
        return self.start(role=role)

    def handle(self, command: str, token: str, signature: str|None=None):
        # 1) Auth
        ident = require_token(token)
        role = ident.get("role","operator")
        user = ident.get("user","unknown")

        if not authorize(role,"submit"):
            return {"status":"blocked","reason":"rbac"}

        task = parse_command(command)
        task_type = task.get("type")
        tenant = task.get("tenant","default")
        prompt = task.get("prompt","")

        # 2) Signed jobs (platform requires signature on submit)
        payload_str = json.dumps({"tenant":tenant,"type":task_type,"prompt":prompt}, ensure_ascii=False, sort_keys=True)
        if signature is None or not verify(payload_str, signature):
            return {"status":"blocked","reason":"invalid_signature","hint":"use CLI/SDK which signs requests"}

        action = _action_for(task_type)

        # 3) Policy
        if is_denied("external_communication") and task_type == "automation":
            return {"status":"blocked","reason":"policy_external_disabled"}
        if not is_allowed(action, role):
            return {"status":"blocked","reason":"policy_or_role"}

        # diffusion admin gate
        if task_type == "video" and diffusion_requires_admin():
            if ("diffusion" in prompt.lower() or "cinematic" in prompt.lower() or "سينمائي" in prompt):
                if role != "admin":
                    return {"status":"blocked","reason":"diffusion_requires_admin"}

        # 4) Quota (per-tenant plan)
        # Determine plan from identity tenants table if exists; default free
        plan = "free"
        ok, meta = check(tenant, plan, kind=("gpu" if ("diffusion" in prompt.lower() or "cinematic" in prompt.lower() or "سينمائي" in prompt) else "job"))
        if not ok:
            return {"status":"blocked","reason":"quota_exceeded","meta":meta}

        # 5) HITL
        if not require_human_approval(task, role=role):
            append({"type":"task_blocked_hitl","user":user,"role":role,"tenant":tenant,"task":task})
            return {"status":"blocked","reason":"HITL"}

        # 6) Accept
        tid = self.tm.create(task)
        append({"type":"task_accepted","id":tid,"user":user,"role":role,"tenant":tenant,"task":task})
        log(f"Accepted task {tid} by {user}/{role} tenant={tenant}")
        return {"status":"accepted","task_id":tid,"task":task, "role": role, "user": user}
