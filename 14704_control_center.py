class ControlCenter:
    def __init__(self):
        self.agents_status = {}

    def register(self, name):
        self.agents_status[name] = "ACTIVE"

    def stop(self, name):
        self.agents_status[name] = "STOPPED"

    def status(self):
        return self.agents_status

control_center = ControlCenter()
