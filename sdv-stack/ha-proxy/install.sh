#!/bin/bash

# #############################################################################
# ##
# ## HAProxy Installation and Configuration Script
# ##
# #############################################################################

# Exit immediately if a command exits with a non-zero status.
set -e

K8S_API_ENDPOINT="$1"
LOG_FILE="/Users/pranavdharashive/sdv-bash/sdv-stack/logs/install.log"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting HAProxy installation and configuration."

# Install HAProxy
log "Installing HAProxy..."
sudo apt-get update
sudo apt-get install -y haproxy

# Enable HAProxy service
log "Enabling HAProxy service..."
sudo systemctl enable haproxy

# Configure HAProxy
log "Configuring HAProxy..."
sudo tee /etc/haproxy/haproxy.cfg <<EOF
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log global
    mode http
    option httplog
    option dontlognull
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

frontend kubernetes_api
    bind *:6443
    mode tcp
    option tcplog
    default_backend kubernetes_nodes

backend kubernetes_nodes
    mode tcp
    option tcp-check
    balance roundrobin
    server master1 $K8S_API_ENDPOINT:6443 check

frontend web_app_http
    bind *:80
    mode http
    default_backend web_app_backend

frontend web_app_https
    bind *:443
    mode http
    default_backend web_app_backend

backend web_app_backend
    mode http
    balance roundrobin
    server webapp_node 127.0.0.1:30080 check
EOF

# Restart HAProxy to apply changes
log "Restarting HAProxy service..."
sudo systemctl restart haproxy

log "HAProxy installation and configuration completed."
