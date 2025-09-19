#!/bin/bash

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration from environment variables
NODE_NAME="${NODE_NAME:-}"
WAIT_TIME="${WAIT_TIME:-30}"
DANGEROUS_MODE="${DANGEROUS_MODE:-true}"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Check if NODE_NAME is provided
if [ -z "$NODE_NAME" ]; then
    log "ERROR: NODE_NAME environment variable is required"
    exit 1
fi

log "Starting DirectPV setup for node: $NODE_NAME"

# Label node with error handling
if kubectl label node "$NODE_NAME" directpv-node=yes --overwrite=true; then
    log "Successfully labeled node $NODE_NAME"
else
    log "ERROR: Failed to label node $NODE_NAME"
    exit 1
fi

# Verify label was applied
if kubectl describe node "$NODE_NAME" | grep -q "directpv-node=yes"; then
    log "Label verification successful"
else
    log "WARNING: Label verification failed"
fi

# Wait for directpv to scan the node
log "Waiting ${WAIT_TIME} seconds for directpv to scan the node..."
sleep "$WAIT_TIME"

# Discover drives
log "Discovering drives on node $NODE_NAME"
if kubectl directpv discover --nodes="$NODE_NAME" --output-file "drives-${NODE_NAME}.yaml"; then
    log "Drive discovery completed"
else
    log "ERROR: Drive discovery failed"
    exit 1
fi

# Initialize drives if dangerous mode is enabled
if [ "$DANGEROUS_MODE" = "true" ]; then
    log "Initializing drives (dangerous mode enabled)"
    if kubectl directpv init "drives-${NODE_NAME}.yaml" --dangerous; then
        log "Drive initialization completed successfully"
    else
        log "ERROR: Drive initialization failed"
        exit 1
    fi
else
    log "Skipping drive initialization (dangerous mode disabled)"
fi

log "DirectPV setup completed for node: $NODE_NAME"

