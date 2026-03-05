#!/usr/bin/env python3
# 🔹 sovereign_control_center_new.py
# تشغيل Dashboard الخاص بالمنظومة على أي بورت متاح

import http.server
import socketserver
import sys

# 🔹 اختر البورت من الوسيط إذا موجود، وإلا استخدم 9000
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 9000

class Handler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

def run():
    try:
        with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
            print(f"🚀 Sovereign AI Dashboard running on port {PORT}")
            httpd.serve_forever()
    except OSError as e:
        print(f"⚠️ خطأ: {e}")
        print("حاول تشغيل السكربت مع بورت آخر المتاح.")
        sys.exit(1)

if __name__ == "__main__":
    run()
