from flask import Flask, jsonify, render_template_string
import psutil, time, os

app = Flask(__name__)

UI = """
<!DOCTYPE html>
<html>
<head>
<title>Genesis Command Dashboard</title>
<style>
body{background:#000;color:#0f0;font-family:monospace}
.box{border:1px solid #0f0;padding:10px;margin:10px}
h1{color:#0ff}
</style>
</head>
<body>
<h1>👑 Genesis Command Dashboard</h1>
<div class="box" id="stats"></div>
<script>
async function load(){
 let r = await fetch('/status');
 let j = await r.json();
 let html = "";
 for(let k in j){ html += k + " : " + j[k] + "<br>"; }
 document.getElementById("stats").innerHTML = html;
}
setInterval(load,2000);
load();
</script>
</body>
</html>
"""

@app.route("/")
def home():
    return render_template_string(UI)

@app.route("/status")
def status():
    return jsonify({
        "cpu": psutil.cpu_percent(),
        "ram": psutil.virtual_memory().percent,
        "disk": psutil.disk_usage("/").percent,
        "processes": len(psutil.pids()),
        "time": time.ctime()
    })

if __name__ == "__main__":
    app.run("0.0.0.0",8080)
