from .base import BaseStore

class MemoryStore(BaseStore):
    def __init__(self):
        super().__init__()
        self.data = {}

    def get(self, key):
        return self.data.get(key)

    def set(self, key, value):
        self.data[key] = value

    def delete(self, key):
        self.data.pop(key, None)

    def exists(self, key):
        return key in self.data

    def all(self):
        return dict(self.data)

    def close(self):
        self.data.clear()
