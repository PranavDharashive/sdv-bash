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

# Ensure logs directory exists
mkdir -p "$BASE_DIR/logs"

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
bash "$BASE_DIR/k8s-prerequisites/install.sh" "$BASE_DIR"

# 3. Install and Configure HAProxy
log "Installing and configuring HAProxy..."
bash "$BASE_DIR/ha-proxy/install.sh" "$K8S_API_ENDPOINT" "$BASE_DIR"

# 4. Setup Kubernetes Cluster
log "Setting up Kubernetes cluster..."
bash "$BASE_DIR/k8s-setup/install.sh" "$K8S_VERSION" "$BASE_DIR" "$K8S_API_ENDPOINT"

# 5. Deploy MinIO
log "Deploying MinIO..."
bash "$BASE_DIR/minio/deploy.sh" "$BASE_DIR"

# 6. Deploy SDV Applications
log "Deploying SDV applications..."
bash "$BASE_DIR/sdv/deploy.sh" "$BASE_DIR"

# 7. Deploy Monitoring Stack
log "Deploying monitoring stack..."
bash "$BASE_DIR/monitoring/deploy.sh" "$BASE_DIR" "$K8S_API_ENDPOINT"

alias k=kubectl

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
echo "## Access URLs:"
echo "##   - SDV Web App: https://$K8S_API_ENDPOINT/"
echo "##   - MinIO Console: https://$K8S_API_ENDPOINT/minio (User: minioadmin, Pass: minioadmin)"
echo "##   - Grafana Dashboard: https://$K8S_API_ENDPOINT/grafana (User: admin, Pass: admin)"
echo "##"
echo "################################################################################"
