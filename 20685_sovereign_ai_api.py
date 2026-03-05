from flask import Flask, request, jsonify
import openai

app = Flask(__name__)
openai.api_key = "هنا_ضع_مفتاحك"

@app.route("/ai_task", methods=["POST"])
def ai_task():
    data = request.json
    task = data.get("task", "")
    try:
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[{"role": "user", "content": task}],
            temperature=0.5
        )
        output = response.choices[0].message.content
        return jsonify({"output": output})
    except Exception as e:
        return jsonify({"error": str(e)})

if __name__ == "__main__":
    app.run(port=5000)
