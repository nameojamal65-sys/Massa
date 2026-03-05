import redis
import os
from dotenv import load_dotenv

load_dotenv()
url = os.getenv("REDIS_URL")

try:
    r = redis.from_url(url)
    r.set('MASA_STATUS', 'ACTIVE_SULTAN')
    print(f"[✓] MASA: الذاكرة اللحظية متصلة! الحالة: {r.get('MASA_STATUS').decode('utf-8')}")
except Exception as e:
    print(f"[!] خطأ في الاتصال بـ Redis: {e}")
