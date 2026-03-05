#!/usr/bin/env python3
import subprocess

packages = ["requests", "flask", "openai"]  # أضف حسب الحاجة

for pkg in packages:
    try:
        subprocess.run(["pip", "install", "--user", "--upgrade", pkg], check=True)
        print(f"✅ Installed/Updated {pkg}")
    except Exception as e:
        print(f"❌ Failed to install {pkg}: {e}")
