# Operational Best Practices & Risk Assessment Guide

> **Purpose:** This document explains how to **manage and secure** your NMOS IS-10 lab deployment. While the README shows you how to build the system, this guide helps you understand the security implications, operational risks, and best practices for running it safely.

## 📚 Background: What Are We Securing?

Before diving into configurations, let's understand what this system does:

### SMPTE ST 2110 & NMOS Overview
**SMPTE ST 2110** is a standard that allows professional broadcast equipment (cameras, audio mixers, video switchers) to communicate over IP networks instead of traditional SDI cables.

**NMOS (Networked Media Open Specifications)** provides the control layer for ST 2110:
- **IS-04:** Device discovery and registration (like a phone book for broadcast equipment)
- **IS-05:** Device connection management (how devices connect to each other)
- **IS-10:** Security authorization (who is allowed to control which devices)

**Why Security Matters:** In a broadcast facility, unauthorized access could allow someone to:
- Hijack live broadcast feeds
- Inject false content into productions
- Disable critical equipment during live events
- Steal proprietary content before release


## 🔑 Key Security Concepts Explained

### Essential Terms for This Project

| Term | What It Means | 
|------|---------------|
| **JWT (JSON Web Token)** | A digital "pass" that proves who you are | 
| **PKI (Public Key Infrastructure)** | System for creating and managing digital certificates |
| **TLS/SSL Certificate** | Digital ID card for servers |
| **Backdoor** | Hidden access method that bypasses normal security |
| **Man-in-the-Middle (MitM)** | Attack where someone secretly intercepts communications |
| **CA (Certificate Authority)** | Entity that issues digital certificates |
| **FQDN (Fully Qualified Domain Name)** | Complete address of a server (e.g., nmos-registry.lab.com) |
| **Realm (in Keycloak)** | Isolated space for users and permissions |

---

## 🚨 Level 1: Critical Infrastructure (High Importance)

> **Impact Level:** System-wide failure or complete security breach if misconfigured

These components are the foundation of your secure NMOS system. Think of them as the locks, alarms, and security cameras of your broadcast facility.

### 1. Identity & Authorization (Keycloak) - The Security Guard

**What It Does:** Keycloak acts as the security guard at the entrance, checking everyone's ID and issuing temporary passes (JWTs) that allow access to specific areas (NMOS devices).

#### Configuration Variables and Risks

| Variable | Purpose | What Happens If Misconfigured | Real-World Impact |
|----------|---------|------------------------------|-------------------|
| `KEYCLOAK_ADMIN` | Master administrator username | **🔴 CRITICAL:** If leaked, attacker gains "master key" access | • Can create fake admin accounts ("backdoors")<br>• Can delete all user accounts<br>• Can disable security entirely<br>• Like giving someone the master key to every room |
| `KEYCLOAK_ADMIN_PASSWORD` | Master admin password | **🔴 CRITICAL:** Complete system compromise | • Full control over who can access your broadcast equipment<br>• Could lock out legitimate operators during live events |
| `KEYCLOAK_REALM` | Logical grouping of users/permissions | **⚠️ HIGH:** All devices lose access if changed | • Like changing all the locks without telling anyone<br>• Every device must be reconfigured manually |
| `POSTGRES_PASSWORD` | Database password storing all auth data | **🔴 CRITICAL:** Database breach | • Attacker can steal session tokens<br>• Can see who accessed what and when<br>• Can impersonate any user |

#### What is a "Backdoor" in This Context?
A **backdoor** here means creating unauthorized admin accounts that persist even after the breach is discovered. For example:
1. Attacker gains admin access
2. Creates a new admin user called "systemservice" (looks legitimate)
3. Even if you change the main admin password, the backdoor account remains
4. Attacker maintains access indefinitely

#### 🛡️ Security Best Practices

**Immediate Actions:**
```bash
# 1. Change default passwords immediately after deployment
KEYCLOAK_ADMIN_PASSWORD=Strong Password
# 2. Store passwords in a secure vault, never in plain text
# 3. Enable audit logging

```

**Network Isolation:**
- Place Keycloak admin interface on a separate management VLAN
- Use firewall rules to restrict access:


**Regular Maintenance:**
- Rotate client secrets monthly
- Review admin access logs weekly
- Conduct security audits quarterly

### 2. The NMOS Registry (IS-04) - The Directory Service

**What It Does:** The Registry is like a phone book for all your broadcast equipment. Every camera, microphone, and switcher registers here so other devices can find them.

#### Configuration Variables and Risks

| Variable | Purpose | What Happens If Misconfigured | Real-World Impact |
|----------|---------|------------------------------|-------------------|
| `REGISTRY_HOST` | The registry's network address | **⚠️ HIGH:** SSL certificate mismatch | • Devices refuse to connect<br>• "Certificate error" prevents registration<br>• Like having the wrong address on your business card |
| `REGISTRY_IP` | Static IP address | **🔴 CRITICAL:** Complete discovery failure | • No device can register<br>• Existing devices can't find each other<br>• Production stops |

#### Attack Scenario: Rogue Node Registration
Without IS-10 security:
1. Attacker connects unauthorized device to network
2. Device registers as "Camera_01" (legitimate name)
3. Production switches to fake camera feed
4. Attacker injects inappropriate content into live broadcast


### 3. Public Key Infrastructure (PKI) - The Trust Foundation

**What It Does:** PKI creates and manages digital certificates that prove servers are who they claim to be, preventing impersonation attacks.

#### Understanding Certificate Risks

| Component | Purpose | Risk if Compromised | Real-World Impact |
|-----------|---------|-------------------|-------------------|
| `ca.key` (CA Private Key) | Signs all certificates | **🔴 CRITICAL:** Total trust breach | • Attacker can create valid certificates for ANY server<br>• Can decrypt all "secure" communications<br>• Like having a machine that prints valid passports |
| `ca.crt` (CA Certificate) | Public trust anchor | **⚠️ MEDIUM:** Must redistribute to all devices | • Not secret, but if lost, must reconfigure every device |
| Server Certificates | Identify specific services | **⚠️ HIGH:** Service impersonation | • Attacker can pretend to be your Registry or Keycloak |

#### Certificate Expiration Timeline
```
Day 0    -----> Day 825 (Default) -----> SYSTEM FAILURE
         |                        |
         Certificate Created      Certificate Expires
                                  ↓
                          All HTTPS connections fail
                          No device can authenticate
                          Complete production outage
```

#### 🛡️ Security Best Practices


**Certificate Rotation Process:**
```bash
# 90 days before expiration:
1. Generate new certificates with existing CA
2. Deploy to staging environment
3. Test all service connections
4. Schedule maintenance window
5. Deploy to production with rollback plan
```

---

## ⚠️ Level 2: Network & Transport (Medium Importance)

> **Impact Level:** Connectivity issues, performance degradation, or partial outages

These components manage how traffic flows through your system. Think of them as the roads and traffic signals of your broadcast network.

### 1. Reverse Proxy (Nginx) - The Security Checkpoint

**What It Does:** Nginx acts as a security checkpoint, inspecting all incoming traffic, encrypting communications, and routing requests to the correct internal service.

#### Configuration Variables and Risks

| Variable | Purpose | What Happens If Misconfigured | Real-World Impact |
|----------|---------|------------------------------|-------------------|
| `PROXY_IP` | Entry point for all traffic | **⚠️ MEDIUM:** Routing failures | • Devices can resolve names but can't connect<br>• Intermittent timeout errors<br>• Like having the wrong building number |
| `PUBLIC_HTTPS_PORT` | Listening port (standard: 443) | **⚠️ LOW:** Configuration complexity | • Every device needs manual configuration<br>• Increases setup errors<br>• Non-standard ports often blocked by firewalls |

#### Understanding TLS Security Levels
```
TLS 1.0/1.1 ❌ INSECURE - Known vulnerabilities, deprecated
    ↓
TLS 1.2 ✅ SECURE - Minimum acceptable version
    ↓
TLS 1.3 ✅ PREFERRED - Best security and performance
```

#### 🛡️ Security Best Practices

**Nginx Security Hardening:**
```nginx
# nginx.conf security additions
server {
    # Force modern TLS only
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    
    # Rate limiting to prevent abuse
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req zone=api burst=20 nodelay;
    
    # Request size limits
    client_max_body_size 10M;
    client_body_buffer_size 128k;
}
```

### 2. DNS Server (Bind9) - The Address Book

**What It Does:** DNS translates human-readable names (nmos-registry.lab.com) into IP addresses that computers understand.

#### Configuration Variables and Risks

| Variable | Purpose | What Happens If Misconfigured | Real-World Impact |
|----------|---------|------------------------------|-------------------|
| `BIND_IP` | DNS server address | **⚠️ HIGH:** Complete name resolution failure | • No device can find any service<br>• Must use IP addresses directly<br>• Like removing all street signs |
| `DOMAIN` | Your lab domain | **⚠️ MEDIUM:** Certificate mismatch | • SSL errors if doesn't match certificates<br>• Devices may refuse connections |



### 3. Network Configuration (Macvlan) - The Network Bridge

**What It Does:** Macvlan allows Docker containers to appear as physical devices on your network, each with its own IP address.

#### Configuration Variables and Risks

| Variable | Purpose | What Happens If Misconfigured | Real-World Impact |
|----------|---------|------------------------------|-------------------|
| `PARENT_IF` | Physical network interface | **🔴 CRITICAL:** Complete network isolation | • Containers can't communicate at all<br>• System appears offline<br>• Like unplugging the network cable |
| `SUBNET`/`GATEWAY` | Network addressing | **⚠️ HIGH:** Routing failures | • Can't reach other VLANs<br>• Internet access may fail<br>• Cross-subnet communication broken |
| Static IPs | Container addresses | **⚠️ HIGH:** IP conflicts | • Random failures as IPs collide<br>• Services become intermittently unreachable |

#### Understanding IP Conflicts
```
Scenario: DHCP Range overlaps with static IPs

Time 0: Registry starts at 192.168.1.52 ✅
Time 1: Laptop joins network, DHCP assigns 192.168.1.52 ❌
Result: IP CONFLICT - Registry becomes unreachable
        Random packet loss
        Intermittent failures
```

## ✅ Production Deployment Checklist

### Pre-Deployment (Planning Phase)

- [ ] **Network Planning**
  - [ ] IP address allocation documented
  - [ ] DHCP exclusions configured
  - [ ] VLANs designed and configured
  - [ ] Firewall rules defined

- [ ] **Security Planning**
  - [ ] Password policy defined
  - [ ] Certificate rotation schedule created
  - [ ] Backup strategy documented
  - [ ] Incident response plan prepared

- [ ] **Capacity Planning**
  - [ ] Expected device count estimated
  - [ ] Network bandwidth calculated
  - [ ] Storage requirements determined
  - [ ] Redundancy requirements identified

### Deployment Phase

- [ ] **Initial Security**
  - [ ] Change ALL default passwords
  - [ ] Generate production certificates
  - [ ] Configure firewall rules
  - [ ] Enable audit logging

- [ ] **Service Configuration**
  - [ ] Configure Keycloak realm and clients
  - [ ] Set up Registry with authentication
  - [ ] Deploy Nginx with TLS 1.2+ only
  - [ ] Configure DNS with DNSSEC

- [ ] **Testing**
  - [ ] Verify all services are running
  - [ ] Test device registration flow
  - [ ] Confirm authentication works
  - [ ] Validate certificate chain




## 📚 Additional Resources

### Official Documentation
- [NMOS IS-04 Registration & Discovery](https://specs.amwa.tv/is-04/)
- [NMOS IS-10 Authorization](https://specs.amwa.tv/is-10/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [SMPTE ST 2110 Standards](https://www.smpte.org/standards)
- [BIND9 AMWA](https://specs.amwa.tv/info-004/branches/main/docs/Example_HOWTO.html)
- [NGINX Documentation](https://nginx.org/en/docs/index.html)
- [Code for NMOS Registry and Node](https://github.com/sony/nmos-cpp/)
---

## 🤝 Contributing

This is an ongoing project meant for training purposes and it is not production ready. If you identify security improvements or best practices, please report privately to avoid public disclosure before patches are available.

---

**Last Updated:** December 2025