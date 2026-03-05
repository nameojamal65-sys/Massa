import json
import time


class MemoryCore:
    def __init__(self, path="memory.db"):
        self.path = path

    def write(self, key, value):
        try:
            data = json.load(open(self.path))
        except BaseException:
            data = {}
        data[key] = {"value": value, "ts": time.time()}
        json.dump(data, open(self.path, "w"))

    def read(self, key):
        try:
            return json.load(open(self.path)).get(key)
        except BaseException:
            return None
