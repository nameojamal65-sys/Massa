from flask import Flask, jsonify
from core.vehicle_manager import VehicleManager
app = Flask(__name__)
vm = VehicleManager()
@app.route("/vehicles", methods=["GET"])
def get_vehicles():
    return jsonify(vm.get_all_vehicles())
def run_api():
    app.run(host="0.0.0.0", port=5000)
