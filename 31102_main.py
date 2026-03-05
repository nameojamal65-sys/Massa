class SovereignCore:
    def __init__(self):
        self.state = "BOOTING"

    def boot(self):
        self.state = "ONLINE"
        print("🚀 Sovereign Core Autonomous System ONLINE")

    def status(self):
        return self.state
