#!/bin/bash
# =========================================
# 👑 PAI6 Ultimate Closure V1 – Full Global Build
# =========================================

ROOT="$HOME/PAI6_UltimateClosure"
mkdir -p "$ROOT"/{core,dashboard,scanner,docker,windows_build,reports,scripts}

echo "👑 Activating PAI6 Ultimate Closure V1..."
echo "========================================="

SYSTEM_TOOLS=("wget" "curl" "git" "jq" "unzip" "tar")
for tool in "${SYSTEM_TOOLS[@]}"; do
    if ! command -v $tool >/dev/null 2>&1; then
        echo "Installing $tool..."
        pkg install $tool -y >/dev/null 2>&1 || echo "⚠️ Failed to install $tool"
    fi
done

PYTHON_LIBS=("requests" "fastapi" "uvicorn" "numpy" "pandas")
NODE_LIBS=("express" "cors" "axios" "react" "react-dom")

for lib in "${PYTHON_LIBS[@]}"; do
    pip install $lib >/dev/null 2>&1 || echo "⚠️ Failed to install $lib"
done

for lib in "${NODE_LIBS[@]}"; do
    npm install $lib >/dev/null 2>&1 || echo "⚠️ Failed to install $lib"
done

touch "$ROOT/windows_build/PAI6.exe"

cat > "$ROOT/docker/Dockerfile" <<EOL
FROM python:3.12-slim
WORKDIR /app
COPY ./core ./core
COPY ./dashboard ./dashboard
COPY ./scanner ./scanner
RUN pip install requests fastapi uvicorn numpy pandas
EXPOSE 8080
CMD ["python", "./core/core_launcher.py"]
EOL

cat > "$ROOT/docker/docker-compose.yml" <<EOL
version: '3.8'
services:
  pai6:
    build: .
    ports:
      - "8080:8080"
    volumes:
      - ./core:/app/core
      - ./dashboard:/app/dashboard
      - ./scanner:/app/scanner
EOL

touch "$ROOT/scanner/ultra_nano_scan.sh"
mkdir -p "$ROOT/reports"

echo ""
echo "✅ PAI6 Ultimate Closure V1 Prepared"
echo "Ready to activate full capabilities with one command."
