#!/data/data/com.termux/files/usr/bin/python3
from http.server import BaseHTTPRequestHandler, HTTPServer
import sys

# قراءة البورت من وسيط التشغيل
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 9000

class AgentHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain; charset=utf-8")
        self.end_headers()
        # نص مع ترميز UTF-8 لدعم الرموز التعبيرية
        self.wfile.write("Legendary AI Agent is ONLINE 🚀\n".encode('utf-8'))

    def log_message(self, format, *args):
        # تعطيل اللوج الافتراضي في الكونسول
        return

def run_server():
    server = HTTPServer(("0.0.0.0", PORT), AgentHandler)
    print(f"🚀 AI Agent مباشر على الإنترنت يعمل على localhost:{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 تم إيقاف AI Agent")
        server.server_close()

if __name__ == "__main__":
    run_server()
