#!/bin/bash

# Exit on any error
set -e

# --- Configuration ---
# The physical interface connected to your lab network
PARENT_INTERFACE="enp1s0"

# An IP for the host on the macvlan network.
HOST_MACVLAN_IP="10.100.64.19/24"

# The IP range you defined for your containers in docker-compose.yml
CONTAINER_SUBNET="10.100.64.0/24"
# --- End Configuration ---

# Create a unique name for the macvlan interface
MACVLAN_IF_NAME="host-macvlan"

echo "Configuring macvlan for host-container communication..."

# Check if interface already exists and clean up if needed
if ip link show ${MACVLAN_IF_NAME} &>/dev/null; then
    echo "Removing existing ${MACVLAN_IF_NAME} interface..."
    ip link delete ${MACVLAN_IF_NAME}
fi

# Create macvlan interface in bridge mode, linked to the lab NIC
ip link add ${MACVLAN_IF_NAME} link ${PARENT_INTERFACE} type macvlan mode bridge

# Assign the dedicated IP address to the new interface
ip addr add ${HOST_MACVLAN_IP} dev ${MACVLAN_IF_NAME}

# Bring the interface up
ip link set ${MACVLAN_IF_NAME} up

# Wait for interface to be ready
sleep 2

# Add a route so the host knows how to reach the containers
ip route del ${CONTAINER_SUBNET} dev ${MACVLAN_IF_NAME} 2>/dev/null || true
ip route add ${CONTAINER_SUBNET} dev ${MACVLAN_IF_NAME}

echo "Success"
echo "Host macvlan IP: ${HOST_MACVLAN_IP%/*}"