from http.server import SimpleHTTPRequestHandler, HTTPServer
import socket
port = int(__import__("sys").argv[1])


class H(SimpleHTTPRequestHandler):
    pass


print(f"🚀 Dashboard running on http://127.0.0.1:{port}")
HTTPServer(("0.0.0.0", port), H).serve_forever()
