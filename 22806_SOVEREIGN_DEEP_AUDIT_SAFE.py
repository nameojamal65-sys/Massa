#!/usr/bin/env python3
import os
from pathlib import Path

# ==============================
# CONFIG
# ==============================

PROJECT_ROOT = Path.home() / "Legendary_UltraLight"
EXCLUDE_DIRS = {"backup", "__pycache__", ".git"}
CODE_EXTENSIONS = {".py", ".js", ".ts", ".sh", ".html", ".css"}

# ==============================
# SAFE UTILITIES
# ==============================

def is_binary(file_path):
    try:
        with open(file_path, "rb") as f:
            chunk = f.read(1024)
            if b"\0" in chunk:
                return True
    except Exception:
        return True
    return False


def safe_stat(path):
    try:
        return path.stat().st_size
    except Exception:
        return 0


def safe_line_count(path):
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            return sum(1 for _ in f)
    except Exception:
        return 0


# ==============================
# ANALYSIS
# ==============================

def analyze():

    if not PROJECT_ROOT.exists():
        print("❌ المشروع غير موجود")
        return

    total_files = 0
    total_size = 0
    total_code_lines = 0
    binary_files = 0
    code_files = 0

    print("🔍 بدء التدقيق العميق الآمن...\n")

    for root, dirs, files in os.walk(PROJECT_ROOT):

        # منع الشلال نهائياً
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]

        for file in files:
            path = Path(root) / file

            try:
                total_files += 1
                total_size += safe_stat(path)

                if is_binary(path):
                    binary_files += 1
                else:
                    if path.suffix in CODE_EXTENSIONS:
                        code_files += 1
                        total_code_lines += safe_line_count(path)

            except Exception:
                continue

    # ==============================
    # REPORT
    # ==============================

    print("📊 تقرير المنظومة")
    print("=" * 40)
    print(f"📂 المسار: {PROJECT_ROOT}")
    print(f"📁 عدد الملفات: {total_files}")
    print(f"💾 الحجم الكلي: {round(total_size / (1024*1024), 2)} MB")
    print(f"🧠 ملفات كود: {code_files}")
    print(f"📝 أسطر الكود الفعلية: {total_code_lines}")
    print(f"⚙️ ملفات باينري: {binary_files}")
    print("=" * 40)

    if binary_files > 0:
        print("🧩 تحتوي على ملفات تنفيذية / باينري")
    else:
        print("📄 المنظومة نصية بالكامل (غير باينري)")

    print("\n✅ انتهى التدقيق بأمان.")


if __name__ == "__main__":
    analyze()
