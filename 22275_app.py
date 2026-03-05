import os, json
from flask import Flask, jsonify, request, send_from_directory
from flask_socketio import SocketIO
from core.config import Settings
from core.monitor import snapshot
from core.logger import log
from core.core_engine import SovereignCoreEngine
from orchestrator.scheduler import Scheduler
from platform_services.identity import bootstrap_admin, login, verify as _who
from platform_services.audit_chain import verify as audit_verify

app = Flask(__name__, static_folder="static")
socketio = SocketIO(app, cors_allowed_origins="*")

bootstrap_admin()

engine = SovereignCoreEngine()
scheduler = Scheduler(engine.tm)
scheduler.start()

@app.route("/")
def home():
    return send_from_directory("static", "dashboard.html")

@app.route("/operator")
def operator_console():
    return send_from_directory("static", "operator.html")

@app.get("/health")
def health():
    return jsonify({"ok": True})

@app.post("/api/login")
def api_login():
    data = request.get_json(force=True, silent=True) or {}
    token = login(data.get("user",""), data.get("password",""))
    if not token:
        return jsonify({"ok": False}), 401
    return jsonify({"ok": True, "token": token})

@app.get("/api/audit/verify")
def api_audit_verify():
    return jsonify(audit_verify())

@app.get("/api/status")
def api_status():
    return jsonify({
        "engine": engine.running,
        "resources": snapshot(),
        "platform_mode": Settings.PLATFORM_MODE,
        "mtls": Settings.MTLS,
        "tasks": engine.tm.list(),
    })

@app.post("/api/start")
def api_start():
    return jsonify(engine.start(role="admin"))

@app.post("/api/stop")
def api_stop():
    return jsonify(engine.stop(role="admin"))

@app.post("/api/restart")
def api_restart():
    return jsonify(engine.restart(role="admin"))

@app.post("/api/command")
def api_command():
    data = request.get_json(force=True, silent=True) or {}
    cmd = data.get("command","")
    token = data.get("token","")
    sig = data.get("signature")
    return jsonify(engine.handle(cmd, token=token, signature=sig))

@app.get("/api/tasks")
def api_tasks():
    return jsonify(engine.tm.list())

@socketio.on("connect")
def on_connect():
    log("WS connected")
    socketio.emit("status", {"ok": True})

def _push():
    while True:
        try:
            socketio.emit("live", {"engine": engine.running, "resources": snapshot()})
        except Exception:
            pass
        socketio.sleep(1.0)

socketio.start_background_task(_push)

if __name__ == "__main__":
    os.makedirs(Settings.ARTIFACT_DIR, exist_ok=True)
    socketio.run(app, host=Settings.APP_HOST, port=Settings.APP_PORT)
