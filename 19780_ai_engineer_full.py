#!/usr/bin/env python3
import os
import openai
from pathlib import Path
import json
import smtplib
from email.message import EmailMessage
import datetime

# -------------------
# إعدادات المشروع
# -------------------
PROJECT_DIR = Path.home() / "sovereign_production"
OUTPUT_DIR = PROJECT_DIR / "output"
OUTPUT_DIR.mkdir(exist_ok=True)

# -------------------
# جمع ملفات المشروع
# -------------------
files = [str(f) for f in PROJECT_DIR.rglob("*.py")]
print(f"🚀 بدء جمع الملفات... 📦 عدد الملفات المكتشفة: {len(files)}")

# -------------------
# تحسين الملفات عبر AI
# -------------------
def ai_optimize(files_list):
    optimized_files = {}
    for file_path in files_list:
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()

            prompt = f"""
            أنت مهندس ذكاء اصطناعي مطور شامل لإدارة مشاريع الإنشاءات والمقاولات.
            طور الكود التالي بحيث:
            1. يمكن توليد رسومات هندسية Plan/Section/Elevation.
            2. يمكن إجراء كلكوليشن للعناصر الإنشائية مثل RAFT, Columns, Piles.
            3. يشمل Resource Management + Schedule Tracking + Alerts.
            4. التواصل الداخلي والخارجي عبر WhatsApp وEmail.
            5. نظام HR لمتابعة المصممين والموظفين.
            6. Document Control وإدارة المستندات.
            7. حافظ على وظيفة الكود الأصلي، فقط حسنه وطور إمكانياته.
            
            الكود:
            {content}
            """

            response = openai.ChatCompletion.create(
                model="gpt-4-turbo",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.3,
                max_tokens=2000
            )
            optimized_code = response.choices[0].message["content"]
            optimized_files[file_path] = optimized_code

        except Exception as e:
            print(f"⚠️ خطأ في معالجة {file_path}: {e}")

    return optimized_files

optimized = ai_optimize(files)

# -------------------
# حفظ الملفات المحسنة
# -------------------
for path, content in optimized.items():
    relative_path = Path(path).relative_to(PROJECT_DIR)
    save_path = OUTPUT_DIR / relative_path
    save_path.parent.mkdir(parents=True, exist_ok=True)
    with open(save_path, "w", encoding="utf-8") as f:
        f.write(content)

# -------------------
# تقرير عدد الأسطر
# -------------------
report_file = OUTPUT_DIR / "report.txt"
with open(report_file, "w", encoding="utf-8") as report:
    total_lines = 0
    for path, content in optimized.items():
        lines = content.count("\n") + 1
        total_lines += lines
        report.write(f"{path}: {lines} lines\n")
    report.write(f"\nTotal lines in optimized project: {total_lines}\n")

# -------------------
# مثال إرسال إشعار عبر البريد الإلكتروني
# -------------------
def send_email_alert(subject, body, to_email):
    try:
        msg = EmailMessage()
        msg.set_content(body)
        msg['Subject'] = subject
        msg['From'] = "project.alerts@sovereign.ai"
        msg['To'] = to_email

        # مثال SMTP
        with smtplib.SMTP('localhost') as s:
            s.send_message(msg)
        print(f"📧 تم إرسال الإشعار إلى {to_email}")
    except Exception as e:
        print(f"⚠️ خطأ أثناء إرسال الإيميل: {e}")

# -------------------
# حفظ التقرير النهائي
# -------------------
print(f"✅ العملية اكتملت! الملفات المحسنة محفوظة في {OUTPUT_DIR}")
print(f"📄 تقرير عدد الأسطر موجود في {report_file}")

# -------------------
# مثال تنبيه تجريبي
# -------------------
send_email_alert(
    subject="Sovereign AI: مشروع مطور",
    body=f"تم تحسين جميع ملفات المشروع بتاريخ {datetime.datetime.now()}",
    to_email="admin@sovereign.ai"
)

