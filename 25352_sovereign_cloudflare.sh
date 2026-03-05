#!/bin/bash
# =============================================
# 🚀 Sovereign Cloudflare Tunnel Smart Launcher
# =============================================

# --- إعداد الحساب ---
read -p "📧 Enter Cloudflare Email: " CF_EMAIL
read -s -p "🔑 Enter Cloudflare Global API Key: " CF_API_KEY
echo ""
read -p "🆔 Enter Cloudflare Account ID: " CF_ACCOUNT_ID
read -p "🎯 Token Name (e.g., 'readonly_token'): " TOKEN_NAME

# --- إنشاء مجلد bin إذا لم يكن موجود ---
mkdir -p ~/bin
export PATH=$HOME/bin:$PATH

# --- إنشاء التوكن Cloudflare ---
echo "⏳ Creating Cloudflare API Token..."
RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/tokens" \
-H "Content-Type: application/json" \
-H "X-Auth-Email: $CF_EMAIL" \
-H "X-Auth-Key: $CF_API_KEY" \
-d "{
      \"name\": \"$TOKEN_NAME\",
      \"policies\": [
        {
          \"effect\": \"allow\",
          \"permission_groups\": [
            {\"id\": \"4f7f2f2c4b6d7a1234567890\"}  # readonly
          ]
        }
      ]
    }")

TOKEN_VALUE=$(echo $RESPONSE | grep -oP '"id":"\K[^"]+')

if [[ -z "$TOKEN_VALUE" ]]; then
    echo "❌ Failed to create Cloudflare token!"
    echo "Response: $RESPONSE"
    exit 1
else
    echo "✅ Cloudflare Token created: $TOKEN_VALUE"
    echo $TOKEN_VALUE > ~/.cloudflare_token
    chmod 600 ~/.cloudflare_token
    echo "💾 Token saved to ~/.cloudflare_token"
fi

# --- تنزيل Cloudflared إذا غير موجود ---
if ! command -v cloudflared &> /dev/null; then
    echo "⚠️ cloudflared not installed. Downloading..."
    wget -O ~/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64
    chmod +x ~/bin/cloudflared
fi

# --- تشغيل Tunnel مباشر ---
echo "⏳ Starting Cloudflare Tunnel on 127.0.0.1:8080..."
cloudflared tunnel --url http://127.0.0.1:8080
