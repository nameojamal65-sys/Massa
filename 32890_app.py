from flask import Flask, jsonify
from core.orchestrator.main import SovereignCore

app = Flask(__name__)
core = SovereignCore()
core.boot()

@app.route("/health")
def health():
    return jsonify({"status": core.status()})

@app.route("/status")
def status():
    return jsonify({"state": core.status()})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
