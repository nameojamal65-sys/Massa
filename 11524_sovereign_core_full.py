#!/data/data/com.termux/files/usr/bin/python3

from flask import Flask, request, jsonify
import requests
import os

app = Flask(__name__)

DATA_STORAGE = {}

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

def external_ai_query(prompt):
    url = "https://api.openai.com/v1/chat/completions"

    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": "gpt-4o-mini",
        "messages": [
            {"role": "system", "content": "You are an autonomous execution AI."},
            {"role": "user", "content": prompt}
        ]
    }

    response = requests.post(url, headers=headers, json=payload)

    if response.status_code == 200:
        return response.json()["choices"][0]["message"]["content"]
    else:
        return response.text

@app.route("/task/external_ai_chat", methods=["POST"])
def api_external_ai_chat():
    query = request.json.get("query", "")
    mode = request.json.get("mode", "execute")

    result = external_ai_query(query)

    DATA_STORAGE['last_external_ai'] = result

    return jsonify({
        "status": "success",
        "mode": mode,
        "response": result
    })

@app.route("/data", methods=["GET"])
def get_data():
    return jsonify(DATA_STORAGE)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
