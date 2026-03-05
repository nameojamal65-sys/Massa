import os
import subprocess
import socket
import threading
import json
import time
import openai

# 🔑 مفتاح OpenAI يجب وضعه في متغير البيئة OPENAI_API_KEY
openai.api_key = os.getenv("OPENAI_API_KEY")

LOG_FILE = "/sdcard/super_agent_log.json"
KNOWLEDGE_FILE = "/sdcard/super_agent_knowledge.json"

# ==========================
# 🛠 دوال مساعدة
# ==========================
def run_cmd(cmd):
    """تشغيل أي أمر نظامي"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.stdout + result.stderr
    except Exception as e:
        return str(e)

def get_local_ip():
    """الحصول على IP الجهاز"""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip

def log_action(action, result):
    """تسجيل سجل الأوامر ونتائجها"""
    entry = {"timestamp": time.time(), "action": action, "result": result}
    with open(LOG_FILE, "a") as f:
        f.write(json.dumps(entry) + "\n")

def remember_knowledge(prompt, outcome):
    """تخزين المعرفة لتعلم Agent"""
    knowledge = {"prompt": prompt, "outcome": outcome, "timestamp": time.time()}
    if os.path.exists(KNOWLEDGE_FILE):
        with open(KNOWLEDGE_FILE, "r") as f:
            data = json.load(f)
    else:
        data = []
    data.append(knowledge)
    with open(KNOWLEDGE_FILE, "w") as f:
        json.dump(data, f, indent=2)

def GPT_decision(prompt):
    """طلب قرار من GPT-4"""
    try:
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "أنت وكيل Super Agent كامل، حر، قادر على إدارة كل الجهاز والشبكة، واتخاذ أي قرارات عملية، وتنفيذ أي أمر نظامي."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        return f"❌ خطأ GPT: {e}"

# ==========================
# 🌐 الشبكة وواي فاي
# ==========================
def list_wifi_networks():
    """قائمة شبكات الواي فاي"""
    return run_cmd("termux-wifi-scaninfo")

def connect_wifi(ssid, password=""):
    """الاتصال بشبكة Wi-Fi"""
    return run_cmd(f"termux-wifi-connectioninfo")

# ==========================
# 🌟 نفق للوصول عن بعد
# ==========================
def start_tunnel(port=9000):
    """تشغيل نفق Ngrok تلقائي"""
    if not os.path.exists("/data/data/com.termux/files/home/ngrok"):
        return "❌ Ngrok غير موجود!"
    proc = subprocess.Popen(f"/data/data/com.termux/files/home/ngrok http {port}", shell=True)
    time.sleep(5)
    url = run_cmd("curl -s http://127.0.0.1:4040/api/tunnels | grep public_url | cut -d '\"' -f4")
    return url.strip()

# ==========================
# 🤖 Agent رئيسي
# ==========================
def SuperAgent():
    print(f"🌐 Super Agent جاهز على IP: {get_local_ip()}")
    print("🔹 اكتب 'exit' للخروج")
    print("🔹 اكتب 'tunnel' لتوليد رابط وصول عن بعد")
    while True:
        user_input = input("📝 أدخل أمر أو سؤال: ")
        if user_input.lower() in ["exit", "quit"]:
            print("🔴 إنهاء Super Agent...")
            break
        if user_input.lower() == "tunnel":
            print("⏳ تشغيل النفق...")
            print("🔗 الوصول عن بعد: ", start_tunnel())
            continue

        # GPT يقرر الإجراء
        decision = GPT_decision(f"الجهاز على IP: {get_local_ip()}, الأمر: {user_input}")
        print(f"🤖 GPT يقترح: {decision}")

        # تنفيذ القرار
        output = run_cmd(decision)
        print(f"💻 نتيجة التنفيذ:\n{output}")
        log_action(user_input, output)
        remember_knowledge(user_input, output)

# ==========================
# تشغيل Agent
# ==========================
if __name__ == "__main__":
    SuperAgent()
