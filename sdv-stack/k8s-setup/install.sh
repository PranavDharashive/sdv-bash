#!/bin/bash

# #############################################################################
# ##
# ## Kubernetes Cluster Setup Script
# ##
# #############################################################################

# Exit immediately if a command exits with a non-zero status.
set -e

K8S_VERSION="$1"
BASE_DIR="$2"
K8S_API_ENDPOINT="$3"
LOG_FILE="$BASE_DIR/logs/install.log"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting Kubernetes cluster setup."

# Install kubeadm, kubelet, kubectl
log "Installing kubeadm, kubelet, kubectl version $K8S_VERSION..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# Add Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes apt repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Initialize Kubernetes cluster
log "Initializing Kubernetes cluster..."
sudo kubeadm init --apiserver-advertise-address=$K8S_API_ENDPOINT --pod-network-cidr=10.244.0.0/16

# Configure kubeconfig for current user
log "Configuring kubeconfig for current user..."
mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -un)":"$(id -gn)" "$HOME"/.kube/config

# Configure kubeconfig for root user
log "Configuring kubeconfig for root user..."
sudo mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown root:root /root/.kube/config

# Install Calico CNI
log "Installing Calico CNI..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml

# Wait for Calico pods to be ready
log "Waiting for Calico pods to be ready..."
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=300s

# Remove control-plane taint
log "Removing control-plane taint..."
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

log "Kubernetes cluster setup completed."
