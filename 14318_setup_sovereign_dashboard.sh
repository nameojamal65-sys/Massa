#!/data/data/com.termux/files/usr/bin/bash

echo "🔹 Setting up Sovereign Dashboard (React + Vite) ..."

# مسار المشروع
DASHBOARD_PATH=~/sovereign_dashboard

# إزالة المشروع القديم إذا موجود
if [ -d "$DASHBOARD_PATH" ]; then
    echo "🔹 Removing old dashboard directory..."
    rm -rf "$DASHBOARD_PATH"
fi

# إنشاء مشروع React Vite جديد
echo "🔹 Creating new React Vite project..."
npx create-vite@latest $DASHBOARD_PATH --template react

# الدخول للمشروع
cd $DASHBOARD_PATH

# تثبيت الحزم المطلوبة
echo "🔹 Installing dependencies..."
npm install axios react-router-dom

# إضافة نقطة النهاية للـ API في ملف env
echo "VITE_API_URL=http://127.0.0.1:5000" > .env

# إنشاء صفحات أساسية
mkdir -p src/pages

# Dashboard.jsx
cat > src/pages/Dashboard.jsx << 'EOF'
import React, { useState, useEffect } from 'react';
import axios from 'axios';

export default function Dashboard() {
  const [data, setData] = useState({});
  const apiUrl = import.meta.env.VITE_API_URL;

  useEffect(() => {
    axios.get(`${apiUrl}/data`).then(res => setData(res.data));
  }, []);

  return (
    <div style={{padding:20}}>
      <h1>Sovereign Dashboard</h1>
      <pre>{JSON.stringify(data, null, 2)}</pre>
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

echo "✅ Sovereign Dashboard setup complete!"
echo "Run: cd $DASHBOARD_PATH && npm run dev"
