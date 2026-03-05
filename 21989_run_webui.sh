#!/bin/bash
echo "🚀 Starting ForgeMind WebUI (Temporary Termux Build)..."

# التأكد من وجود node_modules
if [ ! -d node_modules ]; then
    echo "📦 Installing dependencies..."
    # توليد package.json مؤقت
    cat > package.json << 'EOP'
{
  "name": "forgemind-webui-temp",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "echo Running temporary WebUI server..."
  },
  "dependencies": {}
}
EOP

    # تثبيت الحزم (لا توجد حزم حالياً)
    npm install
fi

echo "✅ Dependencies installed."

# تشغيل dev سكربت مؤقت
npm run dev -- --host
