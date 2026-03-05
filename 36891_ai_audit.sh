#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPORT_FILE="AI_ARCHITECTURE_REPORT.md"
TMP_DIR=".ai_audit_tmp"

# تأكد أننا داخل جذر المشروع (وجود app/)
if [ ! -d "app" ]; then
  echo "❌ Run this script from project root (folder containing ./app)."
  exit 1
fi

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "❌ OPENAI_API_KEY not set in environment."
  exit 1
fi

# فعّل البيئة إن كانت موجودة
if [ -f ".venv/bin/activate" ]; then
  # shellcheck disable=SC1091
  source .venv/bin/activate
fi

mkdir -p "$TMP_DIR"

echo "📦 Collecting file list..."
find app -type f \( -name "*.py" -o -name "*.html" -o -name "*.toml" -o -name "*.yml" -o -name "*.yaml" -o -name "requirements.txt" \) \
  -not -path "*/__pycache__/*" \
  -print | sort > "$TMP_DIR/files.txt"

echo "🧠 Running layered analysis (safe size chunks)..."

python - <<'PY'
import os
from pathlib import Path
from openai import OpenAI

client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])

TMP_DIR = Path(".ai_audit_tmp")
files = (TMP_DIR / "files.txt").read_text().splitlines()

# خريطة طبقات لتقليل حجم الإرسال وتحسين جودة التقرير
groups = {
    "01_core": [p for p in files if p.startswith("app/core/")],
    "02_db": [p for p in files if p.startswith("app/db/")],
    "03_schemas": [p for p in files if p.startswith("app/schemas/")],
    "04_services": [p for p in files if p.startswith("app/services/")],
    "05_api": [p for p in files if p.startswith("app/api/")],
    "06_workers": [p for p in files if p.startswith("app/workers/")],
    "07_web_ui": [p for p in files if p.startswith("app/web/")],
    "08_tests": [p for p in files if p.startswith("app/tests/")],
    "09_main": [p for p in files if p == "app/main.py"],
}

def read_files(paths):
    parts = []
    for path in paths:
        try:
            content = Path(path).read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue
        parts.append(f"\n\n===== FILE: {path} =====\n{content}\n")
    return "".join(parts)

def ask(title, body):
    prompt = f"""
You are a senior software architect.

Analyze ONLY this subset of the project: {title}

Deliver:
- What this layer does
- Key components and responsibilities
- Notable design patterns
- Issues / smells / risks
- Security & correctness concerns
- Recommendations (actionable)

Return Markdown. Be concise but concrete.
"""
    r = client.chat.completions.create(
        model="gpt-4.1-mini",
        messages=[
            {"role": "user", "content": prompt},
            {"role": "user", "content": body},
        ],
        temperature=0.2,
    )
    return r.choices[0].message.content

layer_reports = []
for name, paths in groups.items():
    if not paths:
        continue
    text = read_files(paths)

    # حماية: لا نرسل كمية ضخمة جدًا دفعة واحدة
    # إذا الطبقة كبيرة، نقسمها إلى دفعات ~8 ملفات
    if len(paths) > 8:
        chunks = [paths[i:i+8] for i in range(0, len(paths), 8)]
        chunk_summaries = []
        for idx, ch in enumerate(chunks, 1):
            chunk_text = read_files(ch)
            chunk_summaries.append(ask(f"{name} (chunk {idx}/{len(chunks)})", chunk_text))
        merged = "\n\n".join(chunk_summaries)
        layer_reports.append(f"## Layer: {name}\n\n{merged}")
    else:
        layer_reports.append(f"## Layer: {name}\n\n{ask(name, text)}")

(TMP_DIR / "layers.md").write_text("\n\n".join(layer_reports), encoding="utf-8")

# المرحلة الأخيرة: توليد تقرير معماري شامل اعتمادًا على summaries (بدون إعادة إرسال كامل الكود)
final_prompt = f"""
You are a principal software architect.

You have layer-by-layer audit notes below. Create a single, high-quality, production-grade Architecture Review report.

Must include:
1) Executive summary
2) Project architecture map (layers + flows)
3) Strengths (what is already good)
4) Gaps / missing parts (prioritized)
5) Security review (authn/authz, secrets, CORS, rate limiting, file upload risks, task worker safety)
6) Reliability & ops (logging, metrics, tracing, health/readiness, retries, idempotency)
7) Testing strategy review
8) Refactor plan (concrete steps + suggested file/module moves if needed)
9) Roadmap (3 phases: Stabilize, Harden, Scale)
10) Maturity score (1–10) with justification

Write in Markdown with headings and bullet points.
Use practical recommendations suitable for FastAPI + Termux/dev environment.
"""

layers_md = (TMP_DIR / "layers.md").read_text(encoding="utf-8", errors="replace")

resp = client.chat.completions.create(
    model="gpt-4.1",
    messages=[
        {"role": "user", "content": final_prompt},
        {"role": "user", "content": layers_md},
    ],
    temperature=0.2,
)

Path("AI_ARCHITECTURE_REPORT.md").write_text(resp.choices[0].message.content, encoding="utf-8")
print("✅ Wrote AI_ARCHITECTURE_REPORT.md")
PY

echo "🎉 DONE."
echo "View:"
echo "  less -R $REPORT_FILE"
