import time, json
from .grid import GRID

print("🔱 SOVEREIGN GRID DAEMON ACTIVE")

while True:
    h=GRID.health()
    open("data/health.json","w").write(json.dumps(h,indent=2))
    time.sleep(5)
