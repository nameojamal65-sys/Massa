#!/usr/bin/env bash

set -e

echo "🔍 Cloudflare Account Checker"
echo "============================="

# Check token
if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
  echo "❌ CLOUDFLARE_API_TOKEN is not set"
  echo "👉 Export it first:"
  echo '   export CLOUDFLARE_API_TOKEN="YOUR_TOKEN_HERE"'
  exit 1
fi

echo "✅ Token detected"

# Call API
echo "🌐 Querying Cloudflare API..."
RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json")

# Validate JSON
if ! echo "$RESPONSE" | jq . >/dev/null 2>&1; then
  echo "❌ Invalid response:"
  echo "$RESPONSE"
  exit 1
fi

SUCCESS=$(echo "$RESPONSE" | jq -r '.success')

if [[ "$SUCCESS" != "true" ]]; then
  echo "❌ API Error:"
  echo "$RESPONSE" | jq .
  exit 1
fi

echo "✅ Connected successfully"
echo
echo "📦 Accounts:"
echo "$RESPONSE" | jq '.result[] | {id, name, created_on}'
echo
echo "🚀 Done."
