#!/usr/bin/env python3
import os

# مسار المشروع
PROJECT_DIR = os.path.expanduser("~/sovereign_production")
OUTPUT_DIR = os.path.join(PROJECT_DIR, "output")
os.makedirs(OUTPUT_DIR, exist_ok=True)

report_file = os.path.join(OUTPUT_DIR, "full_report.txt")

def count_lines(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            return sum(1 for _ in f)
    except Exception:
        return 0

def scan_project(project_dir):
    results = []
    for root, dirs, files in os.walk(project_dir):
        for file in files:
            if file.endswith(".py"):
                full_path = os.path.join(root, file)
                size = os.path.getsize(full_path)
                lines = count_lines(full_path)
                results.append({
                    "path": full_path,
                    "size_bytes": size,
                    "lines": lines
                })
    return results

def save_report(results, report_path):
    total_size = sum(r["size_bytes"] for r in results)
    total_lines = sum(r["lines"] for r in results)
    with open(report_path, "w", encoding="utf-8") as f:
        f.write(f"📊 تقرير كامل مشروع Sovereign Core\n")
        f.write(f"عدد الملفات .py: {len(results)}\n")
        f.write(f"إجمالي الأسطر: {total_lines}\n")
        f.write(f"الحجم الكلي: {total_size / 1024:.2f} KB\n\n")
        f.write("تفاصيل كل ملف:\n")
        f.write("="*60 + "\n")
        for r in results:
            f.write(f"{r['path']}\n  الحجم: {r['size_bytes']/1024:.2f} KB | الأسطر: {r['lines']}\n\n")

if __name__ == "__main__":
    print("🚀 بدء فحص المشروع وحساب النتائج الحقيقية...")
    project_results = scan_project(PROJECT_DIR)
    save_report(project_results, report_file)
    print(f"✅ تم إنشاء التقرير في: {report_file}")
    print(f"📄 عدد الملفات: {len(project_results)} | إجمالي الأسطر: {sum(r['lines'] for r in project_results)}")

