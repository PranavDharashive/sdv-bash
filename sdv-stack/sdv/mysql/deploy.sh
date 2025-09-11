#!/bin/bash

# #############################################################################
# ##
# ## MySQL Deployment Script
# ##
# #############################################################################

# Exit immediately if a command exits with a non-zero status.
set -e

BASE_DIR="$1"
LOG_FILE="$BASE_DIR/logs/install.log"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log "Starting MySQL deployment."

# Create data directory for MySQL
log "Creating /data/mysql-db-data/ directory..."
sudo mkdir -p /data/mysql-db-data
sudo chmod 777 /data/mysql-db-data

# Deploy MySQL
log "Deploying MySQL..."
kubectl apply -n sdv -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: sdv-local-storage
  local:
    path: /data/mysql-db-data
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
  name: mysql-pvc
  namespace: sdv
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: sdv-local-storage
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: sdv
spec:
  selector:
    matchLabels:
      app: mysql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - name: mysql
          image: mysql:8.0
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: "rootpassword"
            - name: MYSQL_DATABASE
              value: "sdv_data"
            - name: MYSQL_USER
              value: "sdvuser"
            - name: MYSQL_PASSWORD
              value: "abcd1234"
          ports:
            - containerPort: 3306
              name: mysql
          volumeMounts:
            - name: mysql-persistent-storage
              mountPath: /var/lib/mysql
      volumes:
        - name: mysql-persistent-storage
          persistentVolumeClaim:
            claimName: mysql-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
  namespace: sdv
spec:
  selector:
    app: mysql
  ports:
    - protocol: TCP
      port: 3306
      targetPort: 3306
  type: ClusterIP
EOF

# Wait for MySQL pod to be ready
log "Waiting for MySQL pod to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql -n sdv --timeout=300s

# Verify MySQL setup and create user/database
log "Verifying MySQL setup and creating user/database..."
MYSQL_POD_NAME=$(kubectl get pods -n sdv -l app=mysql -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n sdv "$MYSQL_POD_NAME" -- mysql -h mysql-service -P 3306 -u root -prootpassword -e "CREATE DATABASE IF NOT EXISTS sdv_data;"
kubectl exec -n sdv "$MYSQL_POD_NAME" -- mysql -h mysql-service -P 3306 -u root -prootpassword -e "CREATE USER IF NOT EXISTS 'sdvuser'@'%' IDENTIFIED BY 'abcd1234';"
kubectl exec -n sdv "$MYSQL_POD_NAME" -- mysql -h mysql-service -P 3306 -u root -prootpassword -e "GRANT ALL PRIVILEGES ON sdv_data.* TO 'sdvuser'@'%';"
kubectl exec -n sdv "$MYSQL_POD_NAME" -- mysql -h mysql-service -P 3306 -u root -prootpassword -e "FLUSH PRIVILEGES;"

log "MySQL deployment completed."
