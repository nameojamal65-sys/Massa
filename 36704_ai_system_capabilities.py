#!/usr/bin/env python3
import os

# مسار المشروع
PROJECT_DIR = os.path.expanduser("~/sovereign_production")
OUTPUT_DIR = os.path.join(PROJECT_DIR, "output")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# قائمة أقسام المشروع
sections = ["app/core", "app/api", "app/ai", "app/web", "ui", "modules", "engine", "security", "config", "core"]

# قدرات المنظومة الحالية
capabilities = [
    "جمع البيانات Data Collection",
    "معالجة البيانات Data Processing",
    "تحليلات Analytics",
    "محرك ذكاء اصطناعي AI Engine",
    "إنتاج تقارير يومية، أسبوعية، شهرية",
    "توليد برزنتيشن PowerPoint",
    "إدارة المشاريع Projects Management",
    "تتبع الموارد Resource & Inventory Tracking",
    "نظام تنبيهات Alerts & Notifications",
    "تكامل مع الجداول الزمنية والتخطيط Planning",
    "نظام QA/QC و Contract Management",
    "نظام HR و Job Description و Training",
    "تتبع وادارة RFI, MIR, IR, Logs, Submittals",
    "إنتاج رسومات هندسية Sections, Elevations, Plans",
    "دعم الإدارة المالية Finance & Procurement",
    "دعم التواصل Email & WhatsApp Integration",
    "لوحات تحكم Dashboard (قيد التطوير)",
]

report_file = os.path.join(OUTPUT_DIR, "system_capabilities_report.txt")

with open(report_file, "w", encoding="utf-8") as f:
    f.write("🚀 تقرير قدرات منظومة Sovereign Core\n")
    f.write("="*50 + "\n\n")
    f.write("📌 قدرات المنظومة الحالية:\n\n")
    for idx, cap in enumerate(capabilities, start=1):
        f.write(f"{idx}. {cap}\n")
    f.write("\n📌 حجم الملفات وأقسام المشروع:\n")
    for section in sections:
        section_path = os.path.join(PROJECT_DIR, section)
        if os.path.exists(section_path):
            size = os.popen(f"du -sh {section_path}").read().strip()
            f.write(f"- {section}: {size}\n")
        else:
            f.write(f"- {section}: لا يوجد\n")

print(f"✅ تقرير القدرات جاهز في: {report_file}")
