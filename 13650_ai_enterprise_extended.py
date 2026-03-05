#!/usr/bin/env python3
import os
import datetime
from pathlib import Path
import openai
import smtplib
from email.message import EmailMessage
import pandas as pd

# -------------------
# إعداد المشروع
# -------------------
PROJECT_DIR = Path.home() / "sovereign_production"
OUTPUT_DIR = PROJECT_DIR / "output"
OUTPUT_DIR.mkdir(exist_ok=True)

# -------------------
# جمع ملفات المشروع
# -------------------
files = [str(f) for f in PROJECT_DIR.rglob("*.py")]
print(f"🚀 عدد الملفات المكتشفة: {len(files)}")

# -------------------
# تحسين الملفات وإضافة الميزات
# -------------------
def ai_optimize(files_list):
    optimized_files = {}
    for file_path in files_list:
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
            prompt = f"""
            طور هذا الكود ليصبح نظام مقاولات متكامل AI يشمل:
            - رسومات هندسية Plan / Section / Elevation
            - كلكوليشن للعناصر الإنشائية RAFT/Columns/Piles
            - إدارة الموارد والجدول الزمني مع Tracker وAlerts
            - تكامل مع Excel, P6, FDIC, PRO, PIP
            - إدارة RFI, OSN, IR, MIR, NOR, Shop Drawings, Material Submittals
            - متابعة Approvals حسب أسلوب الاستشاري والعقد
            - إدارة الأقسام QA/QC, Safety, Planning, QS & Contract, Procurement, Finance
            - HR System وإدارة المصممين والمقاولين
            - Document Control متقدم
            - صياغة المراسلات التعاقدية وإدارة أجندة الاجتماعات
            حافظ على وظائف الكود الأصلي وأضف هذه الميزات
            الكود الحالي:
            {content}
            """
            response = openai.ChatCompletion.create(
                model="gpt-4-turbo",
                messages=[{"role":"user","content":prompt}],
                temperature=0.3,
                max_tokens=3000
            )
            optimized_files[file_path] = response.choices[0].message["content"]
        except Exception as e:
            print(f"⚠️ خطأ في معالجة {file_path}: {e}")
    return optimized_files

optimized = ai_optimize(files)

# -------------------
# حفظ الملفات المحسنة
# -------------------
for path, content in optimized.items():
    save_path = OUTPUT_DIR / Path(path).relative_to(PROJECT_DIR)
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
        lines = content.count("\n")+1
        total_lines += lines
        report.write(f"{path}: {lines} lines\n")
    report.write(f"\nTotal lines in optimized project: {total_lines}\n")

# -------------------
# إرسال تنبيهات للأقسام
# -------------------
departments = [
    "qa-qc@sovereign.ai", "safety@sovereign.ai", "planning@sovereign.ai",
    "contract@sovereign.ai", "procurement@sovereign.ai", "finance@sovereign.ai"
]

def send_email_alert(subject, body, to_email):
    try:
        msg = EmailMessage()
        msg.set_content(body)
        msg['Subject'] = subject
        msg['From'] = "project.alerts@sovereign.ai"
        msg['To'] = to_email
        with smtplib.SMTP('localhost') as s:
            s.send_message(msg)
        print(f"📧 تم إرسال الإشعار إلى {to_email}")
    except Exception as e:
        print(f"⚠️ خطأ أثناء إرسال الإيميل: {e}")

for dept in departments:
    send_email_alert(
        subject="Sovereign AI: Project Update",
        body=f"تم تحسين الملفات وتوسيع النظام بتاريخ {datetime.datetime.now()}",
        to_email=dept
    )

print(f"✅ العملية اكتملت! الملفات المحسنة في {OUTPUT_DIR}")
print(f"📄 تقرير عدد الأسطر موجود في {report_file}")

