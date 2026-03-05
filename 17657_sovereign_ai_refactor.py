#!/usr/bin/env python3
import os
from pathlib import Path
import openai

openai.api_key = os.environ.get("OPENAI_API_KEY", "ضع_مفتاحك_هنا")
ROOT = Path(os.getcwd())

for f in ROOT.rglob("*.py"):
    with open(f, "r") as file:
        code = file.read()
    prompt = f"Refactor this Python code for better performance and readability:\n{code}"
    try:
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.3
        )
        suggestion = response.choices[0].message.content
        print(f"📝 Suggestions for {f}:\n{suggestion}\n{'-'*40}")
    except Exception as e:
        print(f"❌ Failed on {f}: {e}")
