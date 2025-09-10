#!/bin/bash

# #############################################################################
# ##
# ## sdv-stack Cleanup Script
# ##
# #############################################################################

# Exit immediately if a command exits with a non-zero status.
set -e

# #############################################################################
# ## Global Variables
# #############################################################################

LOG_FILE="/Users/pranavdharashive/sdv-bash/sdv-stack/logs/cleanup.log"

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

log "Starting sdv-stack cleanup."

# 1. Kubernetes Package Removal
log "Removing Kubernetes packages..."
# Unhold packages if they were held
sudo apt-mark unhold kubeadm kubectl kubelet || true
sudo apt-get purge -y kubeadm kubectl kubelet kubernetes-cni || true
sudo apt-get autoremove -y || true

# 2. Directory Removal
log "Removing Kubernetes configuration and data directories..."
sudo rm -rf /etc/kubernetes || true
sudo rm -rf "$HOME"/.kube || true
sudo rm -rf /var/lib/etcd || true
sudo rm -rf /etc/containerd || true
sudo rm -rf /etc/cni || true

# 3. HAProxy Cleanup (if installed)
log "Cleaning up HAProxy..."
sudo systemctl stop haproxy || true
sudo systemctl disable haproxy || true
sudo apt-get purge -y haproxy || true
sudo rm -rf /etc/haproxy || true

# 4. Containerd and Docker Cleanup
log "Cleaning up containerd and docker..."
sudo systemctl stop containerd || true
sudo systemctl disable containerd || true
sudo apt-get purge -y containerd.io || true
sudo rm -rf /etc/containerd || true

sudo systemctl stop docker || true
sudo systemctl disable docker || true
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || true
sudo rm -rf /var/lib/docker || true

# 5. Iptables Flush
log "Flushing iptables rules..."
sudo iptables -F || true
sudo iptables -t nat -F || true
sudo iptables -t mangle -F || true
sudo iptables -X || true

# 6. Remove swapoff entry from fstab
log "Re-enabling swap..."
sudo sed -i '/ swap / s/^#\(.*\)$/\1/g' /etc/fstab || true
sudo swapon -a || true

log "sdv-stack cleanup completed successfully."
