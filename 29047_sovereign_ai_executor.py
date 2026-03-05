#!/usr/bin/env python3
"""
🚀 Sovereign AI Executor
- يحلل ملفات المشروع تلقائيًا
- يستخدم OpenAI GPT-3/4 لتحليل الملفات
- يولد تقريرًا شاملًا عن الملفات والمكونات
"""

import os
import json
import openai

# ⚠️ ضع مفتاح OpenAI API الخاص بك هنا
openai.api_key = "YOUR_OPENAI_API_KEY"

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
REPORT_FILE = os.path.join(PROJECT_DIR, "sovereign_ai_report.json")

def find_files(project_dir):
    files_list = []
    for root, _, files in os.walk(project_dir):
        for file in files:
            if file.endswith((".py", ".pyc")):
                files_list.append(os.path.join(root, file))
    return files_list

def read_file(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            return f.read()
    except:
        return None

def analyze_file(file_path, content):
    if not content:
        return {"file": file_path, "status": "empty_or_binary"}
    prompt = f"""
    اقرأ محتوى الملف التالي وقم بتلخيص وظيفته، تحديد المكون (Data / AI / Dashboard / Other)
    وإمكانية تحويله لمنتج تجاري. الملف: {file_path}
    المحتوى:
    {content[:4000]}  # أول 4000 حرف لتجنب الحد الأقصى
    """
    try:
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}],
            temperature=0
        )
        analysis = response['choices'][0]['message']['content']
        return {"file": file_path, "analysis": analysis}
    except Exception as e:
        return {"file": file_path, "error": str(e)}

def main():
    print("🚀 Sovereign AI Executor Starting...")
    files = find_files(PROJECT_DIR)
    print(f"🔎 Found {len(files)} files for analysis.")
    results = []
    for i, file_path in enumerate(files, 1):
        print(f"Analyzing ({i}/{len(files)}): {file_path}")
        content = read_file(file_path)
        result = analyze_file(file_path, content)
        results.append(result)
    with open(REPORT_FILE, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print(f"✅ Analysis complete. Report saved to {REPORT_FILE}")

if __name__ == "__main__":
    main()
