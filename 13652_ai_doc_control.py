#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Abu Miftah Smart Document Control
نظام Upload, Approval, Tracking للوثائق بين المقاول، المالك، والاستشاري
"""

import os
import json
from pathlib import Path
from datetime import datetime
import shutil
import openai

# مفتاح OpenAI موجود مسبقًا في البيئة
openai.api_key = os.getenv("OPENAI_API_KEY")

PROJECT_DIR = Path.home() / "sovereign_production"
DOCS_DIR = PROJECT_DIR / "documents"
OUTPUT_DIR = PROJECT_DIR / "output"
BACKUP_DIR = PROJECT_DIR / "doc_backup"
for d in [DOCS_DIR, OUTPUT_DIR, BACKUP_DIR]:
    d.mkdir(exist_ok=True)

# تعريف المستخدمين والصلاحيات
USERS = {
    "admin": {"role": "Project Manager", "permissions": "all"},
    "owner1": {"role": "Owner", "permissions": ["approve", "comment"]},
    "owner2": {"role": "Owner", "permissions": ["approve", "comment"]},
    "consultant": {"role": "Consultant", "permissions": ["approve", "comment", "assist"]},
    "staff": {"role": "Staff", "permissions": ["upload", "view"]},
}

# نسخ احتياطي تلقائي للوثائق
def backup_docs():
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = BACKUP_DIR / f"backup_{timestamp}"
    shutil.copytree(DOCS_DIR, backup_path, dirs_exist_ok=True)
    print(f"🛡️ نسخة احتياطية للوثائق أنشئت في: {backup_path}")

# رفع وثيقة
def upload_document(user, project, file_path, doc_type):
    project_dir = DOCS_DIR / project
    project_dir.mkdir(exist_ok=True)
    dest = project_dir / f"{datetime.now().strftime('%Y%m%d_%H%M%S')}_{Path(file_path).name}"
    shutil.copy(file_path, dest)
    print(f"✅ {user} رفع الوثيقة {dest}")
    log_action(user, project, dest, "upload", doc_type)
    return dest

# تسجيل كل العمليات
LOG_FILE = OUTPUT_DIR / "document_control_log.json"
def log_action(user, project, file_path, action, doc_type, comments=""):
    log_entry = {
        "timestamp": datetime.now().isoformat(),
        "user": user,
        "project": project,
        "file": str(file_path),
        "action": action,
        "doc_type": doc_type,
        "comments": comments
    }
    logs = []
    if LOG_FILE.exists():
        with LOG_FILE.open("r", encoding="utf-8") as f:
            logs = json.load(f)
    logs.append(log_entry)
    with LOG_FILE.open("w", encoding="utf-8") as f:
        json.dump(logs, f, ensure_ascii=False, indent=2)

# إرسال وثيقة للمراجعة والموافقة
def request_approval(file_path, reviewers):
    for reviewer in reviewers:
        print(f"📤 تم إرسال {file_path} للمراجعة من {reviewer}")

# معالجة الردود
def process_approval(file_path, reviewer, decision, comments=""):
    log_action(reviewer, "N/A", file_path, f"decision_{decision}", "approval", comments)
    print(f"✅ {reviewer} قام بـ {decision} على {file_path} مع الملاحظات: {comments}")

# Main
def main():
    print("🚀 Abu Miftah Smart Document Control System Starting...")
    backup_docs()

    # مثال عملي: رفع وثيقة
    doc = upload_document("staff", "Project_X", "/sdcard/sample_drawing.pdf", "Drawing")
    
    # إرسال الوثيقة للمراجعة
    request_approval(doc, ["owner1", "consultant"])
    
    # معالجة الردود
    process_approval(doc, "owner1", "approved", "Looks good")
    process_approval(doc, "consultant", "approved", "Approved with assist notes")

if __name__ == "__main__":
    main()

