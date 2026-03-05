class VehicleModule:
    def run(self):
        vehicles = [
            {"id": "V001", "model": "Tesla Model S"},
            {"id": "V002", "model": "BMW i8"},
            {"id": "V003", "model": "Audi e-tron"},
            {"id": "V004", "model": "Mercedes EQC"}
        ]
        print("🚗 Vehicle List:")
        for v in vehicles:
            print(f"- ID: {v['id']}, Model: {v['model']}")
        return vehicles
