#!/data/data/com.termux/files/usr/bin/bash

# ================= إعداد المتغيرات =================
BASE="$HOME/Legendary_Dashboard/v6"
BACK="$BASE/backend"
FRONT="$BASE/frontend"
PORT=9000
FRONT_PORT=3000

# ================= إنشاء الهيكل إذا لم يكن موجود =================
mkdir -p "$BACK"
mkdir -p "$FRONT"

# ================= تثبيت المتطلبات =================
echo "📦 تثبيت المتطلبات..."
pkg install -y python git net-tools
pip install --upgrade pip
pip install fastapi uvicorn psutil aiosqlite websockets --quiet

# ================= Backend =================
echo "📁 إنشاء Backend..."
cat > "$BACK/main.py" << 'EOF'
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
import psutil, time, asyncio

app = FastAPI(title="Legendary AI Engine v6 Realtime")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

start_time = time.time()

async def ai_model(text: str):
    await asyncio.sleep(0.3)
    return f"🧠 AI Realtime Response to: {text}"

@app.get("/")
async def root():
    return {"status": "Legendary AI v6 Realtime Running"}

@app.get("/metrics")
async def metrics():
    return {
        "cpu": psutil.cpu_percent(),
        "memory": psutil.virtual_memory().percent,
        "uptime": round(time.time() - start_time, 2)
    }

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    while True:
        try:
            data = await websocket.receive_text()
            response = await ai_model(data)
            await websocket.send_text(response)
        except:
            break
EOF

# ================= Frontend =================
echo "📁 إنشاء Frontend..."
cat > "$FRONT/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Legendary Dashboard v6 Realtime</title>
<script src="https://unpkg.com/react@18/umd/react.development.js"></script>
<script src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
<script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
<style>
body { font-family: Arial; background: #111; color: white; text-align: center; }
input { padding: 10px; width: 300px; }
button { padding: 10px 20px; margin: 10px; }
.card { background: #222; padding: 20px; margin: 20px auto; width: 400px; border-radius: 10px; }
</style>
</head>
<body>
<div id="root"></div>
<script type="text/babel">
function App() {
  const [input, setInput] = React.useState("");
  const [response, setResponse] = React.useState("");
  const [metrics, setMetrics] = React.useState({});
  const wsRef = React.useRef(null);

  React.useEffect(() => {
    const ws = new WebSocket('ws://127.0.0.1:9000/ws');
    ws.onmessage = (event) => setResponse(event.data);
    wsRef.current = ws;

    const interval = setInterval(async () => {
      const res = await fetch('http://127.0.0.1:9000/metrics');
      const data = await res.json();
      setMetrics(data);
    }, 2000);

    return () => { ws.close(); clearInterval(interval); };
  }, []);

  const sendMessage = () => {
    if(wsRef.current && input.trim() !== ""){
      wsRef.current.send(input);
      setInput("");
    }
  };

  return (
    <div>
      <h1>🔥 Legendary AI Dashboard v6 Realtime</h1>
      <div className="card">
        <h3>AI Realtime Analysis</h3>
        <input value={input} onChange={e => setInput(e.target.value)} placeholder="اكتب طلبك..." />
        <br/>
        <button onClick={sendMessage}>إرسال</button>
        <p>{response}</p>
      </div>
      <div className="card">
        <h3>Live Metrics</h3>
        <p>CPU: {metrics.cpu}</p>
        <p>Memory: {metrics.memory}</p>
        <p>Uptime: {metrics.uptime}</p>
      </div>
    </div>
  );
}
ReactDOM.createRoot(document.getElementById('root')).render(<App />);
</script>
</body>
</html>
EOF

# ================= إيقاف أي نسخ سابقة =================
echo "🛑 إيقاف أي نسخ سابقة..."
pkill -f uvicorn >/dev/null 2>&1
pkill -f python3 -m http.server >/dev/null 2>&1

# ================= تشغيل Backend =================
echo "🚀 تشغيل Backend..."
cd "$BACK"
nohup uvicorn main:app --host 0.0.0.0 --port $PORT > backend.log 2>&1 &

# ================= تشغيل Frontend =================
echo "🌐 تشغيل Frontend..."
cd "$FRONT"
nohup python3 -m http.server $FRONT_PORT > frontend.log 2>&1 &

sleep 2
echo "🔥 Legendary v6 FullStack Ready"
echo "Backend: http://127.0.0.1:$PORT"
echo "Frontend: http://127.0.0.1:$FRONT_PORT"
echo "=============================="
