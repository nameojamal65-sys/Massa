import threading
from core.vehicle_manager import VehicleManager
from modules.smart_planner import SmartPlanner
from ui.ui_main import display_vehicles
from core import api_server
if __name__ == "__main__":
    vm = VehicleManager()
    planner = SmartPlanner(vm)
    # Start Smart Planner in background
    threading.Thread(target=planner.start_auto_planning, daemon=True).start()
    # Start API server in background
    threading.Thread(target=api_server.run_api, daemon=True).start()
    # CLI display
    while True:
        display_vehicles(vm.get_all_vehicles())
        input("\nPress Enter to refresh...")
