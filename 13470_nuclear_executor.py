import sys, os, json, time

class NuclearExecutor:
    def __init__(self, task_name, command):
        self.task_name = task_name
        self.command = command
        self.vehicles = []
        self.log = []

    def execute(self):
        self.log.append(f"Executing command: {self.command}")
        # Simple dispatcher example (expandable)
        if "vehicle" in self.command.lower():
            from modules.vehicle_module import VehicleModule
            vm = VehicleModule()
            self.vehicles = vm.run()
        else:
            self.log.append("Generic command executed: " + self.command)
        return self.vehicles

    def save_learning(self):
        db_path = os.path.expanduser("~/PAI6/memory/learning_db.json")
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        if os.path.exists(db_path):
            with open(db_path, "r") as f:
                data = json.load(f)
        else:
            data = []
        record = {
            "task_name": self.task_name,
            "command": self.command,
            "timestamp": int(time.time()),
            "status": "success",
            "vehicles_count": len(self.vehicles)
        }
        data.append(record)
        with open(db_path, "w") as f:
            json.dump(data, f, indent=2)
