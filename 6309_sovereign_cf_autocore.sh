#!/data/data/com.termux/files/usr/bin/bash

set -e

clear
echo "👑 Sovereign Cloudflare × Termux Autonomous Core"
echo "==============================================="

### Phase 1 — System Bootstrap
echo "⚙️  Bootstrapping Termux..."
pkg update -y
pkg upgrade -y
pkg install -y curl wget jq git openssl nodejs python cloudflared

### Phase 2 — Secure Input
echo ""
read -p "🔐 Enter Cloudflare ACCOUNT ID: " ACCOUNT_ID
read -p "🔐 Enter Cloudflare ROOT API TOKEN: " CLOUDFLARE_API_TOKEN

export ACCOUNT_ID
export CLOUDFLARE_API_TOKEN

### Phase 3 — Token Auto Generator
echo "🧠 Generating Sovereign API Token..."

NOT_BEFORE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
EXPIRES_ON=$(date -u -d "+10 years" +"%Y-%m-%dT%H:%M:%SZ")

PAYLOAD=$(jq -n \
  --arg nb "$NOT_BEFORE" \
  --arg exp "$EXPIRES_ON" \
  '{
    name: "sovereign-core",
    policies: [
      {
        effect: "allow",
        permission_groups: [
          {id:"c8fed203ed3043cba015a93ad1616f1f"},
          {id:"82e64a83756745bbbb1c9c2701bf816b"}
        ],
        resources: {"com.cloudflare.accounts.*":"*"}
      }
    ],
    expires_on: $exp,
    not_before: $nb
  }')

RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/tokens" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

TOKEN=$(echo "$RESPONSE" | jq -r '.result.value')

if [[ "$TOKEN" == "null" || -z "$TOKEN" ]]; then
  echo "❌ Token generation failed"
  echo "$RESPONSE"
  exit 1
fi

echo "✅ Sovereign Token Generated"

### Phase 4 — Cloudflared Login
echo "🔗 Authenticating Cloudflared..."
echo "$TOKEN" | cloudflared login

### Phase 5 — Auto Tunnel Creation
echo "🌐 Creating Autonomous Tunnel..."
TUNNEL_NAME="sovereign-$(date +%s)"
cloudflared tunnel create "$TUNNEL_NAME"

TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')

### Phase 6 — Config Generator
mkdir -p ~/.cloudflared

cat > ~/.cloudflared/config.yml <<EOF
tunnel: $TUNNEL_ID
credentials-file: /data/data/com.termux/files/home/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $TUNNEL_NAME.zaeem.ai
    service: http://localhost:8080
  - service: http_status:404
EOF

### Phase 7 — Autonomous Runtime
echo "🚀 Launching Sovereign Tunnel..."

while true; do
  cloudflared tunnel run "$TUNNEL_NAME"
  echo "⚠️ Tunnel disconnected — restarting..."
  sleep 3
done
