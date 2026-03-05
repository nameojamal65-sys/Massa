import redis
from legendary.config import settings

r = redis.Redis(host=settings.REDIS_HOST, port=settings.REDIS_PORT)

def push_task(task, tenant="global"):
    r.lpush(f"legendary_queue:{tenant}", task)

def pop_task(tenant="global"):
    return r.rpop(f"legendary_queue:{tenant}")
