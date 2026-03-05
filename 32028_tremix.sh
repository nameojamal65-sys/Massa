#!/data/data/com.termux/files/usr/bin/bash

BASE_DIR="$HOME/Tremix"
PROJECTS_DIR="$BASE_DIR/projects"

mkdir -p "$PROJECTS_DIR"

create_project() {
  NAME="$1"
  mkdir -p "$PROJECTS_DIR/$NAME"

  cat > "$PROJECTS_DIR/$NAME/main.py" <<'PY'
from fastapi import FastAPI
app = FastAPI()

@app.get("/")
def root():
    return {"message": "Tremix Sovereign Running"}
PY

  cat > "$PROJECTS_DIR/$NAME/requirements.txt" <<'REQ'
fastapi
uvicorn
REQ

  echo "✅ Project $NAME created at $PROJECTS_DIR/$NAME"
}

run_project() {
  NAME="$1"
  cd "$PROJECTS_DIR/$NAME" || exit 1

  if [ ! -d ".venv" ]; then
    echo "🔧 Creating venv..."
    python3 -m venv .venv
  fi

  . .venv/bin/activate
  python -m pip install --upgrade pip
  pip install -r requirements.txt

  echo "🚀 Starting at http://127.0.0.1:8000"
  uvicorn main:app --host 127.0.0.1 --port 8000
}

case "$1" in
  create) create_project "$2" ;;
  run)    run_project "$2" ;;
  *)
    echo "Usage:"
    echo "./tremix.sh create service1"
    echo "./tremix.sh run service1"
    ;;
esac
