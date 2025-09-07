#!/usr/bin/env bash

set -e
set -o pipefail
set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

# Install required collections if not already present (idempotent)
if [[ -f collections/requirements.yml ]]; then
  ansible-galaxy collection install -r collections/requirements.yml >/dev/null
fi
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
ansible-playbook -i inventory/hosts.yaml main.yaml "$@"