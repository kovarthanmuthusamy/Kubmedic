#!/usr/bin/env bash
# Report which prerequisites are present. Read-only: never installs or changes anything.
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
missing=0

check() {
  if command -v "$1" >/dev/null 2>&1; then
    printf '  ok       %s\n' "$1"
  else
    printf '  MISSING  %s\n' "$1"
    missing=1
  fi
}

echo "tools:"
for t in git docker kubectl kind helm terraform make curl jq uv ollama; do check "$t"; done

echo "docker daemon:"
if docker info >/dev/null 2>&1; then echo "  ok       reachable"; else echo "  DOWN     docker info failed"; missing=1; fi

echo "gpus:"
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi --query-gpu=index,name,memory.used,memory.total --format=csv,noheader | sed 's/^/  /'
else
  echo "  MISSING  nvidia-smi"; missing=1
fi

echo "ollama ($OLLAMA_URL):"
if curl -fsS -m 3 "$OLLAMA_URL/api/version" >/dev/null 2>&1; then echo "  ok       reachable"; else echo "  DOWN     not reachable"; missing=1; fi

exit "$missing"
