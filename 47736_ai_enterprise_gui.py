#!/data/data/com.termux/files/usr/bin/python3
# -*- coding: utf-8 -*-

"""
Sovereign Enterprise GUI System
Author: Abu Miftah + Advanced Enhancements
Features:
- Modern GUI with Tailwind CSS
- Live admin chat with emojis and colored messages
- Dynamic Dashboard Panels: Analytics, Documents, AI Engine
- Smooth interactive experience
"""

from fastapi import FastAPI, WebSocket, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
import json
import os
import datetime

app = FastAPI(title="Sovereign Enterprise GUI")

# Ensure output directories exist
os.makedirs("./output", exist_ok=True)
LOG_FILE = "./output/admin_chat_log.json"

# Serve static for Tailwind and JS
app.mount("/static", StaticFiles(directory="static"), name="static")

# ==========================
# HTML Template
# ==========================
HTML_PAGE = """
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Sovereign Enterprise Dashboard</title>
<script src="https://cdn.tailwindcss.com"></script>
<script>
let ws;
function initWebSocket() {
    ws = new WebSocket("ws://" + location.host + "/ws/admin");
    ws.onmessage = function(event) {
        const msgBox = document.getElementById("messages");
        msgBox.innerHTML += event.data + "<br/>";
        msgBox.scrollTop = msgBox.scrollHeight;
    };
}
function sendCommand() {
    const input = document.getElementById("command");
    ws.send(input.value);
    input.value = "";
}
window.onload = initWebSocket;
</script>
</head>
<body class="bg-gradient-to-r from-purple-500 via-pink-500 to-red-500 min-h-screen text-white">
<div class="p-6">
<h1 class="text-4xl font-bold mb-4">👑 Sovereign Enterprise Dashboard</h1>
<div class="flex gap-4">
    <div class="flex-1 bg-white/20 p-4 rounded-lg shadow-lg">
        <h2 class="text-2xl font-semibold mb-2">📊 Analytics</h2>
        <p>Live KPIs, charts, and dynamic data here.</p>
    </div>
    <div class="flex-1 bg-white/20 p-4 rounded-lg shadow-lg">
        <h2 class="text-2xl font-semibold mb-2">📂 Documents</h2>
        <p>Manage reports and synchronize files dynamically.</p>
    </div>
</div>
<div class="mt-6 bg-white/20 p-4 rounded-lg shadow-lg">
<h2 class="text-2xl font-semibold mb-2">💬 Admin Chat</h2>
<div id="messages" class="h-40 overflow-y-auto p-2 bg-black/50 rounded mb-2"></div>
<input type="text" id="command" class="w-full p-2 rounded text-black font-bold" placeholder="Type command..." onkeydown="if(event.key==='Enter'){sendCommand();}">
</div>
</div>
</body>
</html>
"""

# ==========================
# Routes
# ==========================
@app.get("/", response_class=HTMLResponse)
async def dashboard():
    return HTML_PAGE

# ==========================
# WebSocket for Admin Chat
# ==========================
@app.websocket("/ws/admin")
async def admin_ws(websocket: WebSocket):
    await websocket.accept()
    while True:
        data = await websocket.receive_text()
        # Log command
        entry = {"user": "admin", "command": data, "timestamp": str(datetime.datetime.now())}
        if os.path.exists(LOG_FILE):
            with open(LOG_FILE, "r") as f:
                logs = json.load(f)
        else:
            logs = []
        logs.append(entry)
        with open(LOG_FILE, "w") as f:
            json.dump(logs, f, indent=2)
        # Execute command (simple simulation)
        if data.startswith("suggest_improvements"):
            response = "🧠 Suggestion: Consider optimizing dashboard KPIs!"
        elif data.startswith("generate_report"):
            response = f"📊 Report generated at {datetime.datetime.now().strftime('%H:%M:%S')} 🎉"
        else:
            response = f"✅ Command executed: {data}"
        await websocket.send_text(response)
