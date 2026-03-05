import os, datetime, stat
from flask import Flask, jsonify, request

BASE_PATH = os.path.dirname(__file__)
OUTPUT_PATH = os.path.join(BASE_PATH, "output")
LOGS_PATH = os.path.join(BASE_PATH, "logs")
PLATFORMS = ["apk", "web", "windows"]

for path in [OUTPUT_PATH, LOGS_PATH]:
    for p in PLATFORMS:
        os.makedirs(os.path.join(path, p), exist_ok=True)

def log(platform, message):
    timestamp = datetime.datetime.now().isoformat()
    log_file = os.path.join(LOGS_PATH,f"{platform}.log")
    with open(log_file,"a") as f:
        f.write(f"[{timestamp}] {message}\n")
    print(f"[{platform.upper()}] {message}")

def build_apk():
    log("apk","Starting APK build...")
    apk_file = os.path.join(OUTPUT_PATH,"apk","pai6_sovereign.apk")
    with open(apk_file,"w") as f: f.write("👑 PAI6 APK Placeholder")
    log("apk",f"APK build completed: {apk_file}")
    return {"apk_file":apk_file}

def build_web():
    log("web","Starting Web build...")
    web_file = os.path.join(OUTPUT_PATH,"web","index.html")
    html_content = "<html><head><title>PAI6 Dashboard</title></head><body style='background:black;color:#00ffcc;font-family:monospace;text-align:center'><h1>👑 PAI6 — Sovereign Control Panel</h1></body></html>"
    with open(web_file,"w") as f: f.write(html_content)
    log("web",f"Web build completed: {web_file}")
    return {"web_file":web_file}

def build_windows():
    log("windows","Starting Windows EXE build...")
    win_file = os.path.join(OUTPUT_PATH,"windows","pai6_windows.exe")
    with open(win_file,"w") as f: f.write("👑 PAI6 Windows EXE Placeholder")
    log("windows",f"Windows build completed: {win_file}")
    return {"exe_file":win_file}

def build_platform(platform):
    if platform=="apk": return build_apk()
    elif platform=="web": return build_web()
    elif platform=="windows": return build_windows()
    else: return {"error":"Unknown platform"}

def build_all_platforms():
    results={}
    for p in PLATFORMS:
        try: results[p] = build_platform(p)
        except Exception as e: results[p] = {"error":str(e)}
    return results

app = Flask(__name__)
DASHBOARD_HTML = "<html><head><title>PAI6 Dashboard</title></head><body style='background:black;color:#00ffcc;font-family:monospace;text-align:center'><h1>👑 PAI6 — Sovereign Control Panel</h1></body></html>"

@app.route('/')
def dashboard(): return DASHBOARD_HTML
@app.route('/api/build',methods=['POST'])
def api_build(): return build_platform(request.json.get("platform"))
@app.route('/api/build_all',methods=['POST'])
def api_build_all(): return build_all_platforms()

def set_permissions():
    try:
        for root, dirs, files in os.walk(BASE_PATH):
            for f in files: os.chmod(os.path.join(root,f), stat.S_IRWXU | stat.S_IRWXG | stat.S_IRWXO)
        print("✅ Permissions set successfully")
    except Exception as e: print("❌ Permission Error:", e)

if __name__=="__main__":
    set_permissions()
    print("🚀 PAI6 Autonomous Builder Running at http://localhost:8080")
    app.run(host="0.0.0.0", port=8080)
