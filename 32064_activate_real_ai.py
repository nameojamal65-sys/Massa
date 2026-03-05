import os
import openai  # تأكد أنك منصب مكتبة openai: pip install openai
import json

# --- إعداد المفتاح ---
OPENAI_API_KEY = "هنا_ضع_مفتاحك"
openai.api_key = OPENAI_API_KEY

# --- وظائف المنظومة ---
SYSTEM_PATH = "/home/user/sovereign_system_fixed/sovereign_system"
CAPABILITIES = ["Data Collection", "Data Processing", "Analytics", "Dashboard", "AI Engine"]

def analyze_file(file_path):
    try:
        import ast
        with open(file_path, "r", encoding="utf-8") as f:
            tree = ast.parse(f.read())
        functions = [node.name for node in ast.walk(tree) if isinstance(node, ast.FunctionDef)]
        classes = [node.name for node in ast.walk(tree) if isinstance(node, ast.ClassDef)]
        return {"functions": functions, "classes": classes}
    except:
        return {"error": "Could not parse"}

def detect_capabilities(file_name):
    caps = []
    name = file_name.lower()
    if "collect" in name or "collector" in name:
        caps.append("Data Collection")
    if "process" in name or "worker" in name or "prepare" in name:
        caps.append("Data Processing")
    if "analytics" in name or "report" in name:
        caps.append("Analytics")
    if "dashboard" in name or "view" in name or "blueprint" in name:
        caps.append("Dashboard")
    if "ai" in name or "engine" in name or "optimizer" in name or "organizer" in name:
        caps.append("AI Engine")
    if not caps:
        caps.append("Unknown")
    return caps

# --- بناء هيكل النظام ---
system_structure = {}
for root, dirs, files in os.walk(SYSTEM_PATH):
    for file in files:
        if file.endswith(".py"):
            rel_path = os.path.relpath(os.path.join(root, file), SYSTEM_PATH)
            system_structure[rel_path] = {
                "capabilities": detect_capabilities(file),
                "analysis": analyze_file(os.path.join(root, file))
            }

# --- واجهة الذكاء الاصطناعي ---
def ai_execute(prompt):
    """يرسل الطلب إلى الذكاء الاصطناعي الحقيقي ويسترجع النتيجة"""
    try:
        response = openai.ChatCompletion.create(
            model="gpt-4",  # أو gpt-4-turbo حسب المفتاح
            messages=[{"role": "user", "content": prompt}],
            temperature=0.5
        )
        return response.choices[0].message.content
    except Exception as e:
        return f"AI Error: {e}"

# --- CLI تفاعلي ---
def interactive_cli():
    while True:
        print("\nAvailable Capabilities:")
        for i, cap in enumerate(CAPABILITIES + ["Unknown"], 1):
            print(f"{i}. {cap}")
        choice = input("\nEnter capability number (or 'q' to quit): ").strip()
        if choice.lower() == "q":
            break
        if not choice.isdigit() or not (1 <= int(choice) <= len(CAPABILITIES)+1):
            print("Invalid choice, try again.")
            continue
        cap = (CAPABILITIES + ["Unknown"])[int(choice)-1]
        files = [f for f, v in system_structure.items() if cap in v["capabilities"]]
        print(f"\nFiles with capability '{cap}': ({len(files)})")
        for f in files:
            print(f" • {f}")
        
        # مثال طلب إلى الذكاء الاصطناعي
        if cap == "AI Engine":
            task = input("\nEnter AI task for real model (e.g., generate algorithm): ")
            result = ai_execute(task)
            print(f"\nAI Output:\n{result}")

if __name__ == "__main__":
    print("✅ Sovereign Real AI System Ready!")
    interactive_cli()
