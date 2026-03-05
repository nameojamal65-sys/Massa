#!/data/data/com.termux/files/usr/bin/bash
set -e

clear
echo "👑 Sovereign Cloudflare Autonomous Bootstrap"
echo "==========================================="

# Dependencies
for cmd in curl jq cloudflared; do
  if ! command -v $cmd >/dev/null 2>&1; then
    echo "❌ Missing dependency: $cmd"
    echo "Run: pkg install $cmd -y"
    exit 1
  fi
done

# Read ROOT API Token
echo
read -s -p "🔐 Enter Cloudflare ROOT API TOKEN: " CF_API_TOKEN
echo

export CLOUDFLARE_API_TOKEN="$CF_API_TOKEN"

# Fetch Account ID
echo "🌐 Fetching Cloudflare Account ID..."
ACCOUNT_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" | jq -r '.result[0].id')

if [[ -z "$ACCOUNT_ID" || "$ACCOUNT_ID" == "null" ]]; then
  echo "❌ Could not fetch ACCOUNT_ID"
  exit 1
fi

export ACCOUNT_ID
echo "✅ ACCOUNT_ID = $ACCOUNT_ID"

# Create token payload
cat > token_payload.json << 'EOF'
{
  "name": "sovereign-core-token",
  "policies": [
    {
      "effect": "allow",
      "permission_groups": [
        {"id": "c8fed203ed3043cba015a93ad1616f1f"},
        {"id": "82e64a83756745bbbb1c9c2701bf816b"}
      ],
      "resources": {"com.cloudflare.api.account.*": "*"}
    }
  ],
  "expires_on": "2027-12-31T23:59:59Z",
  "not_before": "2026-01-01T00:00:00Z"
}
EOF

# Create Scoped Token
echo "🧠 Generating Sovereign Scoped Token..."
TOKEN_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/tokens" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -d @token_payload.json)

SUCCESS=$(echo "$TOKEN_RESPONSE" | jq -r '.success')

if [[ "$SUCCESS" != "true" ]]; then
  echo "❌ Token creation failed:"
  echo "$TOKEN_RESPONSE" | jq
  exit 1
fi

SOVEREIGN_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.result.value')

echo "✅ Sovereign Token Generated"

# Save Token
mkdir -p ~/.sovereign
echo "$SOVEREIGN_TOKEN" > ~/.sovereign/cloudflare.token
chmod 600 ~/.sovereign/cloudflare.token

# Login cloudflared
echo "🔐 Authenticating cloudflared..."
cloudflared login || true
