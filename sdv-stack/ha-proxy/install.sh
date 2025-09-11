#!/bin/bash

# #############################################################################
# ##
# ## HAProxy Installation and Configuration Script
# ##
# #############################################################################

# Exit immediately if a command exits with a non-zero status.
set -e

K8S_API_ENDPOINT="$1"
BASE_DIR="$2"
LOG_FILE="$BASE_DIR/logs/install.log"

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

#frontend kubernetes_api
#    bind *:6443
#    mode tcp
#    option tcplog
#    default_backend kubernetes_nodes

#backend kubernetes_nodes
#    mode tcp
#    option tcp-check
#    balance roundrobin
#    server master1 $K8S_API_ENDPOINT:6443 check

frontend http_front
    bind *:80
    mode http
    redirect scheme https code 301

frontend https_front
    bind *:443 ssl crt /etc/ssl/certs/haproxy.pem no-sslv3 no-tlsv10
    mode http
    acl is_minio path_beg /minio
    acl is_grafana path_beg /grafana
    use_backend minio_backend if is_minio
    use_backend grafana_backend if is_grafana
    default_backend web_app_backend

backend web_app_backend
    mode http
    balance roundrobin
    server webapp_node 127.0.0.1:30080 check

backend minio_backend
    mode http
    balance roundrobin
    http-request set-path %[path,regsub(^/minio(/)?(.*)$,/\2)]
    http-response replace-header Location ^/(.*) /minio/\1
    server minio_node 127.0.0.1:30090 check

backend grafana_backend
    mode http
    balance roundrobin
    http-request set-path %[path,regsub(^/grafana(/)?(.*)$,/\2)]
    http-response replace-header Location ^/(.*) /grafana/\1
    server grafana_node 127.0.0.1:30007 check
EOF

# Validate HAProxy configuration
log "Validating HAProxy configuration..."
if ! sudo haproxy -c -f /etc/haproxy/haproxy.cfg; then
    log "HAProxy configuration is invalid. Please check the output above."
    exit 1
fi

# Restart HAProxy to apply changes
log "Restarting HAProxy service..."
sudo systemctl restart haproxy

log "HAProxy installation and configuration completed."
