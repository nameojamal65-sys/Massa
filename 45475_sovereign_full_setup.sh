#!/data/data/com.termux/files/usr/bin/bash

echo "🚀 Starting Sovereign Full System Setup..."

# --- 1️⃣ Python AI Engine ---
PYTHON_FILE="$HOME/sovereign_ai_full.py"
if [ ! -f "$PYTHON_FILE" ]; then
    cat << 'EOF' > "$PYTHON_FILE"
#!/data/data/com.termux/files/usr/bin/python3
import sys, os, threading, json, requests
from flask import Flask, jsonify, request
import numpy as np
import sympy as sp

sys.set_int_max_str_digits(1000000)

app = Flask(__name__)
DATA_STORAGE = {}

def heavy_math_task(n):
    return sum(i**2 for i in range(n))

def ai_generate_formula(x):
    expr = sp.symbols('x')
    formula = sp.sin(expr)*sp.exp(expr)
    return sp.integrate(formula, expr).subs(expr, x)

def fetch_web_data(url):
    try:
        r = requests.get(url, timeout=5)
        return r.text[:1000]
    except:
        return "Error fetching data"

@app.route("/task/heavy_math", methods=["POST"])
def api_heavy_math():
    n = int(request.json.get("n", 1000))
    result = heavy_math_task(n)
    DATA_STORAGE['last_heavy_math'] = result
    return jsonify({"result": result})

@app.route("/task/ai_formula", methods=["POST"])
def api_ai_formula():
    x = float(request.json.get("x", 1))
    result = ai_generate_formula(x)
    DATA_STORAGE['last_ai_formula'] = str(result)
    return jsonify({"result": str(result)})

@app.route("/task/fetch_web", methods=["POST"])
def api_fetch_web():
    url = request.json.get("url", "https://example.com")
    result = fetch_web_data(url)
    DATA_STORAGE['last_web'] = result
    return jsonify({"result": result})

@app.route("/data", methods=["GET"])
def api_data():
    return jsonify(DATA_STORAGE)

def start_server():
    app.run(host="0.0.0.0", port=5000, debug=False)

if __name__ == "__main__":
    print("✅ Sovereign AI Full System Ready!")
    threading.Thread(target=start_server).start()
EOF
    chmod +x "$PYTHON_FILE"
    echo "🔹 Python AI Engine created."
else
    echo "🔹 Python AI Engine already exists."
fi

# --- 2️⃣ React Dashboard Setup ---
DASHBOARD_DIR="$HOME/sovereign_dashboard"
if [ ! -d "$DASHBOARD_DIR" ]; then
    echo "🔹 Creating Sovereign Dashboard (React + Vite)..."
    npx create-vite sovereign_dashboard --template react
    cd sovereign_dashboard || exit
    npm install axios
    sed -i '/"scripts": {/a\    "dev": "vite",' package.json
else
    echo "🔹 Sovereign Dashboard already exists."
    cd sovereign_dashboard || exit
fi

# --- 3️⃣ Run Servers ---
echo "🔹 Starting Python AI Engine..."
python3 "$PYTHON_FILE" &

echo "🔹 To start React Dashboard, run:"
echo "cd ~/sovereign_dashboard && npm run dev"
echo "🌐 Dashboard should open at http://127.0.0.1:5173"

echo "✅ Setup Complete. All systems ready!"
