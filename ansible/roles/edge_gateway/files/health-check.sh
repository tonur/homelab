#!/usr/bin/env bash
set -euo pipefail

IFACE=wg0
PEER="{{ edge_gateway_wg_peer }}"
LOGTAG="edge-gateway-health"

if ! command -v wg >/dev/null 2>&1; then
  logger -t "$LOGTAG" "wg command not found"
  exit 0
fi

HANDSHAKE=$(wg show $IFACE latest-handshakes 2>/dev/null | awk '{print $2}')
NOW=$(date +%s)
if [[ -n "$HANDSHAKE" ]]; then
  AGE=$((NOW - HANDSHAKE))
  if (( AGE > 180 )); then
    logger -t "$LOGTAG" "No recent handshake (age=${AGE}s), restarting interface"
    systemctl restart wg-quick@$IFACE || logger -t "$LOGTAG" "Failed to restart $IFACE"
  fi
else
  logger -t "$LOGTAG" "No handshake data, attempting restart"
  systemctl restart wg-quick@$IFACE || logger -t "$LOGTAG" "Failed to restart $IFACE"
fi
