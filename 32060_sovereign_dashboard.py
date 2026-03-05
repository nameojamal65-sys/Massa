#!/usr/bin/env python3
# sovereign_dashboard.py - Dashboard كامل بدون nano

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from jinja2 import Template
import os

app = FastAPI(title="Sovereign Dashboard")

# مجلد الملفات الثابتة لو تحتاج CSS/JS
app.mount("/static", StaticFiles(directory="static"), name="static")

# دالة لبناء شجرة الملفات
def build_tree(path, prefix=""):
    tree = ""
    if not os.path.exists(path):
        return "📂 المجلد فارغ أو غير موجود"
    for item in sorted(os.listdir(path)):
        full_path = os.path.join(path, item)
        if os.path.isdir(full_path):
            tree += f"{prefix}📁 {item}/\n"
            tree += build_tree(full_path, prefix + "    ")
        else:
            tree += f"{prefix}📄 {item}\n"
    return tree

@app.get("/", response_class=HTMLResponse)
async def dashboard(request: Request):
    root_path = os.path.expanduser("~/sovereign_system")
    tree_text = build_tree(root_path)
    
    html_template = Template("""
    <html>
    <head>
        <title>Sovereign Dashboard</title>
        <style>
            body { font-family: monospace; background:#1e1e1e; color:#d4d4d4; padding:20px; }
            pre { background:#252526; padding:15px; border-radius:5px; overflow:auto; }
            h1 { color:#61dafb; }
        </style>
    </head>
    <body>
        <h1>🚀 Sovereign System Dashboard</h1>
        <h2>📂 شجرة الملفات:</h2>
        <pre>{{ tree }}</pre>
        <h2>🟢 حالة السيرفر:</h2>
        <p>الذكاء الاصطناعي والمنظومة شغالين.</p>
    </body>
    </html>
    """)
    return html_template.render(tree=tree_text)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
