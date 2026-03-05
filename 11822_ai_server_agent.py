#!/usr/bin/env python3
import subprocess
import time
import requests
import os
import re

# الإعدادات الابتدائية
PORT = 9000
ENDPOINTS = ["/", "/status", "/api/test", "/test", "/health"]
TUNNELS = [
    ("Cloudflared", "./cloudflared tunnel --url http://localhost:{port}"),
    ("Ngrok", "./ngrok http {port} --log=stdout"),
    ("LocalTunnel", "lt --port {port}"),
    ("Serveo", "ssh -R 80:localhost:{port} serveo.net")
]

def is_port_free(port):
    result = subprocess.run(["lsof", "-i", f"tcp:{port}"], capture_output=True)
    return result.returncode != 0

def start_server(port):
    print(f"🚀 تشغيل السيرفر على localhost:{port}")
    return subprocess.Popen(["python3", "sovereign_control_center_new.py", str(port)])

def test_endpoints(port):
    for ep in ENDPOINTS:
        try:
            r = requests.get(f"http://localhost:{port}{ep}", timeout=2)
            if 200 <= r.status_code < 400:
                print(f"✅ Endpoint شغال: {ep} (HTTP {r.status_code})")
                return ep
        except:
            continue
    return None

def try_tunnel(name, cmd):
    print(f"⏳ تجربة النفق: {name}...")
    proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(3)
    try:
        out, _ = proc.communicate(timeout=1)
    except subprocess.TimeoutExpired:
        proc.kill()
        out = b""
    out = out.decode()
    match = re.search(r'https://[-a-z0-9]*\.[a-z]*', out)
    if match:
        print(f"✅ النفق {name} ناجح: {match.group(0)}")
        return True
    else:
        proc.kill()
        print(f"❌ النفق {name} فشل.")
        return False

def AI_agent():
    global PORT
    while True:
        if not is_port_free(PORT):
            print(f"⚠️ البورت {PORT} مشغول، تجربة بورت آخر...")
            PORT += 1
            continue

        server = start_server(PORT)
        time.sleep(2)
        active_ep = test_endpoints(PORT)
        if not active_ep:
            print("❌ لا يوجد Endpoint مستجيب، إعادة تشغيل السيرفر...")
            server.kill()
            continue

        tunnel_ready = False
        for name, cmd_template in TUNNELS:
            if try_tunnel(name, cmd_template.format(port=PORT)):
                tunnel_ready = True
                break

        if tunnel_ready:
            print(f"🎯 النظام جاهز على localhost:{PORT}{active_ep}")
        else:
            print("⚠️ جميع النفقات فشلت، إعادة المحاولة بعد 5 ثواني...")
        
        time.sleep(5)
        if server.poll() is not None:
            print("❌ السيرفر توقف فجأة، إعادة تشغيل...")
            continue

if __name__ == "__main__":
    AI_agent()
