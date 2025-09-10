#!/bin/bash

# #############################################################################
# ##
# ## SDV Middleware Deployment Script
# ##
# #############################################################################

# Exit immediately if a command exits with a non-zero status.
set -e

LOG_FILE="/Users/pranavdharashive/sdv-bash/sdv-stack/logs/install.log"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting SDV Middleware deployment."

# Deploy sdv-middleware
log "Deploying sdv-middleware..."
kubectl apply -n sdv -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sdv-middleware
  namespace: sdv
spec:
  selector:
    matchLabels:
      app: sdv-middleware
  replicas: 1
  template:
    metadata:
      labels:
        app: sdv-middleware
    spec:
      containers:
        - name: sdv-middleware
          image: nginx:latest # Placeholder image, replace with actual sdv-middleware image
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: sdv-middleware-service
  namespace: sdv
spec:
  selector:
    app: sdv-middleware
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
EOF

# Wait for sdv-middleware pod to be ready
log "Waiting for sdv-middleware pod to be ready..."
kubectl wait --for=condition=ready pod -l app=sdv-middleware -n sdv --timeout=300s

log "SDV Middleware deployment completed."
