#!/bin/bash

# Clean previous namespaces if they exist
ip netns del red 2>/dev/null
ip netns del router 2>/dev/null
ip netns del blue 2>/dev/null

# Create namespaces
ip netns add red
ip netns add router
ip netns add blue

# Create veth pairs
ip link add veth-red type veth peer name veth-r1
ip link add veth-blue type veth peer name veth-r2

# Assign interfaces
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

# Enable routing
ip netns exec router sysctl -w net.ipv4.ip_forward=1

# Default routes
ip netns exec red ip route add default via 10.0.1.1
ip netns exec blue ip route add default via 10.0.2.1

echo "Setup complete."