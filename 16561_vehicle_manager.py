class VehicleManager:
    def __init__(self):
        self.vehicles = []
        self._next_id = 1
    def next_id(self):
        current_id = self._next_id
        self._next_id += 1
        return current_id
    def add_vehicle(self, vehicle):
        self.vehicles.append(vehicle)
    def get_all_vehicles(self):
        return self.vehicles
