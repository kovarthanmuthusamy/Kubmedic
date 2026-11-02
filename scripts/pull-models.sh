#!/usr/bin/env bash
# Pull every model listed in models.txt (one per line; blank lines and # comments ignored).
set -euo pipefail
cd "$(dirname "$0")/.."

while IFS= read -r line; do
  model="${line%%#*}"
  model="$(echo "$model" | xargs)"
  [ -z "$model" ] && continue
  echo "pulling $model"
  ollama pull "$model"
done < models.txt
