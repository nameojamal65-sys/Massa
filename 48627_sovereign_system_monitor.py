#!/usr/bin/env python3
import os, psutil, time

THRESHOLD_CPU = 85  # %
THRESHOLD_RAM = 80  # %

def check_system():
    cpu = psutil.cpu_percent(interval=1)
    ram = psutil.virtual_memory().percent
    alerts = []
    if cpu > THRESHOLD_CPU:
        alerts.append(f"⚠️ CPU usage high: {cpu}%")
    if ram > THRESHOLD_RAM:
        alerts.append(f"⚠️ RAM usage high: {ram}%")
    return alerts

def main():
    print("🚀 System Monitor Running...")
    while True:
        alerts = check_system()
        if alerts:
            for a in alerts:
                print(a)
        time.sleep(10)

if __name__ == "__main__":
    main()
