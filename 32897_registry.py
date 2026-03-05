class AgentRegistry:
    def __init__(self):
        self.agents = {}
    def register(self, name, agent):
        self.agents[name] = agent
    def list(self):
        return self.agents
