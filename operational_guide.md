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