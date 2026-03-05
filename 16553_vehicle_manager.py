# تحديث VehicleManager لإضافة دعم Fleet
from fleet.fleet_manager import FleetManager

class VehicleManager:
    def __init__(self):
        self.vehicles = []
        self.fleet_manager = FleetManager()

    def add_vehicle(self, vehicle_id, model, location=None):
        self.vehicles.append({'id': vehicle_id, 'model': model})
        self.fleet_manager.add_vehicle(vehicle_id, model, location)

    def list_vehicles(self):
        return self.vehicles

    def list_fleet(self):
        return self.fleet_manager.list_fleet()
