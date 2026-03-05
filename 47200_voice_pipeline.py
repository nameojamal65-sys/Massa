from agents.voice_agent import VoiceAgent
from tenants.manager import tenant_artifacts, ensure_tenant

class VoicePipeline:
    def run(self, task: dict):
        tenant = task.get("tenant","default")
        ensure_tenant(tenant)
        agent = VoiceAgent(tenant_artifacts(tenant))
        res = agent.tts(task.get("prompt"))
        res["tenant"]=tenant
        return res
