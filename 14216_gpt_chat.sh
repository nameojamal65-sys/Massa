#!/data/data/com.termux/files/usr/bin/bash

clear
echo "=========================="
echo " GPT REAL CHAT SYSTEM"
echo "=========================="
echo ""

read -p "Enter API Key: " API_KEY

while true
do
  echo ""
  read -p "You: " PROMPT

  if [ "$PROMPT" = "exit" ]; then
    break
  fi

  RESPONSE=$(curl https://api.openai.com/v1/responses \
    -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d "{
      \"model\": \"gpt-4o-mini\",
      \"input\": \"$PROMPT\"
    }")

  echo ""
  echo "$RESPONSE" | sed -n 's/.*"text":"\([^"]*\)".*/GPT: \1/p'

done
