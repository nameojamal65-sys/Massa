#!/data/data/com.termux/files/usr/bin/bash

echo "🔹 Setting up Sovereign Full Dashboard (React + Vite)..."

DASHBOARD_PATH=~/sovereign_dashboard

# إزالة المشروع القديم إذا موجود
if [ -d "$DASHBOARD_PATH" ]; then
    echo "🔹 Removing old dashboard directory..."
    rm -rf "$DASHBOARD_PATH"
fi

# إنشاء مشروع React Vite جديد
echo "🔹 Creating new React Vite project..."
npx create-vite@latest $DASHBOARD_PATH --template react

cd $DASHBOARD_PATH

# تثبيت الحزم المطلوبة
echo "🔹 Installing dependencies..."
npm install axios react-router-dom

# نقطة النهاية للـ API
echo "VITE_API_URL=http://127.0.0.1:5000" > .env

# إنشاء مجلد صفحات
mkdir -p src/pages

# Dashboard.jsx
cat > src/pages/Dashboard.jsx << 'EOF'
import React, { useState } from 'react';
import axios from 'axios';

export default function Dashboard() {
  const apiUrl = import.meta.env.VITE_API_URL;
  const [result, setResult] = useState('');

  const tasks = [
    { name: 'Data Collection', endpoint: '/task/collect_data' },
    { name: 'Data Processing', endpoint: '/task/process_data' },
    { name: 'Analytics', endpoint: '/task/analytics' },
    { name: 'AI Engine', endpoint: '/task/ai_formula', payload: {x:1} },
    { name: 'Query External AI', endpoint: '/task/external_ai', payload: {query:'Hello'} },
    { name: 'Fetch Web', endpoint: '/task/fetch_web', payload: {url:'https://example.com'} },
  ];

  const runTask = (task) => {
    axios.post(apiUrl + task.endpoint, task.payload || {})
      .then(res => setResult(JSON.stringify(res.data, null, 2)))
      .catch(err => setResult(err.toString()));
  };

  return (
    <div style={{padding:20}}>
      <h1>Sovereign Full Dashboard</h1>
      <div style={{display:'flex', flexWrap:'wrap', gap:10, marginBottom:20}}>
        {tasks.map(t => (
          <button key={t.name} onClick={() => runTask(t)} style={{padding:'10px 20px'}}>
            {t.name}
          </button>
        ))}
      </div>
      <pre style={{background:'#eee', padding:10, minHeight:200}}>{result}</pre>
    </div>
  );
}
EOF

# App.jsx
cat > src/App.jsx << 'EOF'
import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Dashboard from './pages/Dashboard';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Dashboard />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
EOF

echo "✅ Sovereign Full Dashboard setup complete!"
echo "Run: cd $DASHBOARD_PATH && npm run dev"
