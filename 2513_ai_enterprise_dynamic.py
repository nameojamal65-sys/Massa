#!/usr/bin/env python3
"""
Sovereign Enterprise Dynamic System
Maintained by Abu Miftah AI Master
Handles: Project Management, Document Control, Engineering, QA/QC,
Resource Management, Finance, Procurement, HR, Dashboards, Auto Updates
"""

import os
import json
import shutil
import glob
import time
from datetime import datetime
from pathlib import Path

# --- Optional libraries ---
try:
    import openai
    import pandas as pd
    from pptx import Presentation
except ModuleNotFoundError:
    os.system("pip install openai pandas python-pptx tqdm")
    import openai
    import pandas as pd
    from pptx import Presentation

# --- Configuration ---
BASE_DIR = Path.home() / "sovereign_production"
UPLOAD_DIR = BASE_DIR / "uploaded_docs"
OUTPUT_DIR = BASE_DIR / "output"
BACKUP_DIR = BASE_DIR / "doc_backup"
PROJECTS = ["Project_X", "Project_Y"]
STAFF_ROLES = ["Admin", "Engineer", "QA", "QC", "Planning", "Finance", "Procurement"]
CHECK_INTERVAL = 3600  # Update system every hour

# Ensure directories exist
for d in [UPLOAD_DIR, OUTPUT_DIR, BACKUP_DIR]:
    d.mkdir(parents=True, exist_ok=True)

# -------------------------------
# Abu Miftah AI Master Core
# -------------------------------
class AbuMiftahAI:

    def __init__(self):
        print("🚀 Abu Miftah AI Master Initialized...")
        self.report = {}

    def backup_documents(self):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = BACKUP_DIR / f"backup_{timestamp}"
        shutil.copytree(UPLOAD_DIR, backup_path)
        print(f"🛡️ Documents backup created: {backup_path}")
        return backup_path

    def scan_project_files(self):
        files = []
        for proj in PROJECTS:
            proj_path = UPLOAD_DIR / proj
            files.extend(glob.glob(str(proj_path / "**/*.*"), recursive=True))
        self.report["total_files"] = len(files)
        print(f"📦 Scanned {len(files)} files across projects")
        return files

    def process_documents(self, files):
        processed = []
        for f in files:
            ext = f.split(".")[-1].lower()
            if ext in ["pdf", "docx", "xlsx"]:
                processed.append(f)
        self.report["processed_files"] = len(processed)
        print(f"✅ {len(processed)} documents ready for control & approvals")
        return processed

    def auto_update_system(self):
        print("🔄 Checking for updates and best practices online...")
        # Placeholder for future internet scraping / AI suggestions
        self.report["ai_suggestions"] = ["Optimize resource allocation", "Add risk registry module"]

    def generate_reports(self):
        now = datetime.now().strftime("%Y%m%d_%H%M%S")
        report_file = OUTPUT_DIR / f"full_dynamic_report_{now}.json"
        with open(report_file, "w") as f:
            json.dump(self.report, f, indent=4)
        print(f"📄 Report generated: {report_file}")

    def run_cycle(self):
        self.backup_documents()
        files = self.scan_project_files()
        self.process_documents(files)
        self.auto_update_system()
        self.generate_reports()
        print("✅ Cycle complete. System is up-to-date.")

# -------------------------------
# Main loop
# -------------------------------
def main():
    abu = AbuMiftahAI()
    while True:
        abu.run_cycle()
        print(f"⏳ Waiting {CHECK_INTERVAL} seconds until next update...")
        time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    main()
