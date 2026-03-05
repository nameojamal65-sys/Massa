import os, json, time, hashlib, threading

class GenesisCore:

    def __init__(self, root):
        self.root = root
        self.state = {}
        self.memory = {}
        self.engines = []
        self.endpoints = []
        self.load_map()

    def load_map(self):
        for root, dirs, files in os.walk(self.root):
            for d in dirs:
                if any(x in d.lower() for x in ["core","engine","agent","brain","mind","intel"]):
                    self.engines.append(os.path.join(root,d))
            for f in files:
                if f.endswith((".py",".js",".sh")):
                    self.endpoints.append(os.path.join(root,f))

    def perceive(self):
        self.state["engines"] = len(self.engines)
        self.state["entry_points"] = len(self.endpoints)
        self.state["fingerprint"] = hashlib.sha256(str(self.state).encode()).hexdigest()

    def think(self):
        score = (self.state["engines"] * 7) + (self.state["entry_points"] * 3)
        self.state["intelligence"] = score
        if score > 20000:
            self.state["level"] = "Sovereign"
        elif score > 10000:
            self.state["level"] = "Ultra"
        else:
            self.state["level"] = "Developing"

    def evolve(self):
        self.memory[str(time.time())] = dict(self.state)

    def guardian(self):
        if self.state.get("engines",0) < 5:
            print("⚠️ Warning: Low engine count — system underpowered")

    def run(self):
        print("👑 Genesis AI Core Online")
        while True:
            self.perceive()
            self.think()
            self.evolve()
            self.guardian()
            self.report()
            time.sleep(10)

    def report(self):
        os.system("clear")
        print("👑 Genesis AI Core — Live Intelligence Monitor")
        print("============================================")
        for k,v in self.state.items():
            print(f"{k:20} : {v}")
        print("============================================")

if __name__ == "__main__":
    core = GenesisCore(os.getcwd())
    core.run()
