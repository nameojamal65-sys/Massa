#!/usr/bin/env python3
"""
Sovereign Ultimate Structured System
واجهة خارقة + AI خارجي + تنظيم الملفات
"""

import os, shutil, threading, time
from flask import Flask, render_template_string, request

# ====== هيكل المنظومة ======
STRUCTURE = ["AI", "Dashboard", "Data", "Analytics", "Other"]
BASE_DIR = "Structured_System"
for folder in STRUCTURE:
    os.makedirs(os.path.join(BASE_DIR, folder), exist_ok=True)

# ====== تصنيف الملفات ======
FILE_CATEGORIES = {
    "AI": ["analyze", "ai", "executor"],
    "Dashboard": ["dashboard", "control", "interface", "app.jsx"],
    "Data": ["collect", "process", "sovereign_data"],
    "Analytics": ["analytics", "report"],
    "Other": []
}

def classify_file(filename):
    fname = filename.lower()
    for category, keywords in FILE_CATEGORIES.items():
        if any(k in fname for k in keywords):
            return category
    return "Other"

def organize_files():
    files = [f for f in os.listdir(".") if f.endswith(".py") or f.endswith(".jsx")]
    for f in files:
        category = classify_file(f)
        shutil.copy(f, os.path.join(BASE_DIR, category, f))
        print(f"📂 تم نسخ {f} إلى {category}")

organize_files()

# ====== واجهة ويب ======
app = Flask(__name__)
HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head><title>Sovereign Dashboard</title></head>
<body>
<h1>🚀 Dashboard</h1>
<button onclick="fetch('/run?cap=AI')">تشغيل AI</button>
<button onclick="fetch('/run?cap=Dashboard')">تشغيل Dashboard</button>
<button onclick="fetch('/run?cap=Data')">تشغيل Data</button>
<button onclick="fetch('/run?cap=Analytics')">تشغيل Analytics</button>
</body></html>
"""

@app.route("/")
def home():
    return render_template_string(HTML_TEMPLATE)

@app.route("/run")
def run_capability():
    cap = request.args.get("cap")
    threading.Thread(target=lambda: print(f"⚡ {cap} تعمل الآن")).start()
    return f"{cap} تعمل الآن!"

def run_dashboard():
    app.run(host="0.0.0.0", port=8080)

threading.Thread(target=run_dashboard, daemon=True).start()

# ====== محاكاة AI خارجي ======
def ai_executor():
    while True:
        print("🤖 AI خارجي يعمل ويصدر توصيات...")
        time.sleep(10)

threading.Thread(target=ai_executor, daemon=True).start()

print("🚀 المنظومة جاهزة على: http://127.0.0.1:8080")

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("🛑 المنظومة توقفت")
