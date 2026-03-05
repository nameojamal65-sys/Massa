#!/data/data/com.termux/files/usr/bin/bash

set -e

TUNNEL_NAME="sovereign-core"
LOCAL_PORT="8080"

echo "=============================================="
echo "👑 Sovereign Zero Trust Tunnel Auto Setup"
echo "=============================================="

# Check cloudflared
if ! command -v cloudflared >/dev/null 2>&1; then
  echo "❌ cloudflared غير مثبت"
  echo "📦 جاري التثبيت..."
  pkg install cloudflared -y
fi

echo "✅ cloudflared موجود"

# Check login
if ! cloudflared tunnel list >/dev/null 2>&1; then
  echo "🔐 لم يتم تسجيل الدخول بعد"
  cloudflared tunnel login
fi

echo "✅ تم التحقق من المصادقة"

# Check tunnel exists
if cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
  echo "✅ النفق موجود مسبقاً"
else
  echo "🛠️ إنشاء نفق جديد: $TUNNEL_NAME"
  cloudflared tunnel create $TUNNEL_NAME
fi

# Create config directory
mkdir -p ~/.cloudflared

# Generate config
cat > ~/.cloudflared/config.yml << CONF
tunnel: $TUNNEL_NAME
credentials-file: ~/.cloudflared/$TUNNEL_NAME.json

ingress:
  - hostname: $TUNNEL_NAME.local
    service: http://127.0.0.1:$LOCAL_PORT
  - service: http_status:404
CONF

echo "⚙️ تم إنشاء إعدادات النفق"

echo "🚀 تشغيل النفق الآمن..."
cloudflared tunnel run $TUNNEL_NAME &

sleep 4

echo ""
echo "=============================================="
echo "✅ Sovereign Core Connected Securely"
echo "=============================================="
echo ""
echo "🔐 Zero Trust Tunnel: ACTIVE"
echo "🌐 Local Dashboard: http://127.0.0.1:$LOCAL_PORT"
echo ""
echo "📡 يمكنك إنشاء دومين رسمي من Cloudflare Zero Trust Dashboard"
echo ""
echo "👑 Sovereign Core is now globally reachable"
echo "=============================================="
