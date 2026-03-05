#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

PROJECT_DIR="/data/data/com.termux/files/home/sovereign_core"
REPORT_FILE="AI_ARCHITECTURE_REPORT.md"

echo "🧠 Sovereign AI Architecture Auditor"
echo "📂 Project: $PROJECT_DIR"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "❌ Project directory not found."
  exit 1
fi

cd "$PROJECT_DIR"

source .venv/bin/activate

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "❌ Please export OPENAI_API_KEY first."
  exit 1
fi

echo "📦 Collecting project files..."

find app -type f \( -name "*.py" -o -name "*.html" -o -name "*.toml" -o -name "*.yml" -o -name "*.yaml" -o -name "requirements.txt" \) > file_list.txt

echo "🧠 Generating report with GPT..."

python <<'PY'
import os
from openai import OpenAI

client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])

project_text = ""

with open("file_list.txt") as f:
    files = f.read().splitlines()

for path in files:
    try:
        with open(path, "r", encoding="utf-8") as file:
            content = file.read()
        project_text += f"\n\n===== FILE: {path} =====\n{content}\n"
    except:
        pass

prompt = f"""
You are a senior software architect.

Analyze the following full project source code.

Provide a detailed technical architecture report including:

1. Project tree explanation
2. Architecture layers
3. Dependency flow
4. Security review
5. Missing components
6. Production readiness assessment
7. Risk analysis
8. Refactoring recommendations
9. Suggested roadmap
10. Overall maturity score (1-10)

Return a structured Markdown report.

Project Source:
{project_text}
"""

response = client.chat.completions.create(
    model="gpt-4.1",
    messages=[{"role": "user", "content": prompt}],
    temperature=0.2
)

report = response.choices[0].message.content

with open("AI_ARCHITECTURE_REPORT.md", "w", encoding="utf-8") as f:
    f.write(report)

print("✅ Report saved to AI_ARCHITECTURE_REPORT.md")
PY

echo "🎉 DONE."
echo "Open report:"
echo "cat AI_ARCHITECTURE_REPORT.md"
