#!/usr/bin/env bash
# Install pinned CLI tools into ~/.local/bin without sudo. Every download is checked against
# the publisher's SHA-256 before it is installed. Re-running skips tools already at the pinned version.
set -euo pipefail

KUBECTL_VERSION=1.37.2
KIND_VERSION=0.33.0
HELM_VERSION=4.3.1
TERRAFORM_VERSION=1.17.1
JQ_VERSION=1.8.2

BIN="${BIN:-$HOME/.local/bin}"
STATE="${STATE:-$HOME/.local/share/kubmedic/tools}"
mkdir -p "$BIN" "$STATE"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# fetch URL FILE: download to $WORK/FILE
fetch() { curl -fsSL --retry 2 -o "$WORK/$2" "$1"; }

# verify FILE HASH: fail unless sha256 of $WORK/FILE equals HASH
verify() {
  local got
  got="$(sha256sum "$WORK/$1" | awk '{print $1}')"
  [ "$got" = "$2" ] || { echo "checksum mismatch for $1: expected $2, got $got" >&2; exit 1; }
}

# skip NAME VERSION: true if already installed at that version
skip() { [ -e "$STATE/$1-$2" ] && { echo "ok       $1 $2 (already installed)"; return 0; }; return 1; }

# done_ NAME VERSION: record the install and drop markers for older versions
done_() { rm -f "$STATE/$1"-*; touch "$STATE/$1-$2"; echo "installed $1 $2"; }

if ! skip kubectl "$KUBECTL_VERSION"; then
  base="https://dl.k8s.io/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl"
  fetch "$base" kubectl
  fetch "$base.sha256" kubectl.sha256
  verify kubectl "$(cat "$WORK/kubectl.sha256")"
  install -m 0755 "$WORK/kubectl" "$BIN/kubectl"
  done_ kubectl "$KUBECTL_VERSION"
fi

if ! skip kind "$KIND_VERSION"; then
  base="https://github.com/kubernetes-sigs/kind/releases/download/v$KIND_VERSION/kind-linux-amd64"
  fetch "$base" kind
  fetch "$base.sha256sum" kind.sha256sum
  verify kind "$(awk '{print $1}' "$WORK/kind.sha256sum")"
  install -m 0755 "$WORK/kind" "$BIN/kind"
  done_ kind "$KIND_VERSION"
fi

if ! skip helm "$HELM_VERSION"; then
  file="helm-v$HELM_VERSION-linux-amd64.tar.gz"
  fetch "https://get.helm.sh/$file" "$file"
  fetch "https://get.helm.sh/$file.sha256sum" "$file.sha256sum"
  verify "$file" "$(awk '{print $1}' "$WORK/$file.sha256sum")"
  tar -xzf "$WORK/$file" -C "$WORK" linux-amd64/helm
  install -m 0755 "$WORK/linux-amd64/helm" "$BIN/helm"
  done_ helm "$HELM_VERSION"
fi

if ! skip terraform "$TERRAFORM_VERSION"; then
  file="terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
  base="https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION"
  fetch "$base/$file" "$file"
  fetch "$base/terraform_${TERRAFORM_VERSION}_SHA256SUMS" SHA256SUMS
  verify "$file" "$(awk -v f="$file" '$2 == f {print $1}' "$WORK/SHA256SUMS")"
  python3 -m zipfile -e "$WORK/$file" "$WORK/tf"
  install -m 0755 "$WORK/tf/terraform" "$BIN/terraform"
  done_ terraform "$TERRAFORM_VERSION"
fi

if ! skip jq "$JQ_VERSION"; then
  base="https://github.com/jqlang/jq/releases/download/jq-$JQ_VERSION"
  fetch "$base/jq-linux-amd64" jq
  fetch "$base/sha256sum.txt" jq.sha256sums
  verify jq "$(awk '$2 == "jq-linux-amd64" {print $1}' "$WORK/jq.sha256sums")"
  install -m 0755 "$WORK/jq" "$BIN/jq"
  done_ jq "$JQ_VERSION"
fi
