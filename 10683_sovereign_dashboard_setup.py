import os
import subprocess

HOME = os.path.expanduser("~")
PROJECT_DIR = os.path.join(HOME, "sovereign_dashboard")

# 1️⃣ إنشاء مجلد المشروع
os.makedirs(PROJECT_DIR, exist_ok=True)

# 2️⃣ ملفات المشروع
files = {
    "package.json": """{
  "name": "sovereign_dashboard",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.16.0",
    "axios": "^1.6.0"
  },
  "devDependencies": {
    "vite": "^5.3.0",
    "@vitejs/plugin-react": "^4.0.0",
    "tailwindcss": "^3.4.0",
    "postcss": "^8.4.0",
    "autoprefixer": "^10.4.0"
  }
}""",
    "vite.config.js": """import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()]
});""",
    "index.html": """<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Sovereign Dashboard</title>
    <script type="module" src="/src/main.jsx"></script>
  </head>
  <body class="bg-gray-100"></body>
</html>""",
}

# 3️⃣ مجلد src وملفات داخلها
SRC_FILES = {
    "src/main.jsx": """import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./index.css";

ReactDOM.createRoot(document.getElementById("root") || document.body).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);""",
    "src/App.jsx": """import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Navbar from "./components/Navbar";
import Dashboard from "./pages/Dashboard";
import DataCollectionPage from "./pages/DataCollectionPage";
import DataProcessingPage from "./pages/DataProcessingPage";
import AnalyticsPage from "./pages/AnalyticsPage";
import AIEnginePage from "./pages/AIEnginePage";
import UnknownPage from "./pages/UnknownPage";

export default function App() {
  return (
    <Router>
      <Navbar />
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/collection" element={<DataCollectionPage />} />
        <Route path="/processing" element={<DataProcessingPage />} />
        <Route path="/analytics" element={<AnalyticsPage />} />
        <Route path="/ai" element={<AIEnginePage />} />
        <Route path="/unknown" element={<UnknownPage />} />
      </Routes>
    </Router>
  );
}""",
    "src/index.css": """@tailwind base;
@tailwind components;
@tailwind utilities;""",
    "src/components/Navbar.jsx": """import { Link } from "react-router-dom";

export default function Navbar() {
  return (
    <nav className="bg-gray-800 p-4 text-white flex justify-around">
      <Link to="/">Dashboard</Link>
      <Link to="/collection">Data Collection</Link>
      <Link to="/processing">Data Processing</Link>
      <Link to="/analytics">Analytics</Link>
      <Link to="/ai">AI Engine</Link>
      <Link to="/unknown">Unknown</Link>
    </nav>
  );
}""",
    "src/components/CapabilityCard.jsx": """export default function CapabilityCard({ name, description, onRun }) {
  return (
    <div className="border rounded p-4 m-2 shadow hover:shadow-lg transition bg-white">
      <h2 className="font-bold text-lg">{name}</h2>
      <p className="text-gray-600">{description}</p>
      <button
        onClick={onRun}
        className="mt-2 bg-blue-600 text-white px-3 py-1 rounded hover:bg-blue-700"
      >
        Run
      </button>
    </div>
  );
}""",
    "src/pages/Dashboard.jsx": """import CapabilityCard from "../components/CapabilityCard";

export default function Dashboard() {
  const capabilities = [
    { name: "Data Collection", description: "Collect data from sources" },
    { name: "Data Processing", description: "Process and clean data" },
    { name: "Analytics", description: "Generate reports and insights" },
    { name: "AI Engine", description: "Run AI tasks and predictions" },
  ];

  const handleRun = (cap) => {
    console.log(`Running ${cap}`);
    alert(`Running ${cap} (connect with Python backend to execute)`);
  };

  return (
    <div className="p-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {capabilities.map((cap) => (
        <CapabilityCard
          key={cap.name}
          name={cap.name}
          description={cap.description}
          onRun={() => handleRun(cap.name)}
        />
      ))}
    </div>
  );
}""",
}

# الصفحات الأخرى
PAGES = ["DataCollectionPage", "DataProcessingPage", "AnalyticsPage", "AIEnginePage", "UnknownPage"]
for page in PAGES:
    SRC_FILES[f"src/pages/{page}.jsx"] = f"""export default function {page}() {{
  return <h1 className="p-4 text-xl">{page} - Ready to connect AI tasks</h1>;
}}"""

# إنشاء المجلدات والملفات
for path, content in files.items():
    full_path = os.path.join(PROJECT_DIR, path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w", encoding="utf-8") as f:
        f.write(content)

for path, content in SRC_FILES.items():
    full_path = os.path.join(PROJECT_DIR, path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w", encoding="utf-8") as f:
        f.write(content)

# تثبيت الحزم وتشغيل المشروع
subprocess.run(["npm", "install"], cwd=PROJECT_DIR)
subprocess.run(["npm", "run", "dev"], cwd=PROJECT_DIR)
