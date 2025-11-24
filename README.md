# Secure NMOS Lab (IS-10)

This project deploys a fully containerized, secure NMOS environment featuring the Sony/NVIDIA NMOS C++ Registry and Node, secured by Nginx (TLS) and Keycloak (IS-10 Authorization).

The setup includes automatic generation of DNS records (Bind9) for IS-04 discovery and self-signed certificates for HTTPS communication.

## 🏗 Architecture

The stack runs on **Docker Compose** using the `macvlan` network driver to assign distinct IP addresses to containers, simulating real physical devices on your network.

| Service | Function | Protocol/Port |
| :--- | :--- | :--- |
| **Nginx** | Reverse Proxy & TLS Termination | HTTPS (443) |
| **Bind9** | IS-04 DNS-SD Discovery & DNS Resolution | UDP/TCP (53) |
| **Keycloak** | IS-10 Authorization Server (OAuth2/OpenID) | HTTP (8080) internal |
| **NMOS Registry** | IS-04 Registry Service | HTTP (80) internal |
| **NMOS Node** | Virtual NMOS Node (simulating a device) | HTTP (80) internal |
| **Postgres** | Database for Keycloak | TCP (5432) |

## 📋 Prerequisites

* **OS:** Linux (Required for Macvlan support).
* **Docker** & **Docker Compose**.
* **OpenSSL**: For certificate generation.
* **gettext-base**: For the `envsubst` command used in templating.

## ⚙️ Configuration

This project relies heavily on environment variables. Create a `.env` file in the root directory before starting.

### Sample `.env`
```ini
PROJECT_NAME=nmos_lab
DOMAIN=easyebu.com

# Network Configuration (Must match your physical network)
PARENT_IF=eth0
SUBNET=192.168.1.0/24
GATEWAY=192.168.1.1

# Static IPs for Containers (Must be unused IPs in your SUBNET)
BIND_IP=192.168.1.50
PROXY_IP=192.168.1.51
REGISTRY_IP=192.168.1.52
NODE_IP=192.168.1.53
KEYCLOAK_IP=192.168.1.54
PG_IP=192.168.1.55
HOST_MACVLAN_IP=192.168.1.60

# Hostnames (Mapped in DNS automatically)
REGISTRY_HOST=nmos-registry.easyebu.com
NODE_HOST=nmos-virtnode.easyebu.com
KEYCLOAK_HOST=keycloak.easyebu.com

# Keycloak / DB
POSTGRES_DB=keycloak
POSTGRES_USER=keycloak
POSTGRES_PASSWORD=password123
KEYCLOAK_REALM=nmos

# Docker Images
BIND_IMAGE=ubuntu/bind9
POSTGRES_IMAGE=postgres:15
KEYCLOAK_IMAGE=quay.io/keycloak/keycloak:22.0
NMOS_IMAGE=nmos-cpp:latest
NGINX_IMAGE=nginx:latest
PUBLIC_HTTP_PORT=80
PUBLIC_HTTPS_PORT=443
```

## 🛡️ Operational Guide

For security critical behaviors, threat impact, and infrastructure risk assessment, see:

📌 **[Operational Guide & Risk Assessment](operational_guide.md)**