import json, time

class MemoryCore:
    def __init__(self, path="memory.db"):
        self.path = path

    def write(self, key, value):
        try:
            data = json.load(open(self.path))
        except:
            data = {}
        data[key] = {"value": value, "ts": time.time()}
        json.dump(data, open(self.path,"w"))

    def read(self, key):
        try:
            return json.load(open(self.path)).get(key)
        except:
            return None
