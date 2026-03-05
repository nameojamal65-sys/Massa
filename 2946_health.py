from flask import jsonify

def install(app):
    @app.get("/health")
    def health():
        return jsonify({"ok": True, "service": "sovereign-ui", "status": "healthy"})
