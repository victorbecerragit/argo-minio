!/bin/bash

# Exit immediately on failure of any command within a pipeline
set -o pipefail

# Kubeconfig optionally passed as the first argument
KUBECONFIG=${1}

# Export KUBECONFIG
export KUBECONFIG="$KUBECONFIG"

# Define log file location
LOG_FILE="/tmp/directpv_install.log"

# Timestamp for each run
echo " Directpv bootstrap started at $(date)" >> "$LOG_FILE"

log_error_and_exit() {
    echo "Error during '$1' command." | tee -a "$LOG_FILE"
    exit 1
}

echo "Installing DirectPV binary" 
# Download DirectPV plugin.
release=$(curl -sfL "https://api.github.com/repos/minio/directpv/releases/latest" | awk '/tag_name/ { print substr($2, 3, length($2)-4) }')
curl -fLo kubectl-directpv https://github.com/minio/directpv/releases/download/v${release}/kubectl-directpv_${release}_linux_amd64

# Make the binary executable.
chmod a+x kubectl-directpv 
sudo mv kubectl-directpv /usr/local/bin/kubectl-directpv  >> "$LOG_FILE" 2>&1 || log_error_and_exit "sudo mv"

echo "Label nodes for directpv installation directpv=yes"
# TODO Replace node's name with actual nodes for directpv installation
# Ensure the correct nodes are passed here before installation - this is crucial for DirectPV to function correctly.
kubectl label nodes minioclu-06 directpv=yes
kubectl label nodes minioclu-07 directpv=yes
kubectl label nodes minioclu-08 directpv=yes
kubectl label nodes minioclu-09 directpv=yes

echo "Installing DirectPV with labels and toleration..." | tee -a "$LOG_FILE"
kubectl directpv install --node-selector directpv=yes --tolerations minio-directpv=storage:NoSchedule >> "$LOG_FILE" 2>&1 || log_error_and_exit "directpv install"

# Wait for DirectPV to be ready
echo "Waiting for DirectPV to be ready..." | tee -a "$LOG_FILE"
kubectl wait --for=condition=Ready pod -l app=directpv --timeout=120s >> "$LOG_FILE" 2>&1 || log_error_and_exit "kubectl wait"

echo "Show node names..." | tee -a "$LOG_FILE"
NODE_LIST=$(kubectl directpv info | awk -F '│' '/•/ {gsub(/•| /, "", $2); print $2}') >> "$LOG_FILE" 2>&1 || log_error_and_exit "directpv info"

# Check if NODE_LIST is empty
if [[ -z "$NODE_LIST" ]]; then
  echo "No nodes detected by DirectPV. Aborting installation." | tee -a "$LOG_FILE"
  exit 1
else
  echo " Nodes detected:" | tee -a "$LOG_FILE"
  echo "$NODE_LIST" | tee -a "$LOG_FILE"
fi

echo "Discovering available disks..." | tee -a "$LOG_FILE"

kubectl directpv discover  >> "$LOG_FILE" 2>&1  || log_error_and_exit "directpv discover"

# Optionally wait or confirm before proceeding
# This step is crucial as it formats the disks and destroys data.

read -p "Do you have a drives.yaml ready? This step will format disks and destroy data! (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "Aborting before disk init. Prepare your drives.yaml file first." | tee -a "$LOG_FILE"
  exit 1
fi

echo "Initializing drives (this will format selected disks!)" | tee -a "$LOG_FILE"
kubectl directpv init drives.yaml --dangerous >> "$LOG_FILE" 2>&1 || log_error_and_exit "directpv init"

echo "DirectPV installation and initialization complete!" | tee -a "$LOG_FILE"
echo "You now have 12 DirectPV volumes ready under 'directpv-min-io' StorageClass." | tee -a "$LOG_FILE"

