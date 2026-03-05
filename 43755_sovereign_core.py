#!/usr/bin/env python3
import os
import ast
import threading
import http.server
import socketserver
import webbrowser
import json

SYSTEM_PATH = "/data/data/com.termux/files/home/sovereign_system"
CAPABILITIES = ["Data Collection", "Data Processing", "Analytics", "Dashboard", "AI Engine"]

# --- File Analysis ---
def analyze_file(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            tree = ast.parse(f.read())
        functions = [node.name for node in ast.walk(tree) if isinstance(node, ast.FunctionDef)]
        classes = [node.name for node in ast.walk(tree) if isinstance(node, ast.ClassDef)]
        return {"functions": functions, "classes": classes}
    except:
        return {"error": "Could not parse"}

def detect_capabilities(file_name):
    caps = []
    name = file_name.lower()
    if "collect" in name or "collector" in name:
        caps.append("Data Collection")
    if "process" in name or "worker" in name or "prepare" in name:
        caps.append("Data Processing")
    if "analytics" in name or "report" in name:
        caps.append("Analytics")
    if "dashboard" in name or "view" in name or "blueprint" in name:
        caps.append("Dashboard")
    if "ai" in name or "engine" in name or "optimizer" in name or "organizer" in name:
        caps.append("AI Engine")
    if not caps:
        caps.append("Unknown")
    return caps

# --- Build System Structure ---
system_structure = {}
for root, dirs, files in os.walk(SYSTEM_PATH):
    for file in files:
        if file.endswith(".py"):
            rel_path = os.path.relpath(os.path.join(root, file), SYSTEM_PATH)
            system_structure[rel_path] = {
                "capabilities": detect_capabilities(file),
                "analysis": analyze_file(os.path.join(root, file))
            }

# --- Interactive CLI ---
def cli_loop():
    while True:
        print("\nAvailable Capabilities:")
        for i, cap in enumerate(CAPABILITIES + ["Unknown"], 1):
            print(f"{i}. {cap}")
        choice = input("\nEnter capability number (or 'q' to quit): ").strip()
        if choice.lower() == "q":
            break
        if not choice.isdigit() or not (1 <= int(choice) <= len(CAPABILITIES)+1):
            print("Invalid choice, try again.")
            continue
        cap = (CAPABILITIES + ["Unknown"])[int(choice)-1]
        files = [f for f, v in system_structure.items() if cap in v["capabilities"]]
        print(f"\nFiles with capability '{cap}': ({len(files)})")
        for f in files:
            print(f" • {f}")

# --- Simple Dashboard Server ---
class DashboardHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/system":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(system_structure).encode())
        else:
            super().do_GET()

def start_dashboard():
    PORT = 8080
    os.chdir(SYSTEM_PATH)
    with socketserver.TCPServer(("", PORT), DashboardHandler) as httpd:
        webbrowser.open(f"http://127.0.0.1:{PORT}")
        httpd.serve_forever()

# --- Main Execution ---
if __name__ == "__main__":
    print("✅ Sovereign AI System Ready!")
    dashboard_thread = threading.Thread(target=start_dashboard, daemon=True)
    dashboard_thread.start()
    cli_loop()
