#!/usr/bin/env python3
import requests
import time
import os
import json

# رابط المنظومة (تغيير حسب الإعدادات)
STATUS_URL = "http://127.0.0.1:8000/status"

def fetch_status():
    try:
        resp = requests.get(STATUS_URL, timeout=5)
        if resp.status_code == 200:
            return resp.json()
        else:
            return {"error": f"Status code {resp.status_code}"}
    except Exception as e:
        return {"error": str(e)}

def print_status(status):
    print("🦅 Sovereign Hawk Monitoring (الهوم)")
    print("📸 System Snapshot:")
    print(json.dumps(status, indent=2))
    print("="*60)

if __name__ == "__main__":
    while True:
        os.system('clear')
        status = fetch_status()
        print_status(status)
        time.sleep(10)  # تحديث كل 10 ثواني
