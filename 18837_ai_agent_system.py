#!/usr/bin/env python3
import os, sys, json, subprocess, socket, time, threading
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = 9000
STATE_FILE = "agent_state.json"
TUNNELS = {
    "Ngrok": "./ngrok http {port} --log=stdout",
    "Cloudflared": "./cloudflared tunnel --url http://localhost:{port}",
    "LocalTunnel": "lt --port {port}"
}

# ====== إدارة الحالة والتعلم الذاتي ======
if not os.path.exists(STATE_FILE):
    with open(STATE_FILE, "w") as f:
        json.dump({"commands": [], "errors": []}, f)

def save_state(entry):
    with open(STATE_FILE, "r+") as f:
        state = json.load(f)
        state["commands"].append(entry)
        f.seek(0); json.dump(state, f, indent=2)

# ====== التحقق من البورت الفارغ ======
def get_free_port(port):
    while True:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(("localhost", port)) != 0:
                return port
        port += 1

PORT = get_free_port(PORT)

# ====== تشغيل النفق التلقائي ======
def start_tunnel():
    for name, cmd_template in TUNNELS.items():
        cmd = cmd_template.format(port=PORT)
        try:
            proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            time.sleep(3)
            if proc.poll() is None:
                print(f"✅ النفق {name} ناجح")
                return proc
            else:
                proc.kill()
        except Exception as e:
            print(f"❌ فشل النفق {name}: {e}")
    return None

tunnel_proc = start_tunnel()

# ====== إدارة الأوامر وتشغيلها ======
def run_command(cmd):
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=60)
        output = result.stdout + result.stderr
        save_state({"command": cmd, "output": output})
        return output
    except Exception as e:
        save_state({"command": cmd, "error": str(e)})
        return str(e)

# ====== واجهة API بسيطة ======
class AgentHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith("/run/"):
            cmd = self.path[len("/run/"):].replace("%20"," ")
            output = run_command(cmd)
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(output.encode())
        elif self.path.startswith("/ask/"):
            question = self.path[len("/ask/"):].replace("%20"," ")
            answer = f"[GPT الرد التلقائي على]: {question}"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(answer.encode())
        else:
            self.send_response(404)
            self.end_headers()

# ====== تشغيل السيرفر ======
server = HTTPServer(("0.0.0.0", PORT), AgentHandler)
print(f"🚀 AI Agent يعمل على localhost:{PORT}")
server.serve_forever()
