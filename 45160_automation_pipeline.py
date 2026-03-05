from agents.automation_agent import AutomationAgent


class AutomationPipeline:
    def run(self, task: dict):
        prompt = task.get("prompt", "")
        cmd = prompt
        if "run " in prompt.lower():
            cmd = prompt.split("run ", 1)[1]
        return AutomationAgent().run(cmd)
