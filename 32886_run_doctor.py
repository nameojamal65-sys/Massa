from core.task_engine.dispatcher import TaskDispatcher
from core.agent_manager.registry import AgentRegistry
from core.event_bus.bus import EventBus
from intelligence.multi_lus.multi_lus_router import MultiLingualRouter

dispatcher = TaskDispatcher()
agents = AgentRegistry()
events = EventBus()
router = MultiLingualRouter()

agents.register("web","dashboard")
agents.register("mobile","agent")
agents.register("desktop","agent")

tasks = [
    "monitor system health",
    "analyze current load",
    "generate code",
    "build intelligence report"
]

for t in tasks:
    routed = router.route_multilang("s1", t, "ar")
    res = dispatcher.dispatch(routed)
    events.emit("task_executed", res)

print("✅ FULL SYSTEM DIAGNOSTIC: OK")
