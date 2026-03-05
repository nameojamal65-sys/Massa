def display_vehicles(vehicles):
    print("\n🚗 Current Vehicles List:")
    if not vehicles:
        print("No vehicles yet.")
    for v in vehicles:
        print(f"ID: {v['id']} - Name: {v['name']}")
