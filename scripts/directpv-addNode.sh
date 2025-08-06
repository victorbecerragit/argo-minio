#!/bin/bash

# Check if the NODE_NAME parameter is provided
if [ -z "$1" ]; then
  echo "Usage: $0 NODE_NAME"
  exit 1
fi

# Assign the first argument to NODE_NAME
NODE_NAME="$1"
# Use NODE_NAME for your logic
echo "The node name is: $NODE_NAME"
#Label node
kubectl label node $NODE_NAME directpv=yes
kubectl describe node $NODE_NAME | grep -i directpv=yes

# Wait for directpv to scan the node labeled
echo "Waiting for directpv to scan the node..."
sleep 30

# Discover drives on all nodes (or specify --node <node-name>)
kubectl directpv discover --nodes=$NODE_NAME --output-file drives-$NODE_NAME.yaml

# Uncomment the next line if you're ready to apply
kubectl directpv init drives-$NODE_NAME.yaml --dangerous