#!/usr/bin/env python3
import os
import openai
from pathlib import Path

# مسار مشروعك
PROJECT_DIR = Path.home() / "sovereign_production"
OUTPUT_DIR = PROJECT_DIR / "output"
OUTPUT_DIR.mkdir(exist_ok=True)

# جمع كل ملفات .py
def gather_files():
    py_files = list(PROJECT_DIR.rglob("*.py"))
    print(f"🚀 بدء جمع الملفات...\n📦 عدد الملفات المكتشفة: {len(py_files)}")
    return py_files

# عد الأسطر الفعلية
def count_lines(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        return sum(1 for _ in f)

# تحسين الملفات باستخدام أبو مفتاح AI
def ai_optimize(files):
    optimized_files = []
    for f in files:
        with open(f, "r", encoding="utf-8") as file:
            code = file.read()
        try:
            response = openai.Completion.create(
                engine="text-davinci-003",
                prompt=f"Refactor, clean, and optimize this Python code for modern standards:\n\n{code}",
                temperature=0,
                max_tokens=3500
            )
            optimized_code = response.choices[0].text.strip()
            optimized_files.append((f.relative_to(PROJECT_DIR), optimized_code))
        except Exception as e:
            print(f"⚠️ خطأ في معالجة {f}: {e}")
    return optimized_files

# حفظ الملفات المحسنة مع تقرير بعدد الأسطر
def save_files(optimized_files):
    report = []
    for rel_path, code in optimized_files:
        out_path = OUTPUT_DIR / rel_path
        out_path.parent.mkdir(parents=True, exist_ok=True)
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(code)
        lines = code.count("\n") + 1
        report.append(f"{rel_path}: {lines} سطر فعلي")
    report_file = OUTPUT_DIR / "report.txt"
    with open(report_file, "w", encoding="utf-8") as f:
        f.write("\n".join(report))
    print(f"✅ العملية اكتملت! الملفات المحسنة محفوظة في {OUTPUT_DIR}")
    print(f"📄 تقرير عدد الأسطر موجود في {report_file}")

if __name__ == "__main__":
    files = gather_files()
    optimized = ai_optimize(files)
    save_files(optimized)

