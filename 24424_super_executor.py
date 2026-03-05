import sys, os, json, time

class SuperExecutor:
    def __init__(self, task_name, command):
        self.task_name = task_name
        self.command = command
        self.results = {}
        self.log = []

    def dispatch(self):
        """Determine module and execute"""
        cmd_lower = self.command.lower()
        self.log.append(f"Dispatching command: {self.command}")

        # Vehicle-related commands
        if "vehicle" in cmd_lower:
            from modules.vehicle_module import VehicleModule
            vm = VehicleModule()
            self.results["vehicles"] = vm.run()
        else:
            # Fallback to generic module (auto-create if not exists)
            try:
                from modules.generic_module import GenericModule
            except ImportError:
                # Generate skeleton generic_module.py
                path = os.path.expanduser("$BASE_DIR/modules/generic_module.py")
                with open(path, "w") as f:
                    f.write("class GenericModule:\n")
                    f.write("    def run(self, command):\n")
                    f.write("        print('Executing generic command:', command)\n")
                    f.write("        return {'output': command}\n")
                from modules.generic_module import GenericModule
            gm = GenericModule()
            self.results["generic"] = gm.run(self.command)
        return self.results

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
            "results_summary": {k: len(v) if isinstance(v, list) else "ok" for k, v in self.results.items()}
        }
        data.append(record)
        with open(db_path, "w") as f:
            json.dump(data, f, indent=2)
