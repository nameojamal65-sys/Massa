#!/bin/bash
# =========================================
# Sovereign Auto Smart Build v5.0
# ذكي بالكامل ويعتمد على الجلسة الحالية
# مع وحدة أبو مفتاح لمراقبة البناء وإعادة المحاولة
# =========================================

GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"

echo -e "${GREEN}🚀 Starting Sovereign Auto Smart Build v5.0...${NC}"

# ---- فحص Node.js ----
RECOMMENDED_NODE="18.17.1"
NODE_VERSION=$(node -v 2>/dev/null || echo "v0.0.0" | cut -c2-)
echo -e "${GREEN}🖥 Detected Node.js version: $NODE_VERSION${NC}"

if [ "$NODE_VERSION" != "$RECOMMENDED_NODE" ]; then
    echo -e "${RED}⚠️ Node.js mismatch, installing $RECOMMENDED_NODE...${NC}"
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.6/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    fi
    unset PREFIX
    nvm install $RECOMMENDED_NODE
    nvm use $RECOMMENDED_NODE
fi

# ---- تثبيت npm packages ----
echo -e "${GREEN}📦 Installing npm packages...${NC}"
npm install --legacy-peer-deps || { echo -e "${RED}❌ npm install failed, retrying...${NC}"; npm install; }

# ---- تحديث React & React Native ----
echo -e "${GREEN}⚠️ Updating React & React Native...${NC}"
npm update react react-native || echo -e "${RED}⚠️ npm update failed, continuing...${NC}"

# ---- التحقق من EAS جلسة ----
if ! eas whoami >/dev/null 2>&1; then
    echo -e "${RED}❌ No active EAS session found. Please run 'eas login' once manually.${NC}"
    exit 1
fi

# ---- Abu Mftah Monitoring ----
abu_mftah_retry() {
    local CMD="$1"
    local RETRIES=3
    local COUNT=0
    local SUCCESS=0
    while [ $COUNT -lt $RETRIES ]; do
        echo -e "${GREEN}🤖 Abu Mftah executing: $CMD (Attempt $((COUNT+1)))${NC}"
        $CMD && { SUCCESS=1; break; } || echo -e "${RED}⚠️ Attempt $((COUNT+1)) failed.${NC}"
        COUNT=$((COUNT+1))
        sleep 5
    done
    return $SUCCESS
}

# ---- تشغيل backend ----
BACKEND_PORT=5000
if lsof -i:$BACKEND_PORT >/dev/null; then
    BACKEND_PORT=$(comm -23 <(seq 5000 6000) <(lsof -i -P -n | grep LISTEN | awk '{print $9}' | cut -d':' -f2) | head -n1)
fi
echo -e "${GREEN}🖥 Using backend port: $BACKEND_PORT${NC}"

if [ ! -f "./backend/main.py" ]; then
    echo -e "${GREEN}📦 Creating dummy backend...${NC}"
    mkdir -p backend
    cat <<EOL > backend/main.py
from flask import Flask
app = Flask(__name__)

@app.route("/api/hello")
def hello():
    return {"status": "Sovereign Backend Ready!"}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=$BACKEND_PORT)
EOL
fi

echo -e "${GREEN}🖥 Starting backend...${NC}"
python3 ./backend/main.py &
BACKEND_PID=$!
sleep 3

# ---- البناء الذكي APK / IPA مع مراقبة أبو مفتاح ----
abu_mftah_retry "eas build --platform android --non-interactive --profile production" || echo -e "${RED}❌ Android build ultimately failed.${NC}"
abu_mftah_retry "eas build --platform ios --non-interactive --profile production" || echo -e "${RED}❌ iOS build ultimately failed.${NC}"

# ---- إيقاف backend ----
echo -e "${GREEN}🛑 Stopping backend...${NC}"
kill $BACKEND_PID 2>/dev/null || echo -e "${RED}⚠️ Backend process not found.${NC}"

echo -e "${GREEN}✅ Sovereign Auto Smart Build v5.0 Complete!${NC}"
echo -e "${GREEN}🌐 Backend endpoint: http://localhost:$BACKEND_PORT/api/hello${NC}"
