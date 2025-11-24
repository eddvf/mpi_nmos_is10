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

## ⚙️ Configuration Variable Reference

The `.env` file acts as the single source of truth for the entire lab. The variables below are categorized by their function to help you identify which settings must match your physical environment and which are logical choices.

### 1. Physical Network Configuration (Critical)
These variables **must** match the physical network your host machine is connected to. [cite_start]Because we use the `macvlan` driver, containers attach directly to your LAN like physical devices[cite: 16].



| Variable | Description | How to find it |
| :--- | :--- | :--- |
| `PARENT_IF` | The physical network interface on your host machine that connects to the LAN (e.g., `eth0`, `enp3s0`). | Run `ip addr` or `ifconfig` (Linux, Mac) to find the active interface. |
| `SUBNET` | The CIDR subnet of your physical network. | Usually `192.168.1.0/24`. Ensure this matches your router's setting. |
| `GATEWAY` | The IP address of your network router. | Usually `192.168.1.1`. |

### 2. Static IP Allocation
You must assign static IP addresses to each service. [cite_start]These IPs must be **inside** your `SUBNET` but **outside** your router's DHCP range (to avoid IP conflicts with other devices on your LAN)[cite: 15, 16].

| Variable | Description |
| :--- | :--- |
| `BIND_IP` | IP for the Bind9 DNS server. [cite_start]All other containers use this to discover `_nmos` services[cite: 1, 15]. |
| `PROXY_IP` | IP for the Nginx Reverse Proxy. [cite_start]This is the **primary** IP you connect to via HTTPS[cite: 15, 21]. |
| `REGISTRY_IP` | [cite_start]Dedicated IP for the Sony/NVIDIA NMOS Registry[cite: 15]. |
| `NODE_IP` | [cite_start]Dedicated IP for the Virtual NMOS Node[cite: 15]. |
| `KEYCLOAK_IP` | [cite_start]Dedicated IP for the Authorization Server[cite: 15]. |
| `HOST_MACVLAN_IP` | A virtual IP assigned to the Host machine. [cite_start]This allows the Host to communicate with the containers, bridging the Macvlan isolation[cite: 16]. |

### 3. Logical Identities & Discovery
[cite_start]These variables define how services identify themselves and discover each other via DNS-SD (IS-04)[cite: 1, 17].

| Variable | Description |
| :--- | :--- |
| `DOMAIN` | The local DNS domain suffix (e.g., `easyebu.com`). Services are accessible at `hostname.domain`. |
| `REGISTRY_HOST` | FQDN for the registry. [cite_start]Must match the Common Name (CN) in the SSL certificate[cite: 19]. |
| `NODE_HOST` | [cite_start]FQDN for the virtual node[cite: 18]. |
| `KEYCLOAK_HOST` | [cite_start]FQDN for the Keycloak server[cite: 21]. |

### 4. Security & Application Secrets
These variables control the IS-10 Authorization behavior and database access.

| Variable | Description |
| :--- | :--- |
| `KEYCLOAK_REALM` | The logical workspace within Keycloak. [cite_start]The script imports configuration into this realm[cite: 18, 19]. |
| `POSTGRES_USER` | [cite_start]Username for the Keycloak database[cite: 15]. |
| `POSTGRES_PASSWORD`| Password for the Keycloak database. |

## 🛡️ Operational Guide

For security critical behaviors, threat impact, and infrastructure risk assessment, see:

📌 **[Operational Guide & Risk Assessment](operational_guide.md)**