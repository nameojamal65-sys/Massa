import threading
from abc import ABC, abstractmethod


class BaseStore(ABC):
    def __init__(self):
        self.lock = threading.RLock()

    @abstractmethod
    def get(self, key): ...
    @abstractmethod
    def set(self, key, value): ...
    @abstractmethod
    def delete(self, key): ...
    @abstractmethod
    def exists(self, key): ...
    @abstractmethod
    def all(self): ...
    @abstractmethod
    def close(self): ...
