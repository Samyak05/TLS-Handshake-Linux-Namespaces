#!/bin/bash

ip netns del red 2>/dev/null
ip netns del router 2>/dev/null
ip netns del blue 2>/dev/null

echo "Namespaces removed."