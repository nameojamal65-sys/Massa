#!/usr/bin/env python3
import time, threading, subprocess, os

def system_monitor():
    log_file = os.path.expanduser("~/pai6_system/logs/assistant_monitor.log")
    while True:
        with open(log_file,"a") as f:
            f.write(f"[{time.ctime()}] SYSTEM CHECK\n")
            f.write(subprocess.getoutput("df -h")+"\n")
            f.write(subprocess.getoutput("free -m")+"\n")
            f.write(subprocess.getoutput("ps aux | wc -l")+"\n")
            f.write("-------------------------------\n")
        time.sleep(90)

def ai_watchdog():
    while True:
        subprocess.run(["bash","-c","pip list"], stdout=open("/dev/null","w"))
        time.sleep(20)

if __name__=="__main__":
    threading.Thread(target=system_monitor, daemon=True).start()
    threading.Thread(target=ai_watchdog, daemon=True).start()
    while True:
        time.sleep(300)
