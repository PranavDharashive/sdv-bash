#!/bin/bash

# #############################################################################
# ##
# ## sdv-stack Installation Script
# ##
# #############################################################################

# Exit immediately if a command exits with a non-zero status.
set -e

# #############################################################################
# ## Global Variables
# #############################################################################

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$BASE_DIR/logs/install.log"
K8S_API_ENDPOINT=""
K8S_VERSION=""

# #############################################################################
# ## Functions
# #############################################################################

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# #############################################################################
# ## Main Script
# #############################################################################

# Create log file
touch "$LOG_FILE"

log "Starting sdv-stack installation."

# Prompt for user input
read -p "Enter the Kubernetes API endpoint IP: " K8S_API_ENDPOINT
read -p "Enter the Kubernetes version (e.g., 1.31): " K8S_VERSION

log "Kubernetes API Endpoint IP: $K8S_API_ENDPOINT"
log "Kubernetes Version: $K8S_VERSION"

# 1. Install Kubernetes Prerequisites
log "Installing Kubernetes prerequisites..."
/Users/pranavdharashive/sdv-bash/sdv-stack/k8s-prerequisites/install.sh

# 3. Install and Configure HAProxy
log "Installing and configuring HAProxy..."
/Users/pranavdharashive/sdv-bash/sdv-stack/ha-proxy/install.sh "$K8S_API_ENDPOINT"

# 4. Setup Kubernetes Cluster
log "Setting up Kubernetes cluster..."
/Users/pranavdharashive/sdv-bash/sdv-stack/k8s-setup/install.sh "$K8S_VERSION"

# 5. Deploy MinIO
log "Deploying MinIO..."
/Users/pranavdharashive/sdv-bash/sdv-stack/minio/deploy.sh

# 6. Deploy SDV Applications
log "Deploying SDV applications..."
/Users/pranavdharashive/sdv-bash/sdv-stack/sdv/deploy.sh

# 7. Deploy Monitoring Stack
log "Deploying monitoring stack..."
/Users/pranavdharashive/sdv-bash/sdv-stack/monitoring/deploy.sh

log "sdv-stack installation completed successfully."

# Final success message
echo "################################################################################"
echo "## sdv-stack Deployment Summary"
echo "################################################################################"
echo "##"
echo "## Kubernetes Version: $K8S_VERSION"
echo "## Kubernetes API Endpoint: https://$K8S_API_ENDPOINT:6443"
echo "##"
echo "## Deployed Components:"
echo "##   - Kubernetes Prerequisites"
echo "##   - HAProxy"
echo "##   - Kubernetes Cluster (kubeadm)"
echo "##   - Calico CNI"
echo "##   - MinIO"
echo "##   - MySQL"
echo "##   - Redis"
echo "##   - sdv-middleware"
echo "##   - sdv-web"
echo "##   - Prometheus"
echo "##   - Grafana"
echo "##"
echo "################################################################################"