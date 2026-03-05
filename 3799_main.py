import logging
import os

BASE_DIR = os.path.dirname(os.path.dirname(__file__))
LOG_PATH = os.path.join(BASE_DIR, "legendary_system.log")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
    handlers=[
        logging.FileHandler(LOG_PATH),
        logging.StreamHandler()
    ]
)

logging.info("🚀 Legendary System Starting...")
from agents import ai_agent_async, ai_agent_system, ai_agent_v2, ai_server_agent

def main():
    print("🚀 تشغيل Legendary Dashboard")
    ai_agent_system.run()
    ai_agent_v2.run()
    ai_agent_async.run_async()
    ai_server_agent.run_server()

if __name__ == "__main__":
    main()
