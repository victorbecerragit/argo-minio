#!/bin/bash

export TERM=dumb
export NO_COLOR=1

set -uo pipefail  # exit on undefined vars, pipe failures only

# Configuration from environment variables
DANGEROUS_MODE="${DANGEROUS_MODE:-false}"
WAIT_TIME="${WAIT_TIME:-2m}"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting DirectPV setup for all nodes"

# Discover drives
log "Discovering drives on all nodes"
if kubectl directpv discover --timeout="$WAIT_TIME" --output-file drives-discovery-all-nodes.yaml; then
    if [ ! -s drives-discovery-all-nodes.yaml ]; then
        log "No drives discovered (discovery file is empty), continuing without error"
        
    else
        log "Drive discovery completed"
    fi
else
    # Do not exit, allow handling downstream
    # Capture stderr into a variable
    init_output=$(kubectl directpv discover --timeout="$WAIT_TIME" --output-file drives-discovery-all-nodes.yaml 2>&1)
    # Check for specific "no drives" message in output
            if echo "$init_output" | grep -q "No drives are available to initialize"; then
                log "No drives to initialize, continuing without error"
            else
                log "ERROR: Drive discovery command failed"
                log "Details: $init_output"
            fi
fi

# Initialize drives if dangerous mode is enabled and discovery file is not empty
if [ "$DANGEROUS_MODE" = "true" ]; then
    if [ -s drives-discovery-all-nodes.yaml ]; then
        log "Initializing drives (dangerous mode enabled)"
        
        # Capture stderr into a variable
        init_output=$(kubectl directpv --quiet init "drives-discovery-all-nodes.yaml" --dangerous 2>&1)
        # Check for specific "no drives" message in output
            if echo "$init_output" | grep -q "No drives are available to initialize"; then
                log "No drives to initialize, continuing without error"
            else
                log "ERROR: Drive initialization failed"
                log "Details: $init_output"
                # Optionally exit or handle error
            fi
    else
        log "Skipping drive initialization since no drives were discovered"
    fi
else
    log "Skipping drive initialization (dangerous mode disabled)"
fi

log "DirectPV setup completed for all nodes"
