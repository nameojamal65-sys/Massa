import os, json
from agents.code_agent import CodeAgent
from tenants.manager import tenant_artifacts, ensure_tenant
from core.logger import log

class CodePipeline:
    def run(self, task: dict):
        tenant = task.get("tenant","default")
        ensure_tenant(tenant)
        adir = tenant_artifacts(tenant)
        agent = CodeAgent()
        res = agent.generate(task.get("prompt"))
        path = os.path.join(adir, "generated_code.py")
        with open(path,"w",encoding="utf-8") as f:
            f.write(res["code"])
        log(f"CodePipeline wrote {path} tenant={tenant}")
        res["artifact"]=path
        res["tenant"]=tenant
        return res
