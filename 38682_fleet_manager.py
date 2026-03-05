# Fleet Management Core
class FleetManager:
    def __init__(self):
        self.fleet = []

    def add_vehicle(self, vehicle_id, model, location=None):
        self.fleet.append({'id': vehicle_id, 'model': model, 'location': location})

    def list_fleet(self):
        return self.fleet
