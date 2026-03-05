import random
import time
from core.vehicle_manager import VehicleManager

class SmartPlanner:
    def __init__(self, vm: VehicleManager):
        self.vm = vm

    def auto_add_vehicle(self):
        models = ["Tesla Model 3", "BMW i4", "Audi e-tron", "Mercedes EQC"]
        new_vehicle = {"id": self.vm.next_id(), "name": random.choice(models)}
        self.vm.add_vehicle(new_vehicle)
        print(f"🟢 Added Vehicle: {new_vehicle}")
        return new_vehicle

    def start_auto_planning(self, interval_sec=10):
        while True:
            self.auto_add_vehicle()
            time.sleep(interval_sec)
