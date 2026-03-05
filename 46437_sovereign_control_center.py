import os
import json
from http.server import BaseHTTPRequestHandler, HTTPServer

HOME_DIR = os.path.expanduser("~")

def analyze_projects():
    projects = []
    for item in os.listdir(HOME_DIR):
        path = os.path.join(HOME_DIR, item)
        if os.path.isdir(path):
            total_size = 0
            total_files = 0
            for root, dirs, files in os.walk(path):
                total_files += len(files)
                for f in files:
                    try:
                        fp = os.path.join(root, f)
                        total_size += os.path.getsize(fp)
                    except:
                        pass
            projects.append({
                "name": item,
                "files": total_files,
                "size_mb": round(total_size / (1024*1024), 2)
            })
    return projects

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/projects":
            data = analyze_projects()
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(data).encode())
        else:
            self.send_response(404)
            self.end_headers()
def run(port=9000):
    server = HTTPServer(("0.0.0.0", port), Handler)
    print(f"🚀 Sovereign Control Center running on port {port}")
    server.serve_forever()

if __name__ == "__main__":
    import sys
    port = 9000
    if len(sys.argv) > 1:
        port = int(sys.argv[1])
    run(port)
