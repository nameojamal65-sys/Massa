import os
import shutil
from openai import OpenAI
from app.core.config import settings

client = OpenAI(api_key=settings.OPENAI_API_KEY)

PROJECT_ROOT = os.path.abspath(".")

def backup_file(path):
    shutil.copy(path, path + ".bak")

def modify_file(path: str, instruction: str):
    full_path = os.path.join(PROJECT_ROOT, path)
    if not os.path.exists(full_path):
        return {"error": "File not found"}

    with open(full_path, "r") as f:
        content = f.read()

    prompt = f"""
You are a senior Python engineer.
Modify the following file according to instruction.
Instruction:
{instruction}

File:
{content}
Return full modified file only.
"""

    response = client.chat.completions.create(
        model="gpt-4.1-mini",
        messages=[{"role": "user", "content": prompt}]
    )

    new_code = response.choices[0].message.content

    backup_file(full_path)

    with open(full_path, "w") as f:
        f.write(new_code)

    return {"status": "modified"}
