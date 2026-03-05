import time
from legendary.utils.queue import pop_task

print("🛰 Legendary Worker V11 Termux started...")

TENANTS = ("global",)

while True:
    for tenant in TENANTS:
        task = pop_task(tenant)
        if task:
            print(f"🔥 Processing task for {tenant}: {task.decode()}")
    time.sleep(2)
