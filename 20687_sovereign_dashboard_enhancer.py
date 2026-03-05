#!/usr/bin/env python3
from flask import Flask, render_template_string
import os

app = Flask(__name__)

@app.route("/")
def index():
    files = os.listdir(".")
    return render_template_string("""
    <h1>🚀 Sovereign Dashboard</h1>
    <h3>Files in Project:</h3>
    <ul>{% for f in files %}<li>{{f}}</li>{% endfor %}</ul>
    """, files=files)

if __name__ == "__main__":
    app.run(port=8080)
