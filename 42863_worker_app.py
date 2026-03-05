import argparse
from flask import Flask, request, jsonify
from pipelines.video_pipeline import VideoPipeline
from pipelines.voice_pipeline import VoicePipeline
from pipelines.code_pipeline import CodePipeline

app = Flask(__name__)

@app.post("/execute")
def execute():
    data = request.get_json(force=True, silent=True) or {}
    t = data.get("type")
    payload = data.get("payload") or {}
    if t == "video":
        return jsonify(VideoPipeline().run(payload))
    if t == "voice":
        return jsonify(VoicePipeline().run(payload))
    if t == "code":
        return jsonify(CodePipeline().run(payload))
    return jsonify({"error":"unsupported"}), 400

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="0.0.0.0")
    ap.add_argument("--port", type=int, default=9000)
    args = ap.parse_args()
    app.run(host=args.host, port=args.port)

if __name__ == "__main__":
    main()
