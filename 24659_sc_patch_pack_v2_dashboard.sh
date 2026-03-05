#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/sovereign_core"
DASH="$ROOT/apps/dashboard"
UI_STATIC="$ROOT/ui/static/dash"

echo "== Patch Pack v2: React Dashboard + PWA (Zero-Break) =="

[ -d "$ROOT" ] || { echo "❌ لم أجد $ROOT"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "❌ node غير موجود"; exit 1; }
command -v npm  >/dev/null 2>&1 || { echo "❌ npm غير موجود"; exit 1; }

mkdir -p "$ROOT/apps"

if [ ! -d "$DASH" ]; then
  echo "== Creating Vite React+TS app =="
  cd "$ROOT/apps"
  npm create vite@latest dashboard -- --template react-ts
fi

cd "$DASH"

echo "== Installing deps =="
npm i
npm i react-router-dom
npm i vite-plugin-pwa

echo "== Writing config + app code =="

cat > vite.config.ts <<'TS'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { VitePWA } from "vite-plugin-pwa";

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: "autoUpdate",
      includeAssets: ["favicon.ico"],
      manifest: {
        name: "Sovereign Core Dashboard",
        short_name: "Sovereign",
        start_url: "/dash/",
        scope: "/dash/",
        display: "standalone",
        background_color: "#0b0f14",
        theme_color: "#0b0f14",
        icons: [
          { src: "/dash/pwa-192.png", sizes: "192x192", type: "image/png" },
          { src: "/dash/pwa-512.png", sizes: "512x512", type: "image/png" }
        ]
      }
    })
  ],
  base: "/dash/",
});
TS

mkdir -p public
# minimal icons placeholders (PNG header-less not valid); we generate tiny valid PNGs via python
python3 - <<'PY'
import base64, pathlib
# 1x1 transparent PNG
png = base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMBAJ9WZ9sAAAAASUVORK5CYII=")
p = pathlib.Path("public")
(p/"pwa-192.png").write_bytes(png)
(p/"pwa-512.png").write_bytes(png)
(p/"favicon.ico").write_bytes(b"")
print("icons ok")
PY

mkdir -p src/{app,components,lib,pages}

cat > src/lib/api.ts <<'TS'
export type ApiOk<T> = { ok: true } & T;
export type ApiErr = { ok: false; error: { code: string; message: string; details?: any }; correlation_id?: string };

export async function apiGet<T>(path: string): Promise<T | ApiErr> {
  const r = await fetch(path, { headers: { "X-Client": "dash" } });
  const ct = r.headers.get("content-type") || "";
  if (ct.includes("application/json")) return await r.json();
  const text = await r.text();
  return { ok: false, error: { code: "NON_JSON", message: text.slice(0, 4000) } };
}
TS

cat > src/lib/ws.ts <<'TS'
export function makeWsUrl(path: string) {
  // UI is served at /dash; backend is same origin at /
  const proto = location.protocol === "https:" ? "wss" : "ws";
  return `${proto}://${location.host}${path}`;
}
TS

cat > src/components/Shell.tsx <<'TSX'
import { NavLink, Outlet } from "react-router-dom";

const linkStyle: React.CSSProperties = {
  display: "block",
  padding: "10px 12px",
  borderRadius: 12,
  textDecoration: "none",
};

export default function Shell() {
  return (
    <div style={{ display: "grid", gridTemplateColumns: "260px 1fr", minHeight: "100vh", fontFamily: "system-ui" }}>
      <aside style={{ padding: 16, borderRight: "1px solid #eee" }}>
        <div style={{ marginBottom: 14 }}>
          <div style={{ fontWeight: 800, fontSize: 18 }}>Sovereign</div>
          <div style={{ color: "#666" }}>RC Dashboard</div>
        </div>

        {[
          ["Overview", "/dash/"],
          ["Jobs", "/dash/jobs"],
          ["Approvals", "/dash/approvals"],
          ["Audit", "/dash/audit"],
          ["Quotas", "/dash/quotas"],
          ["Workers", "/dash/workers"],
          ["Settings", "/dash/settings"],
        ].map(([label, to]) => (
          <NavLink
            key={to}
            to={to}
            style={({ isActive }) => ({
              ...linkStyle,
              background: isActive ? "#f3f4f6" : "transparent",
              color: "#111",
            })}
          >
            {label}
          </NavLink>
        ))}

        <div style={{ marginTop: 16, color: "#666", fontSize: 12 }}>
          <div>Zero-Break: لا يلمس / ولا /api/*</div>
          <div>Enable: <code>SC_NEW_UI=1</code></div>
        </div>
      </aside>

      <main style={{ padding: 18 }}>
        <Outlet />
      </main>
    </div>
  );
}
TSX

cat > src/pages/Overview.tsx <<'TSX'
import { useEffect, useState } from "react";
import { apiGet } from "../lib/api";

type Status = any;

export default function Overview() {
  const [data, setData] = useState<Status | null>(null);
  const [err, setErr] = useState<string>("");

  useEffect(() => {
    let alive = true;
    const tick = async () => {
      const res: any = await apiGet("/api/status");
      if (!alive) return;
      if (res && res.ok === false) setErr(res.error?.message || "error");
      else { setErr(""); setData(res); }
    };
    tick();
    const t = setInterval(tick, 1000);
    return () => { alive = false; clearInterval(t); };
  }, []);

  return (
    <div>
      <h1 style={{ marginTop: 0 }}>Overview</h1>
      <p style={{ color: "#666" }}>Live view (polling <code>/api/status</code> كل ثانية).</p>

      {err && <pre style={{ padding: 12, border: "1px solid #fca5a5", borderRadius: 12, background: "#fff1f2" }}>{err}</pre>}
      <div style={{ padding: 12, border: "1px solid #eee", borderRadius: 12 }}>
        <pre style={{ margin: 0 }}>{JSON.stringify(data, null, 2)}</pre>
      </div>

      <div style={{ marginTop: 14, padding: 12, border: "1px solid #eee", borderRadius: 12 }}>
        <div style={{ fontWeight: 700 }}>RC Notes</div>
        <ul style={{ margin: "8px 0 0 18px", color: "#444" }}>
          <li>اليوم: UI مؤسسية + PWA + أساس live.</li>
          <li>الجلسة القادمة: WS streams + Jobs/Approvals/Audit/Quotas endpoints + Policy/Registry.</li>
        </ul>
      </div>
    </div>
  );
}
TSX

cat > src/pages/Stub.tsx <<'TSX'
export default function Stub({ title, hint }: { title: string; hint: string }) {
  return (
    <div>
      <h1 style={{ marginTop: 0 }}>{title}</h1>
      <div style={{ padding: 12, border: "1px solid #eee", borderRadius: 12 }}>
        <div style={{ fontWeight: 700 }}>Coming Online (RC-safe)</div>
        <p style={{ color: "#666" }}>{hint}</p>
        <ul style={{ margin: "8px 0 0 18px", color: "#444" }}>
          <li>لن نغيّر API الحالي.</li>
          <li>سنعمل Endpoints إضافية + Feature Flags.</li>
          <li>الواجهة جاهزة، نربطها بالـbackend في الجلسة القادمة.</li>
        </ul>
      </div>
    </div>
  );
}
TSX

cat > src/pages/Jobs.tsx <<'TSX'
import Stub from "./Stub";
export default function Jobs() {
  return <Stub title="Jobs" hint="ربطها سيكون مع /api/jobs + /ws/jobs (حسب الموجود عندك)." />;
}
TSX

cat > src/pages/Approvals.tsx <<'TSX'
import Stub from "./Stub";
export default function Approvals() {
  return <Stub title="Approvals (HITL)" hint="ربطها سيكون مع /api/approvals و endpoints التوقيع/التحقق." />;
}
TSX

cat > src/pages/Audit.tsx <<'TSX'
import Stub from "./Stub";
export default function Audit() {
  return <Stub title="Audit" hint="ربطها سيكون مع /api/audit/* + verify chain." />;
}
TSX

cat > src/pages/Quotas.tsx <<'TSX'
import Stub from "./Stub";
export default function Quotas() {
  return <Stub title="Quotas / Tenants" hint="ربطها سيكون مع /api/tenants + /api/quotas (Feature Flag)." />;
}
TSX

cat > src/pages/Workers.tsx <<'TSX'
import Stub from "./Stub";
export default function Workers() {
  return <Stub title="Workers" hint="ربطها سيكون مع /api/workers + live metrics." />;
}
TSX

cat > src/pages/Settings.tsx <<'TSX'
import Stub from "./Stub";
export default function Settings() {
  return <Stub title="Settings" hint="Feature Flags, External adapters policy, maintenance mode." />;
}
TSX

cat > src/app/routes.tsx <<'TSX'
import { createBrowserRouter } from "react-router-dom";
import Shell from "../components/Shell";
import Overview from "../pages/Overview";
import Jobs from "../pages/Jobs";
import Approvals from "../pages/Approvals";
import Audit from "../pages/Audit";
import Quotas from "../pages/Quotas";
import Workers from "../pages/Workers";
import Settings from "../pages/Settings";

export const router = createBrowserRouter([
  {
    path: "/dash",
    element: <Shell />,
    children: [
      { index: true, element: <Overview /> },
      { path: "/dash/jobs", element: <Jobs /> },
      { path: "/dash/approvals", element: <Approvals /> },
      { path: "/dash/audit", element: <Audit /> },
      { path: "/dash/quotas", element: <Quotas /> },
      { path: "/dash/workers", element: <Workers /> },
      { path: "/dash/settings", element: <Settings /> },
    ],
  },
]);
TSX

cat > src/main.tsx <<'TSX'
import React from "react";
import ReactDOM from "react-dom/client";
import { RouterProvider } from "react-router-dom";
import { router } from "./app/routes";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <RouterProvider router={router} />
  </React.StrictMode>
);
TSX

# Ensure index.html exists (Vite default) and supports base /dash
# (leave Vite default; just ensure it uses root div)

echo "== Build dashboard =="
npm run build

echo "== Deploy build to ui/static/dash =="
rm -rf "$UI_STATIC"
mkdir -p "$UI_STATIC"
cp -r dist/* "$UI_STATIC/"

echo ""
echo "✅ React Dashboard deployed."
echo "To enable /dash at runtime:"
echo "  export SC_NEW_UI=1"
echo "  open: http://127.0.0.1:8080/dash/"
echo ""
echo "Tip: keep / unchanged (zero-break)."
