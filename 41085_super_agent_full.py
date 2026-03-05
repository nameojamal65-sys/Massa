import os
import subprocess
import socket
import threading
import json
import time
import openai
import urllib.request
import zipfile

# 🔑 مفتاح OpenAI يجب وضعه في متغير البيئة OPENAI_API_KEY
openai.api_key = os.getenv("OPENAI_API_KEY")

LOG_FILE = "/sdcard/super_agent_log.json"
KNOWLEDGE_FILE = "/sdcard/super_agent_knowledge.json"
NGROK_PATH = "/data/data/com.termux/files/home/ngrok"

# ==========================
# 🛠 دوال مساعدة
# ==========================
def run_cmd(cmd):
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.stdout + result.stderr
    except Exception as e:
        return str(e)

def get_local_ip():
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
    entry = {"timestamp": time.time(), "action": action, "result": result}
    with open(LOG_FILE, "a") as f:
        f.write(json.dumps(entry) + "\n")

def remember_knowledge(prompt, outcome):
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
# 🌐 تثبيت Ngrok تلقائي
# ==========================
def setup_ngrok():
    if os.path.exists(NGROK_PATH):
        return "✅ Ngrok موجود بالفعل"
    print("⏳ تنزيل Ngrok ARM64...")
    url = "https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm64.zip"
    zip_path = "/data/data/com.termux/files/home/ngrok.zip"
    urllib.request.urlretrieve(url, zip_path)
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall("/data/data/com.termux/files/home/")
    os.chmod(NGROK_PATH, 0o755)
    os.remove(zip_path)
    return "✅ Ngrok جاهز"

# ==========================
# 🌟 نفق للوصول عن بعد
# ==========================
def start_tunnel(port=9000):
    if not os.path.exists(NGROK_PATH):
        return "❌ Ngrok غير موجود!"
    proc = subprocess.Popen(f"{NGROK_PATH} http {port}", shell=True)
    time.sleep(5)
    url = run_cmd("curl -s http://127.0.0.1:4040/api/tunnels | grep public_url | cut -d '\"' -f4")
    return url.strip()

# ==========================
# 🤖 Agent رئيسي
# ==========================
def SuperAgent():
    print(setup_ngrok())
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

        decision = GPT_decision(f"الجهاز على IP: {get_local_ip()}, الأمر: {user_input}")
        print(f"🤖 GPT يقترح: {decision}")

        output = run_cmd(decision)
        print(f"💻 نتيجة التنفيذ:\n{output}")
        log_action(user_input, output)
        remember_knowledge(user_input, output)

if __name__ == "__main__":
    SuperAgent()
