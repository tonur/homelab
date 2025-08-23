#!/usr/bin/env bash
set -euo pipefail
# Generate an Age key pair and show public recipient.
# Usage: ./scripts/generate-age-key.sh > age-key.txt (then add public part to .sops.yaml)
if ! command -v age-keygen >/dev/null 2>&1; then
  echo "Install age first (e.g. sudo apt install age)." >&2
  exit 1
fi
age-keygen 2>age-key.tmp
echo "# PRIVATE KEY (keep secret, do not commit)" >&2
cat age-key.tmp >&2
pub=$(grep 'public key' age-key.tmp | sed -E 's/.*public key: (.*)$/\1/')
rm age-key.tmp
echo "Add this to .sops.yaml creation_rules age list:" >&2
echo "$pub"
