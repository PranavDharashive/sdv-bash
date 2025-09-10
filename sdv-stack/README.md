# sdv-stack

This project provides a comprehensive solution for deploying a Kubernetes cluster and various applications on Ubuntu 22.04 LTS using shell scripting.

## Features

- Automated installation and configuration of Kubernetes prerequisites.
- HAProxy setup for API server load balancing.
- Single-node Kubernetes cluster deployment using Kubeadm.
- Calico CNI integration.
- Deployment of MinIO, MySQL, Redis, and SDV applications.
- Monitoring stack deployment with Prometheus and Grafana.
- Idempotent scripts for seamless re-runs.
- Centralized logging for all installation and cleanup processes.

## Prerequisites

- Ubuntu 22.04 LTS server.
- Sudo privileges.
- Internet connectivity.

## Getting Started

1.  **Clone the repository:**

    ```bash
    git clone <repository-url>
    cd sdv-stack
    ```

2.  **Run the installation script:**

    ```bash
    chmod +x install.sh
    ./install.sh
    ```

    The script will prompt you for the Kubernetes API endpoint IP and the desired Kubernetes version.

## Cleanup

To remove all deployed components and configurations, run the cleanup script:

```bash
chmod +x cleanup.sh
./cleanup.sh
```

## Directory Structure

- `install.sh`: Main installation script.
- `cleanup.sh`: Main cleanup script.
- `README.md`: Project documentation.
- `logs/`: Contains installation and cleanup logs.
- `monitoring/`: Scripts and configurations for Prometheus and Grafana.
- `sdv/`: Scripts and configurations for MySQL, Redis, sdv-middleware, and sdv-web.
- `minio/`: Scripts and configurations for MinIO.
- `k8s-prerequisites/`: Scripts for Kubernetes prerequisites.
- `k8s-setup/`: Scripts for Kubernetes cluster setup.
- `ha-proxy/`: Scripts for HAProxy installation and configuration.

## Logging

All installation and cleanup logs are stored in the `logs/` directory.

## Customization

- **Kubernetes Version:** The `install.sh` script prompts for the Kubernetes version. Ensure you provide a supported version (e.g., 1.31).
- **Application Configurations:** Application-specific configurations can be found and modified within their respective directories (e.g., `sdv/`, `minio/`).
