#!/bin/bash

# #############################################################################
# ##
# ## SDV Applications Deployment Script
# ##
# #############################################################################

# Exit immediately if a command exits with a non-zero status.
set -e

BASE_DIR="$1"
LOG_FILE="$BASE_DIR/logs/install.log"

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
"$BASE_DIR/sdv/mysql/deploy.sh" "$BASE_DIR"

# Deploy Redis
log "Deploying Redis..."
"$BASE_DIR/sdv/redis/deploy.sh" "$BASE_DIR"

# Deploy sdv-middleware
log "Deploying sdv-middleware..."
"$BASE_DIR/sdv/sdv-middleware/deploy.sh" "$BASE_DIR"

# Deploy sdv-web
log "Deploying sdv-web..."
"$BASE_DIR/sdv/sdv-web/deploy.sh" "$BASE_DIR"

log "SDV applications deployment completed."
