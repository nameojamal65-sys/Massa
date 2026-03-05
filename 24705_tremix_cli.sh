#!/data/data/com.termux/files/usr/bin/bash
set -e

HOST="${TREMIX_HOST:-http://127.0.0.1:8080}"
TOKEN="${TREMIX_TOKEN:-}"

if [ -z "$TOKEN" ]; then
  echo "❌ لازم تحدد التوكن:"
  echo "export TREMIX_TOKEN='YOUR_TOKEN'"
  exit 1
fi

api_get() {
  curl -sS -H "X-API-Token: $TOKEN" "$HOST$1"
}

api_post() {
  curl -sS -X POST -H "X-API-Token: $TOKEN" "$HOST$1" -d "$2"
}

cmd="$1"; shift || true

case "$cmd" in
  ping) api_get "/api/v1/ping" ;;
  registry) api_get "/api/v1/registry" ;;
  tasks) api_get "/api/v1/tasks" ;;
  task-add) api_post "/api/v1/task/add" "data=$*" ;;
  worker-start) api_post "/api/v1/worker/start" "" ;;
  worker-stop) api_post "/api/v1/worker/stop" "" ;;
  svc-start) api_post "/api/v1/service/start" "name=$1" ;;
  svc-stop) api_post "/api/v1/service/stop" "name=$1" ;;
  file-analyze)
    # usage: tremix_cli.sh file-analyze /path/to/file "optional instruction"
    FILEPATH="$1"; shift || true
    INSTR="$*"
    curl -sS -X POST \
      -H "X-API-Token: $TOKEN" \
      -F "file=@${FILEPATH}" \
      -F "instruction=${INSTR}" \
      "$HOST/api/v1/file/analyze"
    ;;
  *)
    echo "Usage:"
    echo "  export TREMIX_TOKEN='...'"
    echo "  $0 ping | registry | tasks"
    echo "  $0 task-add \"text...\""
    echo "  $0 worker-start | worker-stop"
    echo "  $0 svc-start service1 | svc-stop service1"
    echo "  $0 file-analyze /sdcard/Download/x.log \"ركز على الأخطاء\""
    ;;
esac
