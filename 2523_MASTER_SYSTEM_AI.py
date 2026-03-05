#!/data/data/com.termux/files/usr/bin/python3
# MASTER SYSTEM AI 3.0 - SOVEREIGN

import os
import shutil
import datetime
import json
from pathlib import Path
import concurrent.futures

# -------------------------
# النظام الذكي AI
# -------------------------
class SystemAI:
    def __init__(self):
        self.rules = []

    def add_rule(self, description, action):
        """إضافة قاعدة ذكاء اصطناعي لكل ملف أو مجلد"""
        self.rules.append({"description": description, "action": action})

    def evaluate(self, path: Path):
        """تقييم كل ملف/مجلد وتنظيمه حسب القواعد"""
        results = []
        for rule in self.rules:
            try:
                result = rule["action"](path)
                if result:
                    results.append(result)
            except Exception as e:
                results.append(f"Error on {path.name}: {e}")
        return results

# -------------------------
# وظائف النظام الأساسية
# -------------------------
def organize_file(path: Path):
    """نقل الملفات الكبيرة والقديمة والغير ضرورية"""
    try:
        if not path.exists():
            return None
        size = path.stat().st_size
        mtime = path.stat().st_mtime
        now = datetime.datetime.now().timestamp()

        # الملفات الكبيرة >10 ميجا
        if size > 10_000_000:
            dest_folder = path.parent / "LARGE_FILES"
            dest_folder.mkdir(exist_ok=True)
            shutil.move(str(path), dest_folder / path.name)
            return f"Moved {path.name} to LARGE_FILES"

        # الملفات القديمة >30 يوم
        elif now - mtime > 30*24*3600:
            old_folder = path.parent / "OLD_FILES"
            old_folder.mkdir(exist_ok=True)
            shutil.move(str(path), old_folder / path.name)
            return f"Moved {path.name} to OLD_FILES"

        # حذف الملفات الغير ضرورية (temp / log)
        elif path.suffix in (".log", ".tmp") or path.name.startswith("temp"):
            path.unlink()
            return f"Deleted {path.name}"

    except Exception as e:
        return f"Failed {path.name}: {e}"
    return None

def backup_folder(source: Path, destination: Path):
    """نسخ احتياطي آمن ومتعدد الخيوط"""
    ignore_patterns = shutil.ignore_patterns(
        "backup*", "*.agent.*", "socket*", "temp*", ".ssh/*"
    )

    def copy_item(item: Path):
        try:
            if item.is_dir():
                shutil.copytree(item, destination / item.name, ignore=ignore_patterns)
            else:
                shutil.copy2(item, destination / item.name)
            return f"Copied {item.name}"
        except Exception as e:
            return f"Error {item.name}: {e}"

    items = [i for i in source.iterdir() if i.name not in ("SYSTEM_BACKUPS",)]
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        futures = [executor.submit(copy_item, item) for item in items]
        return [f.result() for f in concurrent.futures.as_completed(futures)]

# -------------------------
# تنفيذ النظام MASTER AI 3.0
# -------------------------
def master_system(source_path: str):
    source = Path(source_path)
    destination = Path(f"/data/data/com.termux/files/home/SYSTEM_BACKUPS/master_{datetime.datetime.now():%Y%m%d_%H%M%S}")
    destination.mkdir(parents=True, exist_ok=True)

    print("🚀 بدء النظام الذكي MASTER AI 3.0 ...")
    print(f"📂 المصدر: {source}")
    print(f"💾 الوجهة: {destination}")

    # 1. النسخ الاحتياطي
    backup_results = backup_folder(source, destination)

    # 2. الذكاء الاصطناعي لترتيب الملفات
    ai = SystemAI()
    ai.add_rule("Move large/old/temp files", organize_file)

    ai_results = []
    for root, dirs, files in os.walk(destination):
        # تجاهل مجلدات backup القديمة لتجنب اسم طويل جدًا
        if "backup" in dirs:
            dirs.remove("backup")
        for name in files:
            path = Path(root) / name
            ai_results.extend(ai.evaluate(path))

    # 3. Hardening كامل: تصاريح الملفات
    for path in destination.rglob("*"):
        try:
            if path.is_file():
                path.chmod(0o644)  # ملفات
            elif path.is_dir():
                path.chmod(0o755)  # مجلدات
        except:
            continue

    # 4. التقرير النهائي
    report = {
        "backup": backup_results,
        "ai_actions": ai_results,
        "timestamp": str(datetime.datetime.now())
    }

    report_file = destination / "SYSTEM_REPORT.json"
    with open(report_file, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=4, ensure_ascii=False)

    print(f"✅ النظام اكتمل! التقرير موجود في: {report_file}")
    os.system(f"cat {report_file}")

    return report_file

# -------------------------
# تشغيل السكريبت
# -------------------------
if __name__ == "__main__":
    master_system("/data/data/com.termux/files/home/Legendary_UltraLight")
