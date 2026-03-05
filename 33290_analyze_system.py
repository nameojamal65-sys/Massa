#!/usr/bin/env python3
import os

# ───── مجلدات المنظومة الأساسية ─────
folders = ["core", "agents", "pipelines", "security", "reports"]

def analyze_system(base_dir="."):
    total_size = 0
    total_files = 0
    total_lines = 0
    report = []

    for folder in folders:
        folder_path = os.path.join(base_dir, folder)
        if not os.path.exists(folder_path):
            report.append(f"[WARN] المجلد مفقود: {folder}")
            continue

        folder_size = 0
        folder_files = 0
        folder_lines = 0

        for root, dirs, files in os.walk(folder_path):
            for f in files:
                filepath = os.path.join(root, f)
                try:
                    folder_size += os.path.getsize(filepath)
                    folder_files += 1
                    if f.endswith(".py"):
                        with open(filepath, "r", encoding="utf-8") as file:
                            lines = file.readlines()
                            folder_lines += len(lines)
                except Exception as e:
                    report.append(f"[ERROR] فشل قراءة {filepath}: {e}")

        total_size += folder_size
        total_files += folder_files
        total_lines += folder_lines

        report.append(f"[INFO] {folder}: {folder_files} ملف، {folder_lines} سطر كود، {folder_size/1024:.2f} KB")

    report.append(f"\n[SUMMARY] المنظومة متماسكة: {'✅' if total_files>0 else '❌'}")
    report.append(f"[SUMMARY] إجمالي الملفات: {total_files}")
    report.append(f"[SUMMARY] إجمالي الأسطر: {total_lines}")
    report.append(f"[SUMMARY] إجمالي الحجم: {total_size/1024:.2f} KB ({total_size/(1024*1024):.2f} MB)")

    return "\n".join(report)

if __name__ == "__main__":
    print(analyze_system())
