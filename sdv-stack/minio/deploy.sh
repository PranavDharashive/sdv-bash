#!/bin/bash

# #############################################################################
# ##
# ## MinIO Deployment Script
# ##
# #############################################################################

# Exit immediately if a command exits with a non-zero status.
set -e

LOG_FILE="/Users/pranavdharashive/sdv-bash/sdv-stack/logs/install.log"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting MinIO deployment."

# Create minio namespace
log "Creating minio namespace..."
kubectl create namespace minio || true

# Create data directory for MinIO
log "Creating /data/minio-storage/ directory..."
sudo mkdir -p /data/minio-storage
sudo chmod 777 /data/minio-storage

# Create MinIO deployment and service
log "Deploying MinIO..."
kubectl apply -n minio -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: minio-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /data/minio-storage
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - $(hostname)
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: minio-pvc
  namespace: minio
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: local-storage
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
  namespace: minio
spec:
  selector:
    matchLabels:
      app: minio
  replicas: 1
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
        - name: minio
          image: minio/minio:latest
          args: ["server", "/data"]
          env:
            - name: MINIO_ROOT_USER
              value: "minioadmin"
            - name: MINIO_ROOT_PASSWORD
              value: "minioadmin"
          ports:
            - containerPort: 9000
              name: http
            - containerPort: 9001
              name: console
          volumeMounts:
            - name: storage
              mountPath: "/data"
      volumes:
        - name: storage
          persistentVolumeClaim:
            claimName: minio-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: minio-service
  namespace: minio
spec:
  type: NodePort
  selector:
    app: minio
  ports:
    - port: 9000
      targetPort: 9000
      nodePort: 30009
      name: api
    - port: 9001
      targetPort: 9001
      nodePort: 30090
      name: console
EOF

# Wait for MinIO pod to be ready
log "Waiting for MinIO pod to be ready..."
kubectl wait --for=condition=ready pod -l app=minio -n minio --timeout=300s

log "MinIO deployment completed."
