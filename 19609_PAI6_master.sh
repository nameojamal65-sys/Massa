#!/data/data/com.termux/files/usr/bin/bash

# =============================
# 🌐 PAI6 Master Controller
# =============================

HOME_DIR="$HOME"
ROOT="$HOME_DIR/PAI6_System"
BASE="$HOME_DIR/PAI6"
OUTPUT="$BASE/realized"
LOG="$BASE/logs"
TEMP="$BASE/temp"
REPORT="$LOG/final_report.json"
HASH_DB="$BASE/hash_db.json"
GPT_MODEL="$HOME_DIR/ggml-model-quantized.bin"

MAX_THREADS=4
MAX_SIZE=$((100*1024))  # 100KB

mkdir -p "$OUTPUT" "$LOG" "$TEMP"

# --- قراءة مفتاح OpenAI ---
API_KEY_FILE="$HOME_DIR/PAI6/PAI6_API_KEY.txt"
if [ ! -f "$API_KEY_FILE" ]; then
    echo "⚠️ المفتاح غير موجود، افتح nano وأدخل المفتاح أولاً!"
    exit 1
else
    OPENAI_KEY=$(cat "$API_KEY_FILE")
fi

echo "🚀 تشغيل PAI6 Master..."
echo "🌐 Dashboard: http://127.0.0.1:8080"

# --- جمع الملفات ---
find "$ROOT" -type f \
 ! -name "*.key" \
 ! -name "*.pem" \
 ! -name "*.env" \
 ! -path "*/.git/*" > "$TEMP/files.txt"

# --- سكربت بايثون للتشغيل ---
python3 <<EOF
import os, json, hashlib, requests, subprocess, time, concurrent.futures

API_KEY = "$OPENAI_KEY"
FILES_PATH = "$TEMP/files.txt"
OUTPUT = "$OUTPUT"
REPORT_PATH = "$REPORT"
HASH_DB_PATH = "$HASH_DB"
GPT_LOCAL = "$GPT_MODEL"
MAX_SIZE = $MAX_SIZE
MAX_WORKERS = $MAX_THREADS

# تحميل DB الهاشات
if os.path.exists(HASH_DB_PATH):
    with open(HASH_DB_PATH) as f:
        HASH_DB = json.load(f)
else:
    HASH_DB = {}

def sha256_file(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()

def call_openai(content):
    try:
        headers = {
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": "gpt-4.1",
            "input": f"🔥 قم بإصلاح وتحسين الكود التالي بأمان:\n\n{content}"
        }
        r = requests.post("https://api.openai.com/v1/responses", headers=headers, json=payload, timeout=60)
        r.raise_for_status()
        text = r.json()["output"][0]["content"][0]["text"]
        if len(text.strip()) < 10:
            return None
        return text
    except:
        return None

def offline(file):
    if not os.path.exists(GPT_LOCAL):
        return None
    try:
        result = subprocess.run(
            ["gpt4all", "-m", GPT_LOCAL, "-p", f"fix {file}"],
            capture_output=True, text=True, timeout=120
        )
        return result.stdout
    except:
        return None

def process(file):
    result = {"file": file, "status": "skipped", "reason": "", "time": 0}
    start = time.time()

    if not os.path.exists(file):
        result["reason"] = "file not found"
        return result
    if os.path.getsize(file) > MAX_SIZE:
        result["reason"] = "file too large"
        return result

    file_hash = sha256_file(file)
    if HASH_DB.get(file) == file_hash:
        result["reason"] = "unchanged"
        return result

    try:
        with open(file, "r", errors="ignore") as f:
            content = f.read()

        # أولاً OFFLINE
        ai_output = offline(file)
        mode = "OFFLINE"
        # إذا فشل، ONLINE
        if not ai_output or len(ai_output) < 10:
            ai_output = call_openai(content)
            mode = "ONLINE"

        if ai_output:
            out_path = os.path.join(OUTPUT, os.path.basename(file))
            with open(out_path,"w") as out:
                out.write(ai_output)
            HASH_DB[file] = file_hash
            result["status"] = mode
        else:
            result["reason"] = "AI failed"

    except Exception as e:
        result["reason"] = str(e)

    result["time"] = round(time.time() - start, 2)
    print(f"[{mode}] {os.path.basename(file)} -> {result['reason'] if result['status']=='skipped' else 'done'} ({result['time']}s)")
    return result

# --- قراءة الملفات ---
with open(FILES_PATH) as f:
    FILES = [line.strip() for line in f if line.strip()]

results = []
with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
    for r in executor.map(process, FILES):
        results.append(r)

# --- حفظ التقرير ---
with open(REPORT_PATH,"w") as rep:
    json.dump(results, rep, indent=2)
with open(HASH_DB_PATH,"w") as hdb:
    json.dump(HASH_DB,hdb, indent=2)

print("✅ PAI6 Master Finished!")
EOF
