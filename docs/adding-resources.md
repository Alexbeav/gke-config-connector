# Adding New Resources

This guide explains how to add new GCP resources to the data platform infrastructure.

## Overview

The infrastructure uses a layered approach:
1. **Base resources** - Generic resource definitions
2. **Environment overlays** - Environment-specific configurations
3. **Argo CD applications** - GitOps deployment automation

## Adding a New Resource Type

### Step 1: Create Base Resource Definition

Create a new YAML file in `infrastructure/base/` for your resource type:

```yaml
# infrastructure/base/memorystore.yaml
apiVersion: redis.cnrm.cloud.google.com/v1beta1
kind: RedisInstance
metadata:
  name: cache-instance
  labels:
    component: cache
    managed-by: config-connector
spec:
  tier: "BASIC"
  memorySizeGb: 1
  region: "us-central1"
  redisVersion: "REDIS_6_X"
  displayName: "Application Cache"
  labels:
    environment: "placeholder"
    team: "data-engineering"
```

### Step 2: Update Base Kustomization

Add your new resource to `infrastructure/base/kustomization.yaml`:

```yaml
resources:
  - bigquery.yaml
  - pubsub.yaml
  - storage.yaml
  - cloudsql.yaml
  - iam.yaml
  - memorystore.yaml  # Add your new resource
```

### Step 3: Create Environment-Specific Patches

Add patches for each environment in their respective `kustomization.yaml` files:

```yaml
# infrastructure/environments/dev/kustomization.yaml
patches:
  # Existing patches...
  
  # Use smaller Redis instance for dev
  - target:
      kind: RedisInstance
      name: cache-instance
    patch: |
      - op: replace
        path: /spec/memorySizeGb
        value: 1
      - op: replace
        path: /spec/tier
        value: "BASIC"
```

```yaml
# infrastructure/environments/prod/kustomization.yaml
patches:
  # Existing patches...
  
  # Use HA Redis instance for prod
  - target:
      kind: RedisInstance
      name: cache-instance
    patch: |
      - op: replace
        path: /spec/memorySizeGb
        value: 4
      - op: replace
        path: /spec/tier
        value: "STANDARD_HA"
```

### Step 4: Add IAM Permissions

Create appropriate IAM policies in `infrastructure/base/iam.yaml`:

```yaml
# Redis access for application service account
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: app-redis-access
  labels:
    component: iam
    managed-by: config-connector
spec:
  member: serviceAccount:data-pipeline-sa@${PROJECT_ID}.iam.gserviceaccount.com
  role: roles/redis.editor
  resourceRef:
    apiVersion: redis.cnrm.cloud.google.com/v1beta1
    kind: RedisInstance
    name: cache-instance
```

### Step 5: Update Argo CD Project

Add the new resource type to the allowed resources in `argocd/project.yaml`:

```yaml
namespaceResourceWhitelist:
  # Existing resources...
  - group: redis.cnrm.cloud.google.com
    kind: "*"
```

### Step 6: Test and Deploy

1. **Validate locally**:
   ```bash
   kubectl kustomize infrastructure/environments/dev/
   ```

2. **Commit changes**:
   ```bash
   git add .
   git commit -m "Add Redis Memorystore support"
   git push origin main
   ```

3. **Sync via Argo CD**:
   ```bash
   argocd app sync dev-infrastructure
   ```

## Resource-Specific Guides

### Adding Cloud Functions

```yaml
# infrastructure/base/functions.yaml
apiVersion: cloudfunctions.cnrm.cloud.google.com/v1beta1
kind: CloudFunction
metadata:
  name: data-processor-function
spec:
  sourceArchiveUrl: "gs://source-bucket/function.zip"
  runtime: "python39"
  entryPoint: "process_data"
  httpsTrigger: {}
  availableMemoryMb: 256
  timeout: "60s"
  environmentVariables:
    PROJECT_ID: "${PROJECT_ID}"
```

### Adding Cloud Run Services

```yaml
# infrastructure/base/cloudrun.yaml
apiVersion: run.cnrm.cloud.google.com/v1beta1
kind: RunService
metadata:
  name: api-service
spec:
  location: "us-central1"
  template:
    spec:
      containers:
        - image: "gcr.io/${PROJECT_ID}/api:latest"
          ports:
            - containerPort: 8080
          env:
            - name: DATABASE_URL
              value: "postgresql://user:pass@localhost/db"
```

### Adding Kubernetes Engine Resources

```yaml
# infrastructure/base/gke.yaml
apiVersion: container.cnrm.cloud.google.com/v1beta1
kind: ContainerNodePool
metadata:
  name: high-memory-pool
spec:
  location: "us-central1"
  clusterRef:
    name: "data-platform-cluster"
  nodeCount: 1
  nodeConfig:
    machineType: "n1-highmem-2"
    diskSizeGb: 100
    oauthScopes:
      - "https://www.googleapis.com/auth/cloud-platform"
```

## Best Practices

### Resource Naming
- Use consistent naming patterns: `{environment}-{resource-type}-{purpose}`
- Include descriptive labels for filtering and organization

### Configuration Management
- Keep environment-specific values in patches, not base resources
- Use ConfigMaps for environment variables
- Store secrets in Kubernetes Secrets or Secret Manager

### Dependencies
- Use `resourceRef` to reference other Config Connector resources
- Ensure proper ordering with Argo CD sync waves if needed

### Testing
- Test changes in development environment first
- Use `kubectl dry-run` to validate manifests
- Monitor Argo CD application health after deployment

## Common Resource Types

| GCP Service | Config Connector Kind | Use Case |
|-------------|----------------------|----------|
| Cloud Functions | CloudFunction | Event processing |
| Cloud Run | RunService | Serverless APIs |
| Cloud Scheduler | CloudSchedulerJob | Cron jobs |
| Secret Manager | SecretManagerSecret | Secret storage |
| Cloud DNS | DNSManagedZone | DNS management |
| Cloud CDN | ComputeBackendService | Content delivery |
| Cloud Armor | ComputeSecurityPolicy | DDoS protection |

## Troubleshooting

### Resource Creation Issues
```bash
# Check resource status
kubectl describe <resource-type> <resource-name> -n <namespace>

# Check Config Connector logs
kubectl logs -n cnrm-system deployment/cnrm-controller-manager
```

### Permission Issues
```bash
# Verify service account has necessary roles
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:cnrm-controller-manager@$PROJECT_ID.iam.gserviceaccount.com"
```

### Dependency Issues
- Ensure referenced resources exist before creating dependent resources
- Use Argo CD sync waves for complex dependencies
- Check resource status before proceeding to dependent resources
