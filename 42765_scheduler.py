import time
class Scheduler:
    def run(self):
        while True:
            print("⏳ Scheduler heartbeat")
            time.sleep(10)
