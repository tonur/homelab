#!/usr/bin/env bash

set -e
set -o pipefail
set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

ansible-playbook -i inventory/hosts.yaml main.yaml "$@"