# GitOps Data Platform - Project Structure

This document describes the clean, production-ready structure of the GitOps Data Platform.

## 📁 **Directory Structure**

```
gke-config-connector/                 # ✅ PRODUCTION-READY GitOps Platform
├── README.md                         # 📘 Getting Started, Use Cases, CI hints
├── PROJECT_STRUCTURE.md              # 📂 Folder-by-folder walkthrough
├── LICENSE                           # ✅ MIT License
├── Makefile                          # ⚙️  Task automation: bootstrap, audit, cleanup
│
├── docs/                             # 🧠 Design & How-Tos
│   ├── setup.md                      # ⚙️  Cluster setup & pre-reqs
│   ├── security-architecture.md      # 🔐 Zero Trust, IAM, CMEK
│   ├── adding-resources.md           # ➕ KCC expansion via kpt/kustomize
│   └── known-issues.md               # 🐞 Autopilot & KCC gotchas + fixes
│
├── infrastructure/                   # 🏗️  KCC Resource Definitions (Validated)
│   ├── base/                         # 🔧 VPC, IAM, CloudSQL, BQ, PubSub, GCS...
│   └── environments/                 # 🧪 Isolated overlays: dev/staging/prod
│       ├── dev/
│       ├── staging/
│       └── prod/
│
├── scripts/                          # 🚀 One-line setup with progress logs
│   ├── setup-cluster.sh              # [1/6] Bootstrap Autopilot + tooling
│   ├── install-config-connector.sh   # [1/4] Connect GCP → K8s
│   ├── install-argocd.sh             # [1/4] GitOps engine
│   ├── install-gatekeeper.sh         # [1/7] OPA policy engine
│   └── cleanup-orphaned-resources.sh # [1/24] GCP resource hygiene
│
├── argocd/                           # 📦 ArgoCD apps, projects, sync policies
├── security-policies/               # 🛡️  OPA/Gatekeeper Rego + constraints
├── monitoring/                       # 📈 Stackdriver/Monitoring setup
├── sample-app/                       # 🧪 Reference workloads: data-ingester/processor
└── samples/                          # 📁 Raw Config Connector samples (optional)
```

## 🏗️ **Architecture Overview**

### **Core Components**
- **GKE Autopilot Cluster**: Hardened, managed Kubernetes
- **Config Connector**: Infrastructure as Code via Kubernetes
- **ArgoCD**: GitOps continuous deployment
- **Security Policies**: OPA Gatekeeper + Pod Security Standards

### **Infrastructure Environments**
- **Development**: `infrastructure/environments/dev/`
- **Staging**: `infrastructure/environments/staging/`
- **Production**: `infrastructure/environments/prod/`

### **Key Features**
- ✅ **Progress Indicators**: All scripts show [X/Y] progress
- ✅ **Environment Isolation**: Separate namespaces and resources
- ✅ **Security Hardening**: Multiple layers of security controls
- ✅ **GitOps Workflow**: Declarative infrastructure management
- ✅ **Comprehensive Cleanup**: Proper resource lifecycle management

## 🚀 **Quick Start**

```bash
# 1. Setup everything
make setup-all

# 2. Deploy infrastructure
make deploy-infrastructure

# 3. Access ArgoCD
make argocd-ui

# 4. Clean up (when needed)
make cleanup-everything
```

## 📚 **Documentation Hierarchy**

1. **README.md** - Start here for overview and quick setup
2. **docs/setup.md** - Detailed setup instructions
3. **docs/security-architecture.md** - Security design and implementation
4. **docs/known-issues.md** - Current limitations and workarounds
5. **docs/adding-resources.md** - Guide for extending the platform

## 🔧 **Automation Features**

All automation scripts include:
- **Progress tracking** with [X/Y] indicators
- **Error handling** with clear messages
- **Idempotent operations** (safe to re-run)
- **Environment validation** before execution
- **Comprehensive logging** for debugging

---

**Status**: ✅ **PRODUCTION READY**  
**Last Updated**: August 1, 2025  
**Version**: v1.0.0
