from fastapi import FastAPI, Form
from fastapi.responses import HTMLResponse, JSONResponse
import psutil, os, time, subprocess

app = FastAPI(title="PAI6 Ultimate Dashboard")

# Define tasks & assistants to monitor
TASKS = {
    "Sovereign_UI": "$HOME/pai6_ui/run_ui.sh",
    "Sovereign_Core": "$HOME/sovereign_nuclear/run_plus.sh",
    "Terminal_Assistant": "$HOME/sovereign_nuclear/pai6_assistant.sh",
    "Ultimate_Assistant": "$HOME/sovereign_nuclear/pai6_ultimate_assistant.sh"
}

def task_status(cmd):
    try:
        result = subprocess.run(["pgrep","-f", cmd], stdout=subprocess.PIPE)
        return "RUNNING" if result.stdout else "STOPPED"
    except:
        return "ERROR"

@app.get("/status")
def status():
    cpu = psutil.cpu_percent()
    ram = psutil.virtual_memory().percent
    disk = psutil.disk_usage("/").percent
    time_now = time.ctime()
    tasks_status = {t: task_status(c) for t,c in TASKS.items()}
    return JSONResponse({
        "cpu": cpu, "ram": ram, "disk": disk, "time": time_now,
        "tasks": tasks_status
    })

@app.post("/control")
def control(task:str = Form(...), action:str = Form(...)):
    if task not in TASKS:
        return {"result": "INVALID_TASK"}
    cmd = TASKS[task]
    if action=="start":
        subprocess.Popen([cmd])
    elif action=="stop":
        subprocess.run(["pkill","-f", cmd])
    elif action=="restart":
        subprocess.run(["pkill","-f", cmd])
        subprocess.Popen([cmd])
    return {"result": f"{task} -> {action.upper()}"}

@app.get("/")
def dashboard():
    return HTMLResponse(open("../web/index.html").read())
