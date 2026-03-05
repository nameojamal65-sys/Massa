class VehicleManager:
    def __init__(self):
        self.vehicles = []

    def add_vehicle(self, vehicle_id, model):
        self.vehicles.append({'id': vehicle_id, 'model': model})

    def list_vehicles(self):
        return self.vehicles
