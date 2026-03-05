from intelligence.multi_lus.multi_lus_router import MultiLingualRouter
from memory.memory_core import MemoryCore

router = MultiLingualRouter()
memory = MemoryCore()

router.register_model("analysis",{"type":"llm"})
router.register_model("code",{"type":"llm"})
router.register_model("vision",{"type":"multimodal"})

def execute(task, lang="en"):
    routed = router.route_multilang("sovereign",task,lang)
    memory.write(task,routed)
    return routed
