#!/usr/bin/env bash
# Install Ollama into ~/.local (checksum-verified) and run it as a systemd service bound to localhost.
# The download needs no sudo; registering the service does (one `sudo` prompt).
set -euo pipefail

OLLAMA_VERSION=0.40.13

HERE="$(cd "$(dirname "$0")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local}"
STATE="${STATE:-$HOME/.local/share/kubmedic/tools}"
mkdir -p "$PREFIX" "$STATE"

if [ -e "$STATE/ollama-$OLLAMA_VERSION" ]; then
  echo "ok       ollama $OLLAMA_VERSION (already installed)"
else
  WORK="$(mktemp -d)"
  trap 'rm -rf "$WORK"' EXIT
  base="https://github.com/ollama/ollama/releases/download/v$OLLAMA_VERSION"
  curl -fsSL --retry 2 -o "$WORK/ollama.tar.zst" "$base/ollama-linux-amd64.tar.zst"
  curl -fsSL --retry 2 -o "$WORK/sha256sum.txt" "$base/sha256sum.txt"
  want="$(awk '$2 == "./ollama-linux-amd64.tar.zst" {print $1}' "$WORK/sha256sum.txt")"
  got="$(sha256sum "$WORK/ollama.tar.zst" | awk '{print $1}')"
  [ -n "$want" ] && [ "$want" = "$got" ] || { echo "ollama checksum mismatch: want '$want', got '$got'" >&2; exit 1; }
  # zstd is not installed by default; decompress with the python module instead of needing apt
  uv run --no-project --with zstandard python -I -c '
import sys, zstandard
with open(sys.argv[1], "rb") as f, open(sys.argv[2], "wb") as o:
    zstandard.ZstdDecompressor().copy_stream(f, o)
' "$WORK/ollama.tar.zst" "$WORK/ollama.tar"
  # refuse archives with absolute or parent-relative paths
  if tar -tf "$WORK/ollama.tar" | grep -qE '^/|(^|/)\.\.(/|$)'; then echo "unsafe paths in ollama archive" >&2; exit 1; fi
  tar -xf "$WORK/ollama.tar" -C "$PREFIX"
  rm -f "$STATE"/ollama-*; touch "$STATE/ollama-$OLLAMA_VERSION"
  echo "installed ollama $OLLAMA_VERSION"
fi

unit=/etc/systemd/system/ollama.service
rendered="$(sed -e "s|@USER@|$(id -un)|" -e "s|@HOME@|$HOME|" "$HERE/ollama.service")"
if [ "$(cat "$unit" 2>/dev/null)" = "$rendered" ] && systemctl is-active --quiet ollama; then
  echo "ok       ollama.service (already running)"
else
  echo "registering ollama.service (sudo)"
  echo "$rendered" | sudo tee "$unit" >/dev/null
  sudo systemctl daemon-reload
  sudo systemctl enable --now ollama
fi
