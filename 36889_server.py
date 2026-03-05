#!/usr/bin/env python3
from flask import Flask, render_template, jsonify
import psutil, os, socket

app = Flask(__name__, template_folder="templates")

# --- SC_OPS_BEGIN ---
# Enterprise Ops API (Zero-Break) - behind SC_OPS_API=0 by default
try:
    from sc_ops.api import bp as sc_ops_bp
    app.register_blueprint(sc_ops_bp)
except Exception as _e:
    # Ops layer is optional; do not break legacy startup
    pass
# --- SC_OPS_END ---

# --- SC_RELEASE_LOCK_BEGIN ---
# --- SC_IMPORT_LOCK_BEGIN ---
# Ensure project root is on sys.path even when running: python3 ui/server.py
import os as _os, sys as _sys
_sys.path.insert(0, _os.path.dirname(_os.path.dirname(__file__)))
# --- SC_IMPORT_LOCK_END ---

from sc_platform.middleware import install as sc_install_mw
from sc_platform.health import install as sc_install_health
from sc_platform.flags import SC_NEW_UI
import os
from flask import send_from_directory

sc_install_mw(app)
sc_install_health(app)

# New UI served under /dash (Feature Flag: SC_NEW_UI=1)
_DASH_DIR = os.path.join(os.path.dirname(__file__), "static", "dash")

@app.get("/dash")
@app.get("/dash/")
@app.get("/dash/<path:path>")
def sc_dash(path="index.html"):
    if not SC_NEW_UI:
        return ("Not Found", 404)
    file_path = path if path else "index.html"
    full = os.path.join(_DASH_DIR, file_path)
    if os.path.exists(full):
        return send_from_directory(_DASH_DIR, file_path)
    return send_from_directory(_DASH_DIR, "index.html")
# --- SC_RELEASE_LOCK_END ---

def get_status_safe():
    cpu = ram = procs = 0.0
    try:
        cpu = psutil.cpu_percent(interval=0.5)
        ram = psutil.virtual_memory().percent
        procs = len(psutil.pids())
    except Exception:
        cpu = ram = procs = 0.0
    return {"cpu": cpu, "ram": ram, "procs": procs}

@app.route("/")
def index():
    return render_template("dashboard.html")

@app.route("/api/status")
def status():
    return jsonify(get_status_safe())

@app.route("/api/restart")
def restart():
    os.system("pkill -f core.py")
    return jsonify({"status":"restarting"})

if __name__ == "__main__":
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    port = 8080
    while True:
        try:
            sock.bind(("0.0.0.0", port))
            sock.close()
            break
        except:
            port += 1
    app.run(host="0.0.0.0", port=port)
