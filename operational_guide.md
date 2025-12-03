# Operational Best Practices & Risk Assessment Guide

> **Purpose:** This document explains how to **manage and secure** your NMOS IS-10 lab deployment. While the README shows you how to build the system, this guide helps you understand the security implications, operational risks, and best practices for running it safely.

## 📚 Background: What Are We Securing?

Before diving into configurations, let's understand what this system does:

### SMPTE ST 2110 & NMOS Overview
**SMPTE ST 2110** is a standard that allows professional broadcast equipment (cameras, audio mixers, video switchers) to communicate over IP networks instead of traditional SDI cables. Think of it as replacing physical video cables with network connections.

**NMOS (Networked Media Open Specifications)** provides the control layer for ST 2110:
- **IS-04:** Device discovery and registration (like a phone book for broadcast equipment)
- **IS-05:** Device connection management (how devices connect to each other)
- **IS-10:** Security authorization (who is allowed to control which devices)

**Why Security Matters:** In a broadcast facility, unauthorized access could allow someone to:
- Hijack live broadcast feeds
- Inject false content into productions
- Disable critical equipment during live events
- Steal proprietary content before release

---

## 📑 Table of Contents
1. [Key Security Concepts](#-key-security-concepts-explained)
2. [Level 1: Critical Infrastructure](#-level-1-critical-infrastructure-high-importance)
3. [Level 2: Network & Transport](#-level-2-network--transport-medium-importance)
4. [Level 3: Deployment & Support](#ℹ️-level-3-deployment--support-low-importance)
5. [Common Attack Scenarios](#-common-attack-scenarios--mitigations)
6. [Troubleshooting Guide](#-troubleshooting-guide)
7. [Production Deployment Checklist](#-production-deployment-checklist)

---

## 🔑 Key Security Concepts Explained

### Essential Terms for This Project

| Term | What It Means | Why It Matters |
|------|---------------|----------------|
| **JWT (JSON Web Token)** | A digital "pass" that proves who you are | Like a backstage pass at a concert - if someone steals it, they can access restricted areas |
| **PKI (Public Key Infrastructure)** | System for creating and managing digital certificates | Like a passport office - it issues trusted IDs that others can verify |
| **TLS/SSL Certificate** | Digital ID card for servers | Ensures you're talking to the real server, not an imposter |
| **Backdoor** | Hidden access method that bypasses normal security | Like a secret entrance that lets someone into your system without proper credentials |
| **Man-in-the-Middle (MitM)** | Attack where someone secretly intercepts communications | Like someone listening to your phone calls by tapping the line |
| **CA (Certificate Authority)** | Entity that issues digital certificates | Like a government office that issues driver's licenses |
| **FQDN (Fully Qualified Domain Name)** | Complete address of a server (e.g., nmos-registry.lab.com) | Like a complete mailing address vs. just a house number |
| **Realm (in Keycloak)** | Isolated space for users and permissions | Like separate buildings in a campus - each has its own security |

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
KEYCLOAK_ADMIN_PASSWORD=$(openssl rand -base64 32)

# 2. Store passwords in a secure vault, never in plain text
# Use tools like HashiCorp Vault, AWS Secrets Manager, or Azure Key Vault

# 3. Enable audit logging
docker exec keycloak /opt/keycloak/bin/kcadm.sh update events/config \
  -s eventsEnabled=true \
  -s adminEventsEnabled=true
```

**Network Isolation:**
- Place Keycloak admin interface on a separate management VLAN
- Use firewall rules to restrict access:
```bash
# Example: Only allow admin access from management network
iptables -A INPUT -p tcp --dport 8443 -s 10.0.100.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 8443 -j DROP
```

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

#### 🛡️ Security Best Practices

**Prevent Rogue Devices:**
```bash
# Configure Registry to require authentication
export REGISTRY_AUTH_MODE=oauth2
export REGISTRY_OAUTH_ISSUER=https://keycloak.lab.com/realms/nmos

# Implement device allowlisting
export REGISTRY_DEVICE_ALLOWLIST=/config/approved_devices.json
```

**High Availability Setup:**
```yaml
# docker-compose.yml excerpt for clustered registry
services:
  registry-1:
    image: nmos-cpp:latest
    environment:
      - REGISTRY_CLUSTER_MODE=true
      - REGISTRY_PEERS=registry-2,registry-3
  
  registry-2:
    # ... similar configuration
  
  registry-3:
    # ... similar configuration
```

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

**Secure Certificate Storage:**
```bash
# 1. Protect the CA private key
chmod 400 nginx/certs/ca.key
chown root:root nginx/certs/ca.key

# 2. Store CA key offline after certificate generation
# Move to hardware security module (HSM) or encrypted USB
mv nginx/certs/ca.key /secure-offline-storage/

# 3. Monitor certificate expiration
cat > /etc/cron.d/cert-monitor << EOF
0 9 * * 1 /usr/local/bin/check-cert-expiry.sh
EOF
```

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

#### DNS Poisoning Attack Scenario
```
Normal Flow:
Device asks: "Where is nmos-registry.lab.com?"
DNS responds: "192.168.1.52" ✅

Attack Flow:
Attacker intercepts DNS
Device asks: "Where is nmos-registry.lab.com?"
Attacker responds: "192.168.1.100" (malicious server) ❌
Device connects to fake registry
```

#### 🛡️ Security Best Practices

**DNS Security Configuration:**
```bash
# Enable DNSSEC for authentication
dnssec-enable yes;
dnssec-validation yes;

# Restrict zone transfers
allow-transfer { none; };

# Rate limiting
rate-limit {
    responses-per-second 10;
    errors-per-second 5;
};
```

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

#### 🛡️ Security Best Practices

**Network Planning:**
```bash
# 1. Reserve IP ranges in DHCP server
# Example for ISC DHCP:
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;  # DHCP range
    # .50-.99 reserved for NMOS static IPs
}

# 2. Document IP allocations
cat > /etc/nmos/ip-allocations.txt << EOF
192.168.1.50  - DNS Server (Bind9)
192.168.1.51  - Reverse Proxy (Nginx)
192.168.1.52  - NMOS Registry
192.168.1.53  - NMOS Node
192.168.1.54  - Keycloak Auth
192.168.1.55  - PostgreSQL Database
192.168.1.60  - Host Bridge
192.168.1.61-99 - Reserved for expansion
EOF

# 3. Monitor for conflicts
arp-scan --local | grep -i "dup"
```

---

## ℹ️ Level 3: Deployment & Support (Low Importance)

> **Impact Level:** Maintenance difficulties, version conflicts, or documentation issues

These settings affect long-term maintainability rather than immediate functionality.

### Configuration Variables and Risks

| Variable | Purpose | What Happens If Misconfigured | Real-World Impact |
|----------|---------|------------------------------|-------------------|
| `PROJECT_NAME` | Container naming prefix | **✅ MINIMAL:** Cosmetic only | • Container names change<br>• No functional impact |
| `*_IMAGE` versions | Software versions | **⚠️ MEDIUM:** Compatibility issues | • Unexpected behavior after updates<br>• Database schema mismatches<br>• API breaking changes |

### Understanding Version Pinning

**Bad Practice - Using 'latest':**
```yaml
services:
  registry:
    image: nmos-cpp:latest  # ❌ Dangerous
    # Monday: Gets v1.0.0
    # Tuesday: Auto-updates to v2.0.0
    # Wednesday: Breaking changes cause outage
```

**Good Practice - Pinned Versions:**
```yaml
services:
  registry:
    image: nmos-cpp:v1.2.3  # ✅ Predictable
    # Always gets exact same version
    # Updates are intentional and tested
```

### 🛡️ Best Practices

**Version Management Strategy:**
```bash
# 1. Document all versions in use
cat > VERSION_MANIFEST.txt << EOF
Component     | Current Version | Tested With
--------------|-----------------|-------------
NMOS Registry | v1.2.3         | IS-04 v1.3
NMOS Node     | v1.2.3         | IS-05 v1.1
Keycloak      | 22.0.1         | OIDC 1.0
PostgreSQL    | 15.3           | -
Nginx         | 1.24.0         | -
Bind9         | 9.18.12        | -
EOF

# 2. Test updates in staging
docker-compose -f docker-compose.staging.yml up -d

# 3. Maintain rollback plan
docker tag nmos-cpp:v1.2.3 nmos-cpp:v1.2.3-backup
```

---

## 🚫 Common Attack Scenarios & Mitigations

### Scenario 1: Unauthorized Operator Access
**Attack:** Disgruntled employee tries to disrupt live broadcast
```
1. Attacker knows operator credentials
2. Logs into NMOS Controller
3. Reroutes camera feeds during live event
4. Causes broadcast interruption
```

**Mitigation:**
- Implement role-based access control (RBAC)
- Use time-limited sessions
- Enable audit logging
- Require 2FA for production changes

### Scenario 2: Rogue Device Injection
**Attack:** Attacker connects unauthorized device to network
```
1. Attacker brings laptop with NMOS node software
2. Device auto-registers with Registry
3. Advertises as legitimate source (e.g., "Camera_01")
4. Production accidentally uses fake source
```

**Mitigation:**
- Enable IS-10 authorization
- Implement device allowlisting
- Monitor for unknown devices
- Use network access control (NAC/802.1X)

### Scenario 3: Man-in-the-Middle Attack
**Attack:** Attacker intercepts control commands
```
1. Attacker compromises network position
2. Intercepts NMOS control traffic
3. Modifies commands in transit
4. Changes routing without authorization
```

**Mitigation:**
- Enforce TLS for all communications
- Implement certificate pinning
- Use network segmentation
- Deploy intrusion detection systems (IDS)

### Scenario 4: Certificate Expiration During Live Event
**Attack:** Not malicious, but devastating timing
```
1. Certificates expire during major broadcast
2. All secure connections fail instantly
3. Devices can't authenticate
4. Complete system failure during critical moment
```

**Mitigation:**
- Monitor expiration dates (90, 60, 30, 7 days warning)
- Maintain hot-standby certificates
- Practice certificate rotation procedures
- Keep emergency bypass procedures

---

## 🔧 Troubleshooting Guide

### Quick Diagnosis Table

| Symptom | Check These First | Common Solutions |
|---------|------------------|------------------|
| **"Cannot login to Registry"** | 1. Keycloak status<br>2. DNS resolution<br>3. Certificate validity | • `docker logs keycloak`<br>• `nslookup keycloak.lab.com`<br>• `openssl s_client -connect keycloak.lab.com:443` |
| **"Node not discovered"** | 1. Registry reachability<br>2. Authentication token<br>3. Network connectivity | • `curl https://registry.lab.com/x-nmos/registration/v1.3/health`<br>• Check JWT expiration<br>• `ping registry.lab.com` |
| **"Certificate errors"** | 1. Certificate expiration<br>2. Hostname mismatch<br>3. CA trust | • `openssl x509 -in cert.pem -text -noout`<br>• Verify CN matches FQDN<br>• Check ca.crt is distributed |
| **"Intermittent failures"** | 1. IP conflicts<br>2. DNS cache<br>3. Network congestion | • `arp -a | grep duplicate`<br>• `systemctl restart systemd-resolved`<br>• Check bandwidth utilization |
| **"Permission denied"** | 1. File ownership<br>2. OAuth2 scopes<br>3. RBAC policies | • `ls -la` check ownership<br>• Verify token scopes<br>• Review Keycloak roles |

### Diagnostic Commands Toolbox
```bash
# Network Diagnostics
docker exec nmos-node ping -c 4 nmos-registry
docker exec nmos-node nslookup nmos-registry.lab.com
docker exec nginx curl -k https://localhost/health

# Certificate Validation
openssl x509 -in nginx/certs/registry.crt -text -noout | grep -E "Subject:|Not After"
openssl verify -CAfile nginx/certs/ca.crt nginx/certs/registry.crt

# Authentication Testing
curl -X POST https://keycloak.lab.com/realms/nmos/protocol/openid-connect/token \
  -d "client_id=nmos-registry" \
  -d "client_secret=$SECRET" \
  -d "grant_type=client_credentials"

# Container Health
docker-compose ps
docker stats --no-stream
docker logs --tail 50 -f keycloak

# System Resources
df -h
free -m
netstat -tulpn | grep -E ":(80|443|5432|8080)"
```

---

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

### Post-Deployment (Operations Phase)

- [ ] **Monitoring Setup**
  - [ ] Certificate expiration monitoring
  - [ ] Service health checks
  - [ ] Log aggregation configured
  - [ ] Alert notifications enabled

- [ ] **Documentation**
  - [ ] Network diagram created
  - [ ] Runbook procedures written
  - [ ] Emergency contacts listed
  - [ ] Change log maintained

- [ ] **Regular Maintenance**
  - [ ] Weekly: Review audit logs
  - [ ] Monthly: Rotate secrets
  - [ ] Quarterly: Security audit
  - [ ] Annually: Disaster recovery test

### Emergency Procedures

**In Case of Security Breach:**
1. Isolate affected systems
2. Revoke all authentication tokens
3. Rotate all secrets and certificates
4. Review audit logs for impact assessment
5. Implement additional monitoring
6. Document lessons learned

**In Case of Certificate Expiration:**
1. Use pre-generated backup certificates
2. Restart affected services
3. Verify all connections restored
4. Investigate why monitoring failed
5. Update rotation schedule

---

## 📚 Additional Resources

### Official Documentation
- [NMOS IS-04 Registration & Discovery](https://specs.amwa.tv/is-04/)
- [NMOS IS-10 Authorization](https://specs.amwa.tv/is-10/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [SMPTE ST 2110 Standards](https://www.smpte.org/standards)

### Security Tools
- [testssl.sh](https://testssl.sh/) - TLS/SSL tester
- [OWASP ZAP](https://www.zaproxy.org/) - Security scanner
- [Fail2ban](https://www.fail2ban.org/) - Intrusion prevention

### Monitoring Solutions
- [Prometheus](https://prometheus.io/) + [Grafana](https://grafana.com/) - Metrics
- [ELK Stack](https://www.elastic.co/elk-stack) - Log analysis
- [Nagios](https://www.nagios.org/) - Infrastructure monitoring

---

## 🤝 Contributing

This is an open-source project. If you identify security improvements or best practices, please:

1. Fork the repository
2. Create a feature branch
3. Document your changes thoroughly
4. Submit a pull request with clear explanation

For security vulnerabilities, please report privately to avoid public disclosure before patches are available.

---

**Last Updated:** December 2024  
**Maintainers:** NMOS Lab Team  
**License:** Apache 2.0