# GitOps-Driven Data Pipeline Platform on GCP

🚀 **Project Overview**: A complete GitOps solution using GKE Config Connector to manage cloud infrastructure as Kubernetes resources.

## 🎯 Problem Solved
- Manage Pub/Sub topics, Cloud Storage buckets, BigQuery datasets, and Cloud SQL instances
- Coordinate infrastructure across multiple environments (dev/staging/prod)
- Keep infrastructure definitions under Git with CI/CD pipelines
- Ensure RBAC isolation across teams
- Reduce manual gcloud CLI dependency and Terraform state drift

## 🔧 Tech Stack
- **GKE Autopilot** - Managed Kubernetes cluster
- **Config Connector** - Kubernetes CRDs for GCP resources
- **Argo CD** - GitOps continuous deployment
- **Google Cloud Services**: Pub/Sub, BigQuery, Cloud SQL, IAM, GCS
- **Workload Identity** - Secure service-to-service authentication

## 📁 Project Structure
```
infrastructure/
├── base/                   # Base resource templates
├── environments/           # Environment-specific configurations
│   ├── dev/
│   ├── staging/
│   └── prod/
├── argocd/                # Argo CD application definitions
├── scripts/               # Setup and automation scripts
├── docs/                  # Documentation
├── security-policies/     # OPA Gatekeeper policies
├── security-reports/      # Security assessments and dashboards
└── ci-cd-examples/        # CI/CD pipeline templates
```

## 🚀 Quick Start

### Prerequisites
- **GCP Project** with billing enabled
- **gcloud CLI** installed and authenticated (`gcloud auth login`)
- **kubectl** installed
- **make** utility (usually pre-installed on Linux/macOS)
- **Project permissions**: `roles/container.admin`, `roles/iam.serviceAccountAdmin`, `roles/resourcemanager.projectIamAdmin`

### First Time Setup (Fork Repository)
```bash
# 1. Fork this repository to your GitHub account
# 2. Clone your forked repository
git clone https://github.com/YOUR_USERNAME/gke-config-connector.git
cd gke-config-connector

# 3. Update repository URLs in configuration files
# Edit Makefile and change GITHUB_REPO to your forked repository URL
# Edit argocd/applications-enhanced.yaml and update repoURL fields

# 4. Configure environment variables
cp .env.example .env.local
# Edit .env.local with your GitHub credentials and repository URL
```

### One-Command Setup
```bash
# Set your project ID
export PROJECT_ID=your-gcp-project-id

# Complete platform setup (cluster + Config Connector + Argo CD)
make setup-all
```

### Manual Step-by-Step Setup
```bash
# 1. Check prerequisites and environment
make check-env

# 2. Create GKE Autopilot cluster
make setup-cluster

# 3. Install Config Connector
make install-config-connector

# 4. Install Argo CD
make install-argocd

# 5. Deploy infrastructure applications
make deploy-infrastructure
```

### Access Argo CD UI
```bash
# Start port-forward and get login credentials
make argocd-ui

# Access at: https://localhost:8080
# Username: admin
# Password: (displayed in terminal)
```

## 📋 Daily Operations

### Environment Management
```bash
# Check status of all applications
make status

# Sync specific environments
make sync-dev        # Auto-sync development
make sync-staging    # Manual sync staging
make sync-prod       # Manual sync production (with confirmation)

# Validate configurations before deployment
make validate-all    # Validate all environments
make validate-dev    # Validate development only
```

### Monitoring & Troubleshooting
```bash
# View application logs
make logs-config-connector    # Config Connector logs
make logs-argocd             # Argo CD logs

# Check resource status
make check-resources         # Count of Config Connector resources
make status                  # Argo CD application health

# Watch real-time status
make watch-apps              # Watch Argo CD applications
make watch-resources         # Watch Config Connector resources
```

### Development & Testing
```bash
# Open development shell in cluster
make dev-shell

# Test connectivity between components
make test-connectivity

# Security and compliance checks
make security-check

# Cost estimation
make cost-estimate

# CI/CD pipeline validation (safe for automation)
make dry-run              # Validate without applying changes
make ci-validate          # Full CI/CD validation pipeline
make security-policy-check # Validate OPA Gatekeeper policies
```

## 🔧 Customization Guide

### Adding New GCP Resources
1. **Create base resource** in `infrastructure/base/new-service.yaml`
2. **Add to kustomization** in `infrastructure/base/kustomization.yaml`
3. **Create environment patches** in each `environments/*/kustomization.yaml`
4. **Update IAM permissions** in `infrastructure/base/iam.yaml`
5. **Test and deploy**: `make validate-all && make sync-dev`

### Adding New Environments
1. **Create environment directory**: `infrastructure/environments/new-env/`
2. **Copy template files** from existing environment
3. **Customize** `kustomization.yaml` with environment-specific patches
4. **Create Argo CD application** in `argocd/applications.yaml`
5. **Update RBAC** in `argocd/project.yaml`

### Repository Configuration
1. **Fork or create repository** for your infrastructure code
2. **Update Git URLs** in `argocd/applications.yaml`:
   ```bash
   sed -i 's|https://github.com/your-org/data-platform-infrastructure|YOUR_REPO_URL|g' argocd/applications.yaml
   ```
3. **Commit and push** changes to trigger GitOps deployment

## 📊 Infrastructure Overview

### Created Resources

| Service | Resources | Purpose |
|---------|-----------|---------|
| **BigQuery** | 2 datasets, 2 tables | Data analytics with CMEK encryption |
| **Pub/Sub** | 3 topics, 2 subscriptions, 1 DLQ | Event streaming with encryption |
| **Cloud Storage** | 3 buckets | Data lake with lifecycle policies and CMEK |
| **Cloud SQL** | 1 PostgreSQL instance, 2 databases | Private, encrypted relational storage |
| **IAM** | 6 service accounts, 12 policy bindings | Secure access control with Workload Identity |
| **KMS** | 1 key ring, 5 encryption keys | Customer-managed encryption for all services |
| **VPC** | 1 network, 3 subnets, 5 firewall rules | Private networking with micro-segmentation |
| **Organization Policies** | 7 security policies | Enterprise security baseline enforcement |
| **Monitoring** | Security alerts, audit logs | Comprehensive security monitoring |

### Environment Differences

| Configuration | Dev | Staging | Production |
|---------------|-----|---------|------------|
| **BigQuery Retention** | 30 days | 60 days | 180 days |
| **Pub/Sub Retention** | 3 days | 5 days | 14 days |
| **SQL Instance** | 1 vCPU, 4GB | 2 vCPU, 7.5GB | 4 vCPU, 16GB |
| **SQL Availability** | Zonal | Zonal | Regional (HA) |
| **Storage Lifecycle** | 30 days | 180 days | 7 years |
| **Sync Policy** | Auto | Manual | Manual + Approval |

## 🛡️ Enterprise Security Features

### Core Security Controls
- **Organization Policies**: 7 enterprise-grade policies enforcing security baselines
- **VPC Security**: Private networking with firewall rules and secure subnet isolation
- **CMEK Encryption**: Customer-managed encryption keys for all data services
- **Workload Identity Federation**: Secure, keyless authentication with conditional access
- **Policy-as-Code**: OPA Gatekeeper for runtime policy enforcement
- **Security Monitoring**: Comprehensive audit logging and security alerting

### Data Classification & Protection
- **Data Classification Labels**: Confidential, Sensitive, Internal, Public classification system
- **DLP Integration**: Data Loss Prevention scanning for PII/PHI detection
- **Binary Authorization**: Container image security and supply chain verification
- **Security Command Center**: Centralized security findings and vulnerability management

### Compliance & Governance
- **Audit Logging**: Complete trail of all infrastructure and application changes
- **Retention Policies**: Automated data lifecycle management with compliance requirements
- **Access Controls**: Fine-grained RBAC with environment isolation
- **Encryption at Rest/Transit**: End-to-end encryption using Google-managed and customer keys

### Network Security
- **Private Cluster**: GKE nodes without public IPs
- **Authorized Networks**: Restricted API server access
- **VPC Firewall Rules**: Micro-segmentation and traffic controls
- **Private Service Connect**: Secure connectivity to Google APIs

### Identity & Access Management
- **Least Privilege IAM**: Role-based access with minimal required permissions
- **Service Account Hardening**: Workload Identity without downloadable keys
- **Conditional Access**: Location and device-based access controls
- **Regular Access Reviews**: Automated IAM policy auditing and cleanup

## � Cleanup & Management

### Environment Cleanup
```bash
# Clean up specific environments
make cleanup-dev        # Remove dev resources
make cleanup-staging    # Remove staging resources
make cleanup-prod       # Remove prod resources (requires confirmation)

# Complete cluster removal
make cleanup-cluster    # Delete entire GKE cluster (requires confirmation)
```

### Backup & Recovery
```bash
# Backup production data
make backup-prod

# Restore from backup (implement based on your requirements)
make restore-prod
```

## 🔍 Troubleshooting

### Common Issues

1. **Config Connector not ready**
   ```bash
   make logs-config-connector
   kubectl get pods -n cnrm-system
   ```

2. **Permission errors**
   ```bash
   # Check service account permissions
   gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --filter="bindings.members:cnrm-controller-manager@$PROJECT_ID.iam.gserviceaccount.com"
   ```

3. **Argo CD sync failures**
   ```bash
   make status
   make logs-argocd
   ```

4. **Resource creation failures**
   ```bash
   kubectl describe <resource-type> <resource-name> -n <namespace>
   ```

### Getting Help
- Check the [Setup Guide](docs/setup.md) for detailed instructions
- Review [Security Best Practices](docs/security.md) for security configuration
- See [Adding Resources Guide](docs/adding-resources.md) for extending the platform

## 📚 Documentation
- **[Setup Guide](docs/setup.md)** - Detailed setup instructions and troubleshooting
- **[Adding New Resources](docs/adding-resources.md)** - How to extend the platform with new GCP services
- **[Security Architecture](docs/security-architecture.md)** - USC enterprise security design and compliance
- **[Development Log](devlog.md)** - Project development methodology and decisions
- **[CI/CD Pipeline Examples](ci-cd-examples/pipeline-examples.md)** - GitHub Actions, GitLab CI, Jenkins workflows
- **[OPA Gatekeeper Policies](security-policies/opa-gatekeeper-policies.rego)** - Custom runtime security controls
- **[Security Command Center Report](security-reports/security-command-center-example.md)** - Example vulnerability assessment
- **[Security Posture Dashboard](security-reports/security-posture-dashboard.md)** - Visual security monitoring overview

## 🎯 Use Cases

This platform is ideal for:
- **Data Engineering Teams** managing multi-environment data pipelines
- **Platform Teams** providing self-service infrastructure to development teams
- **DevOps Teams** implementing GitOps workflows for cloud infrastructure
- **Organizations** requiring compliance, audit trails, and security controls
- **Startups to Enterprise** needing scalable infrastructure management
- **Security Teams** implementing policy-as-code and runtime security controls
- **Compliance Officers** managing regulatory requirements (SOC 2, NIST, ISO 27001)
- **University IT Departments** meeting USC-level enterprise security standards

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/new-resource`
3. **Make changes** to infrastructure templates or documentation
4. **Test changes**: `make validate-all`
5. **Submit pull request** with clear description of changes
6. **Changes automatically deploy** via GitOps pipeline after merge

## 📄 License

This project is open source. See [LICENSE](LICENSE) for details.

## 🆘 Support

For questions or issues:
- Create an issue in the repository
- Check the **[Known Issues](docs/known-issues.md)** document for GKE Autopilot limitations
- Check the troubleshooting section in documentation
- Review the development log for implementation details
