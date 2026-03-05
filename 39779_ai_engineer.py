#!/usr/bin/env python3
import os
import openai
from pathlib import Path
import json

# مفتاح API موجود مسبقًا في المتغير OPENAI_API_KEY
# os.environ["OPENAI_API_KEY"] = "ضع_مفتاحك_هنا" # غير مطلوب إذا المفتاح موجود

PROJECT_DIR = Path.home() / "sovereign_production"
OUTPUT_DIR = PROJECT_DIR / "output"
OUTPUT_DIR.mkdir(exist_ok=True)

# جمع كل ملفات المشروع
files = []
for path in PROJECT_DIR.rglob("*.py"):
    files.append(str(path))

print(f"🚀 بدء جمع الملفات... 📦 عدد الملفات المكتشفة: {len(files)}")

# دالة إرسال الملفات للذكاء الاصطناعي لتحسين وتطوير المنظومة
def ai_optimize(files_list):
    optimized_files = {}
    for file_path in files_list:
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            
            prompt = f"""
            أنت مهندس ذكاء اصطناعي مطور للمشاريع الإنشائية والمقاولات.
            حسّن الكود التالي بحيث:
            1. يمكن توليد رسومات هندسية Plan/Section/Elevation.
            2. يمكن إجراء كلكوليشن للعناصر الإنشائية مثل RAFT, Columns, Piles.
            3. يمكن إنشاء Dashboard لمتابعة المشاريع والمصممين والـ stakeholders.
            4. استخدم أحدث مكتبات Python المناسبة.
            لا تغير وظيفة الكود الأصلي، فقط حسنه وطور إمكانياته.
            
            الكود:
            {content}
            """

            response = openai.ChatCompletion.create(
                model="gpt-4-turbo",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.3,
                max_tokens=1500
            )
            optimized_code = response.choices[0].message["content"]
            optimized_files[file_path] = optimized_code

        except Exception as e:
            print(f"⚠️ خطأ في معالجة {file_path}: {e}")

    return optimized_files

# تنفيذ تحسين الملفات
optimized = ai_optimize(files)

# حفظ الملفات المحسنة
for path, content in optimized.items():
    relative_path = Path(path).relative_to(PROJECT_DIR)
    save_path = OUTPUT_DIR / relative_path
    save_path.parent.mkdir(parents=True, exist_ok=True)
    with open(save_path, "w", encoding="utf-8") as f:
        f.write(content)

# إنشاء تقرير عدد الأسطر
report_file = OUTPUT_DIR / "report.txt"
with open(report_file, "w", encoding="utf-8") as report:
    total_lines = 0
    for path, content in optimized.items():
        lines = content.count("\n") + 1
        total_lines += lines
        report.write(f"{path}: {lines} lines\n")
    report.write(f"\nTotal lines in optimized project: {total_lines}\n")

print(f"✅ العملية اكتملت! الملفات المحسنة محفوظة في {OUTPUT_DIR}")
print(f"📄 تقرير عدد الأسطر موجود في {report_file}")

