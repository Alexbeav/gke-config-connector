# Setup Guide

This guide walks you through setting up the GitOps-driven data pipeline platform on GCP.

## Prerequisites

### Required Tools
- `gcloud` CLI installed and authenticated
- `kubectl` installed 
- `git` for version control
- Access to a GCP project with billing enabled

### Required Permissions
Your user account needs the following IAM roles:
- `roles/container.admin` - For GKE cluster management
- `roles/iam.serviceAccountAdmin` - For service account creation
- `roles/resourcemanager.projectIamAdmin` - For IAM policy management
- `roles/serviceusage.serviceUsageAdmin` - For enabling APIs

## Step 1: Project Setup

1. **Set your project ID**:
   ```bash
   export PROJECT_ID=your-gcp-project-id
   gcloud config set project $PROJECT_ID
   ```

2. **Enable required APIs**:
   ```bash
   gcloud services enable \
     container.googleapis.com \
     pubsub.googleapis.com \
     bigquery.googleapis.com \
     storage.googleapis.com \
     sqladmin.googleapis.com \
     iam.googleapis.com \
     cloudresourcemanager.googleapis.com
   ```

## Step 2: Create GKE Cluster

Run the cluster setup script:
```bash
chmod +x scripts/setup-cluster.sh
./scripts/setup-cluster.sh
```

This script will:
- Create a GKE Autopilot cluster
- Enable Workload Identity
- Create necessary namespaces

## Step 3: Install Config Connector

Install and configure Config Connector:
```bash
chmod +x scripts/install-config-connector.sh
./scripts/install-config-connector.sh
```

This script will:
- Install Config Connector operator
- Create service accounts with necessary permissions
- Configure Workload Identity binding
- Set up ConfigConnectorContext for each environment

## Step 4: Install Argo CD

Install Argo CD for GitOps:
```bash
chmod +x scripts/install-argocd.sh
./scripts/install-argocd.sh
```

This script will:
- Install Argo CD in the cluster
- Expose the Argo CD server
- Provide access credentials

## Step 5: Configure Git Repository

1. **Fork or create a repository** for your infrastructure code
2. **Update Argo CD applications** to point to your repository:
   ```bash
   # Edit argocd/applications.yaml
   sed -i 's|https://github.com/your-org/data-platform-infrastructure|YOUR_REPO_URL|g' argocd/applications.yaml
   ```

3. **Commit and push** your infrastructure code to the repository

## Step 6: Deploy Infrastructure

1. **Create Argo CD project and applications**:
   ```bash
   kubectl apply -f argocd/project.yaml
   kubectl apply -f argocd/applications.yaml
   ```

2. **Access Argo CD UI**:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
   Open https://localhost:8080 and login with the credentials from step 4.

3. **Sync applications** in the Argo CD UI or via CLI:
   ```bash
   # Install Argo CD CLI first
   argocd app sync dev-infrastructure
   argocd app sync staging-infrastructure
   argocd app sync prod-infrastructure
   ```

## Step 7: Verify Deployment

1. **Check Config Connector resources**:
   ```bash
   kubectl get configconnector -A
   kubectl get bigquerydataset -A
   kubectl get pubsubtopic -A
   kubectl get storagebucket -A
   ```

2. **Verify GCP resources in Cloud Console**:
   - BigQuery: Check datasets and tables
   - Pub/Sub: Verify topics and subscriptions
   - Cloud Storage: Confirm buckets are created
   - Cloud SQL: Check database instances

3. **Test Argo CD sync**:
   - Make a small change to infrastructure
   - Commit and push to repository
   - Watch Argo CD sync the changes

## Troubleshooting

### Common Issues

1. **Config Connector not ready**:
   ```bash
   kubectl get pods -n cnrm-system
   kubectl logs -n cnrm-system deployment/cnrm-controller-manager
   ```

2. **Permission errors**:
   ```bash
   # Check service account permissions
   gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --filter="bindings.members:cnrm-controller-manager@$PROJECT_ID.iam.gserviceaccount.com"
   ```

3. **Workload Identity issues**:
   ```bash
   # Verify annotation on Kubernetes service account
   kubectl get serviceaccount cnrm-controller-manager -n cnrm-system -o yaml
   ```

4. **Argo CD sync failures**:
   ```bash
   # Check application status
   kubectl get applications -n argocd
   argocd app get dev-infrastructure
   ```

## Next Steps

- [Adding New Resources](adding-resources.md)
- [Security Best Practices](security.md)
- [Monitoring and Alerting](monitoring.md)
