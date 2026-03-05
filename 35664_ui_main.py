def display_vehicles(vehicle_list):
    print("🚗 Vehicle List:")
    for v in vehicle_list:
        print(f"- ID: {v['id']}, Model: {v['model']}")
