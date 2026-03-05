from agents.video_agent import VideoAgent
from tenants.manager import tenant_artifacts, ensure_tenant

class VideoPipeline:
    def run(self, task: dict):
        tenant = task.get("tenant","default")
        ensure_tenant(tenant)
        agent = VideoAgent(tenant_artifacts(tenant))
        res = agent.generate(task.get("prompt"))
        res["tenant"]=tenant
        return res
