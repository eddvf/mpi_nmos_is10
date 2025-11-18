#!/usr/bin/env bash
set -euo pipefail
set -a; source .env; set +a
IF_NAME="host-macvlan"
ip link show "${IF_NAME}" &>/dev/null && ip link del "${IF_NAME}" || true
ip link add "${IF_NAME}" link "${PARENT_IF}" type macvlan mode bridge
ip addr add "${HOST_MACVLAN_IP}" dev "${IF_NAME}"
ip link set "${IF_NAME}" up
ip route del "${SUBNET}" dev "${IF_NAME}" 2>/dev/null || true
ip route add "${SUBNET}" dev "${IF_NAME}"
echo "[macvlan] Host reachable at ${HOST_MACVLAN_IP}"
