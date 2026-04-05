#!/bin/bash

# Exit immediately if any command fails
set -e

# Get project root directory dynamically
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Project root: $BASE_DIR"

# ✅ Check if cert directories exist AND are not empty
if [ -z "$(ls -A "$BASE_DIR/red_namespace" 2>/dev/null)" ] || \
   [ -z "$(ls -A "$BASE_DIR/blue_namespace" 2>/dev/null)" ]; then
    echo "❌ Certificates missing or empty."
    echo "👉 Run: ./generate_certs.sh"
    exit 1
fi

echo "✅ Certificates found."

# Clean previous namespaces if they exist
ip netns del red 2>/dev/null || true
ip netns del router 2>/dev/null || true
ip netns del blue 2>/dev/null || true

# Create namespaces
ip netns add red
ip netns add router
ip netns add blue

# Create veth pairs
ip link add veth-red type veth peer name veth-r1
ip link add veth-blue type veth peer name veth-r2

# Assign to namespaces
ip link set veth-red netns red
ip link set veth-r1 netns router
ip link set veth-r2 netns router
ip link set veth-blue netns blue

# Assign IP addresses
ip netns exec red ip addr add 10.0.1.2/24 dev veth-red
ip netns exec router ip addr add 10.0.1.1/24 dev veth-r1
ip netns exec router ip addr add 10.0.2.1/24 dev veth-r2
ip netns exec blue ip addr add 10.0.2.2/24 dev veth-blue

# Bring interfaces up
ip netns exec red ip link set veth-red up
ip netns exec router ip link set veth-r1 up
ip netns exec router ip link set veth-r2 up
ip netns exec blue ip link set veth-blue up

ip netns exec red ip link set lo up
ip netns exec router ip link set lo up
ip netns exec blue ip link set lo up

# Enable Routing in Router
ip netns exec router sysctl -w net.ipv4.ip_forward=1

# Add Default Routes
ip netns exec red ip route add default via 10.0.1.1
ip netns exec blue ip route add default via 10.0.2.1

# Create cert directories inside namespaces
ip netns exec red mkdir -p /certs
ip netns exec blue mkdir -p /certs

# Copy certificates safely
ip netns exec blue cp -r "$BASE_DIR/blue_namespace/." /certs/
ip netns exec red cp -r "$BASE_DIR/red_namespace/." /certs/

echo "✅ Certificates copied into namespaces."
echo "🚀 Setup complete."