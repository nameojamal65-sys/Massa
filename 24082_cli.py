import sys
from legendary.orchestrator.orchestrator import Orchestrator
from legendary.agents.sample_agent import SampleAgent

orchestrator = Orchestrator()
agent = SampleAgent("agent_cli")
orchestrator.register(agent)

if len(sys.argv) < 2:
    print("Usage: python3 cli.py [start|stop|status]")
    sys.exit(1)

cmd = sys.argv[1]

if cmd == "start":
    orchestrator.start("agent_cli")
    print("Agent started")
elif cmd == "stop":
    orchestrator.stop("agent_cli")
    print("Agent stopped")
elif cmd == "status":
    print(orchestrator.list_agents())
