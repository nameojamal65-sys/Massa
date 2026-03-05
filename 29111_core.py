import os, time, json, threading, subprocess, sys, traceback

LOG="data/logs/autonomous.log"

def log(msg):
    ts=time.strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG,"a") as f:
        f.write(f"[{ts}] {msg}\n")
    print(msg)

class AutonomousCore:
    def __init__(self):
        self.alive=True
        self.tasks=[]
        log("AUTONOMOUS CORE INITIALIZED")

    def register(self, fn, interval):
        self.tasks.append((fn, interval, time.time()))

    def loop(self):
        log("AUTONOMOUS CORE LOOP STARTED")
        while self.alive:
            now=time.time()
            for i,(fn,interval,last) in enumerate(self.tasks):
                if now-last>=interval:
                    try:
                        fn()
                        self.tasks[i]=(fn,interval,now)
                    except Exception as e:
                        log("TASK ERROR: "+str(e))
                        log(traceback.format_exc())
            time.sleep(0.5)

CORE=AutonomousCore()

def health():
    return {
        "pid": os.getpid(),
        "time": time.ctime(),
        "uptime": time.time()
    }

def heartbeat():
    open("data/heartbeat.json","w").write(json.dumps(health(),indent=2))
    log("HEARTBEAT OK")

CORE.register(heartbeat,3)

if __name__=="__main__":
    CORE.loop()
