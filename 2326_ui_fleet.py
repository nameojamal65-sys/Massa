# Fleet UI
def display_fleet(fleet_list):
    print("🚘 Fleet Overview:")
    for v in fleet_list:
        loc = v['location'] if v['location'] else "Unknown"
        print(f"- ID: {v['id']}, Model: {v['model']}, Location: {loc}")
