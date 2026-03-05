class EventBus:
    def emit(self, event, payload=None):
        print(f"📡 EVENT => {event}", payload)
