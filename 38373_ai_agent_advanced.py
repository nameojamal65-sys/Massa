import os, sys, time, subprocess, requests, json
from threading import Thread
from http.server import SimpleHTTPRequestHandler, HTTPServer

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 9000
GPT_API_KEY = os.environ.get("OPENAI_API_KEY", "")

# ==============================
# Agent HTTP Interface
# ==============================
class AgentHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/status":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"AI Agent running")
        elif self.path.startswith("/run/"):
            cmd = self.path.replace("/run/", "")
            try:
                output = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT)
                self.send_response(200)
                self.end_headers()
                self.wfile.write(output)
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(str(e).encode())
        elif self.path.startswith("/ask/") and GPT_API_KEY:
            question = self.path.replace("/ask/", "")
            try:
                resp = requests.post(
                    "https://api.openai.com/v1/chat/completions",
                    headers={"Authorization": f"Bearer {GPT_API_KEY}"},
                    json={
                        "model": "gpt-4",
                        "messages": [{"role": "user", "content": question}],
                        "max_tokens": 500
                    }
                )
                answer = resp.json()['choices'][0]['message']['content']
                self.send_response(200)
                self.end_headers()
                self.wfile.write(answer.encode())
            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(str(e).encode())
        else:
            self.send_response(404)
            self.end_headers()

# ==============================
# Background Tasks
# ==============================
def auto_update():
    while True:
        subprocess.call("git pull || true", shell=True)
        time.sleep(3600)

def manage_network():
    while True:
        try:
            ngrok_proc = subprocess.Popen(f"./ngrok http {PORT}", shell=True)
            time.sleep(10)
            ngrok_proc.terminate()
        except:
            pass
        time.sleep(600)

# ==============================
# Run Agent
# ==============================
Thread(target=auto_update, daemon=True).start()
Thread(target=manage_network, daemon=True).start()
server = HTTPServer(('0.0.0.0', PORT), AgentHandler)
print(f"✅ AI Advanced Agent server running on port {PORT}")
server.serve_forever()
