class Orchestrator:
    def __init__(self):
        self.agents = {}

    def register(self, agent):
        self.agents[agent.name] = agent

    def start(self, name):
        if name in self.agents:
            self.agents[name].start()

    def stop(self, name):
        if name in self.agents:
            self.agents[name].stop()

    def list_agents(self):
        return {
            name: agent.status()
            for name, agent in self.agents.items()
        }
