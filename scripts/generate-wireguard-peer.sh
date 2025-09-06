#!/usr/bin/env bash
set -euo pipefail

# generate-wireguard-peer.sh
# Helper to generate a WireGuard keypair + config snippet for edge gateway peer variables.
# It outputs:
#  - Private key (to store securely, e.g. in SOPS encrypted vars as wg_private_key)
#  - Public key
#  - Example Ansible vars to add to host/group vars for the opposite peer
#  - Example wg0.conf snippet for manual setups
#
# Usage:
#   ./scripts/generate-wireguard-peer.sh [--endpoint host:port] [--ip 10.172.90.X] [--listen-port 51820]
# Example:
#   ./scripts/generate-wireguard-peer.sh --endpoint gateway.example.com:51820 --ip 10.172.90.1 --listen-port 51820
#
# Requirements: wg (wireguard-tools)

endpoint=""
peer_ip=""
listen_port="51820"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --endpoint)
      endpoint="$2"; shift 2 ;;
    --ip)
      peer_ip="$2"; shift 2 ;;
    --listen-port)
      listen_port="$2"; shift 2 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# //' ; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if ! command -v wg >/dev/null 2>&1; then
  echo "wireguard-tools (wg) not found. Install it first." >&2
  exit 1
fi

priv_key=$(wg genkey)
pub_key=$(echo "$priv_key" | wg pubkey)

cat <<EOF
=== WireGuard Keypair Generated ===
Private Key (keep secret, DO NOT COMMIT):
$priv_key
Public Key:
$pub_key

Add to encrypted Ansible vars (e.g. group_vars/edge.yml or host_vars/<host>.yml via SOPS):
  wg_private_key: "$priv_key"

If this node is the home peer (existing in defaults as edge_gateway_wg_peer): set on the edge gateway:
  edge_gateway_wg_peer_public_key: "$pub_key"
  edge_gateway_wg_peer_endpoint: "$endpoint"

If this node is the gateway and you generated the other side, swap perspective accordingly.

Example interface address variable (adjust if different subnet):
  edge_gateway_wg_local: ${peer_ip:-10.172.90.2}
  edge_gateway_wg_peer:  ${peer_ip:-10.172.90.1}

Minimal wg0.conf fragment for the local side:
[Interface]
Address = ${peer_ip:-10.172.90.2}/32
ListenPort = $listen_port
PrivateKey = $priv_key

[Peer]
PublicKey = $pub_key
AllowedIPs = 10.172.90.0/24
PersistentKeepalive = 25
Endpoint = $endpoint
EOF
