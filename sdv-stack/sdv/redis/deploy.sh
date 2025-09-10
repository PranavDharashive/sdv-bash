#!/bin/bash

# #############################################################################
# ##
# ## Redis Deployment Script
# ##
# #############################################################################

# Exit immediately if a command exits with a non-zero status.
set -e

BASE_DIR="$1"
LOG_FILE="$BASE_DIR/logs/install.log"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting Redis deployment."

# Deploy Redis
log "Deploying Redis..."
kubectl apply -n sdv -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: sdv
spec:
  selector:
    matchLabels:
      app: redis
  replicas: 1
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - name: redis
          image: redis:latest
          ports:
            - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: sdv
spec:
  selector:
    app: redis
  ports:
    - protocol: TCP
      port: 6379
      targetPort: 6379
  type: ClusterIP
EOF

# Wait for Redis pod to be ready
log "Waiting for Redis pod to be ready..."
kubectl wait --for=condition=ready pod -l app=redis -n sdv --timeout=300s

log "Redis deployment completed."
