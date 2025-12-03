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



## 🚀 Quick Start Guide

### Prerequisites
- Docker and Docker Compose installed
- Git installed
- Make command available
- Root/sudo access for initial setup

---

### 📦 Step 1: Clone the Repository
```bash
# Clone the repository
git clone git@github.com:eddvf/mpi_nmos_is10.git
cd mpi_nmos_is10
```
---

### 🔐 Step 2: Fix File Permissions (Critical!)

**⚠️ This step is essential to avoid "Permission denied" errors.**

The automation scripts need write access to generate certificates and configuration files. If you cloned the repository using `sudo` or in a protected directory, you must change ownership:
```bash
# Grant your user full ownership of all project files
sudo chown -R $USER:$(id -gn) .
```

---

### ⚙️ Step 3: Configure Environment Variables

The project uses a `.env` file to manage all configuration. You'll need to customize this file with your network settings.
```bash
# 1. Create your configuration file from the template
cp .env.example .env

# 2. Open the file in your preferred editor
nano .env    # or vim, code, etc.
```

#### 📋 Configuration Checklist

When editing your `.env` file, ensure you update these critical settings:

| Variable | Description | Example |
|----------|-------------|---------|
| **PARENT_IF** | Your network interface name | `eth0`, `ens33`, `enp0s3` |
| **SUBNET** | Your network subnet | `192.168.1.0/24` |
| **GATEWAY** | Your network gateway | `192.168.1.1` |
| **DOMAIN** | Your domain name | `yourlab.com` |
| **Static IPs** | Unused IPs in your subnet | See sample below |

#### 📝 Sample `.env` Configuration

Here's a complete example configuration. **You must modify the IP addresses and network settings to match your environment:**
```ini
# Project Identification
PROJECT_NAME=nmos_lab
DOMAIN=easyebu.com              # ← Change to your domain

# Network Configuration (MUST match your physical network)
PARENT_IF=eth0                  # ← Change to your network interface
SUBNET=192.168.1.0/24          # ← Change to your subnet
GATEWAY=192.168.1.1            # ← Change to your gateway

# Container Static IPs (MUST be unused IPs in your subnet)
BIND_IP=192.168.1.50           # DNS Server
PROXY_IP=192.168.1.51          # Nginx Proxy
REGISTRY_IP=192.168.1.52       # NMOS Registry
NODE_IP=192.168.1.53           # NMOS Node
KEYCLOAK_IP=192.168.1.54       # Auth Server
PG_IP=192.168.1.55             # Database
HOST_MACVLAN_IP=192.168.1.60   # Host Bridge

# Service Hostnames (automatically mapped in DNS)
REGISTRY_HOST=nmos-registry.easyebu.com
NODE_HOST=nmos-virtnode.easyebu.com
KEYCLOAK_HOST=keycloak.easyebu.com

# Database Configuration
POSTGRES_DB=keycloak
POSTGRES_USER=keycloak
POSTGRES_PASSWORD=password123   # ← Change in production!
KEYCLOAK_REALM=nmos

# Docker Images (keep defaults unless customizing)
BIND_IMAGE=ubuntu/bind9
POSTGRES_IMAGE=postgres:15
KEYCLOAK_IMAGE=quay.io/keycloak/keycloak:22.0
NMOS_IMAGE=nmos-cpp:latest
NGINX_IMAGE=nginx:latest

# Port Configuration
PUBLIC_HTTP_PORT=80
PUBLIC_HTTPS_PORT=443
```

---

### 🏗️ Step 4: Build and Deploy

Once your `.env` file is configured, run these commands in order:
```bash
# 1. Generate Certificate Authority and TLS certificates
make certs

# 2. Generate configuration files from templates
make render

# 3. Start all services
make up
```

#### 🎯 What Each Command Does:

- **`make certs`** → Creates a local Certificate Authority and generates TLS certificates for secure communication
- **`make render`** → Processes template files to create Nginx, DNS, and Keycloak configurations using your `.env` settings
- **`make up`** → Launches the entire Docker infrastructure

---

### ✅ Verification

After running `make up`, verify your deployment:
```bash
# Check if all containers are running
docker ps

# Access the services in your browser:
# - Registry: https://nmos-registry.easyebu.com
# - Keycloak: https://keycloak.easyebu.com
```

---

### 🛠️ Troubleshooting

| Issue | Solution |
|-------|----------|
| Permission denied errors | Re-run Step 2 to fix ownership |
| Port already in use | Change `PUBLIC_HTTP_PORT` or `PUBLIC_HTTPS_PORT` in `.env` |
| Cannot resolve hostnames | Ensure BIND_IP is reachable and DNS is configured |
| Network unreachable | Verify SUBNET, GATEWAY, and PARENT_IF match your network |

## ⚙️ Configuration Variable Reference

The `.env` file acts as the single source of truth for the entire lab. The variables below are categorized by their function to help you identify which settings must match your physical environment and which are logical choices.

### 1. Physical Network Configuration (Critical)
These variables **must** match the physical network your host machine is connected to. Because we use the `macvlan` driver, containers attach directly to your LAN like physical devices.



| Variable | Description | How to find it |
| :--- | :--- | :--- |
| `PARENT_IF` | The physical network interface on your host machine that connects to the LAN (e.g., `eth0`, `enp3s0`). | Run `ip addr` or `ifconfig` (Linux, Mac) to find the active interface. |
| `SUBNET` | The CIDR subnet of your physical network. | Usually `192.168.1.0/24`. Ensure this matches your router's setting. |
| `GATEWAY` | The IP address of your network router. | Usually `192.168.1.1`. |

### 2. Static IP Allocation
You must assign static IP addresses to each service. These IPs must be **inside** your `SUBNET` but **outside** your router's DHCP range (to avoid IP conflicts with other devices on your LAN).

| Variable | Description |
| :--- | :--- |
| `BIND_IP` | IP for the Bind9 DNS server. All other containers use this to discover `_nmos` services. |
| `PROXY_IP` | IP for the Nginx Reverse Proxy. This is the **primary** IP you connect to via HTTPS. |
| `REGISTRY_IP` | Dedicated IP for the Sony/NVIDIA NMOS Registry. |
| `NODE_IP` | Dedicated IP for the Virtual NMOS Node. |
| `KEYCLOAK_IP` | Dedicated IP for the Authorization Server. |
| `HOST_MACVLAN_IP` | A virtual IP assigned to the Host machine. This allows the Host to communicate with the containers, bridging the Macvlan isolation. |

### 3. Logical Identities & Discovery
These variables define how services identify themselves and discover each other via DNS-SD (IS-04).

| Variable | Description |
| :--- | :--- |
| `DOMAIN` | The local DNS domain suffix (e.g., `easyebu.com`). Services are accessible at `hostname.domain`. |
| `REGISTRY_HOST` | FQDN for the registry. Must match the Common Name (CN) in the SSL certificate. |
| `NODE_HOST` | FQDN for the virtual node. |
| `KEYCLOAK_HOST` | FQDN for the Keycloak server. |

### 4. Security & Application Secrets
These variables control the IS-10 Authorization behavior and database access.

| Variable | Description |
| :--- | :--- |
| `KEYCLOAK_REALM` | The logical workspace within Keycloak. The script imports configuration into this realm. |
| `POSTGRES_USER` | Username for the Keycloak database. |
| `POSTGRES_PASSWORD`| Password for the Keycloak database. |

## 🛡️ Operational Guide

For security critical behaviors, threat impact, and infrastructure risk assessment, see:

📌 **[Operational Guide & Risk Assessment](operational_guide.md)**