#!/bin/bash

# #############################################################################
# ##
# ## SDV Applications Deployment Script
# ##
# #############################################################################

# Exit immediately if a command exits with a non-zero status.
set -e

LOG_FILE="/Users/pranavdharashive/sdv-bash/sdv-stack/logs/install.log"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting SDV applications deployment."

# Create sdv namespace
log "Creating sdv namespace..."
kubectl create namespace sdv || true

# Create local storage class
log "Creating sdv-local-storage class..."
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: sdv-local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

# Deploy MySQL
log "Deploying MySQL..."
./sdv/mysql/deploy.sh

# Deploy Redis
log "Deploying Redis..."
./sdv/redis/deploy.sh

# Deploy sdv-middleware
log "Deploying sdv-middleware..."
./sdv/sdv-middleware/deploy.sh

# Deploy sdv-web
log "Deploying sdv-web..."
./sdv/sdv-web/deploy.sh

log "SDV applications deployment completed."
