#!/bin/bash

# #############################################################################
# ##
# ## SDV Web Deployment Script
# ##
# #############################################################################

# Exit immediately if a command exits with a non-zero status.
set -e

BASE_DIR="$1"
LOG_FILE="$BASE_DIR/logs/install.log"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting SDV Web deployment."

# Deploy sdv-web
log "Deploying sdv-web..."
kubectl apply -n sdv -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sdv-web
  namespace: sdv
spec:
  selector:
    matchLabels:
      app: sdv-web
  replicas: 1
  template:
    metadata:
      labels:
        app: sdv-web
    spec:
      containers:
        - name: sdv-web
          image: nginx:latest # Placeholder image, replace with actual sdv-web image
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: sdv-web-service
  namespace: sdv
spec:
  type: NodePort
  selector:
    app: sdv-web
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080 # As per HAProxy configuration
EOF

# Wait for sdv-web pod to be ready
log "Waiting for sdv-web pod to be ready..."
kubectl wait --for=condition=ready pod -l app=sdv-web -n sdv --timeout=300s

log "SDV Web deployment completed."
