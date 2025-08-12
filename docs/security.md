# Security Best Practices

This document outlines security best practices for the GitOps-driven data platform.

## Identity and Access Management

### Service Account Security

1. **Principle of Least Privilege**
   ```yaml
   # Grant only necessary permissions
   apiVersion: iam.cnrm.cloud.google.com/v1beta1
   kind: IAMPolicyMember
   metadata:
     name: limited-bigquery-access
   spec:
     member: serviceAccount:data-pipeline-sa@${PROJECT_ID}.iam.gserviceaccount.com
     role: roles/bigquery.dataEditor  # Not roles/bigquery.admin
     resourceRef:
       apiVersion: bigquery.cnrm.cloud.google.com/v1beta1
       kind: BigQueryDataset
       name: logs-dataset
   ```

2. **Service Account Key Rotation**
   - Use Workload Identity instead of service account keys
   - Regularly audit service account usage
   - Remove unused service accounts

3. **Cross-Environment Isolation**
   ```yaml
   # Separate service accounts per environment
   apiVersion: iam.cnrm.cloud.google.com/v1beta1
   kind: IAMServiceAccount
   metadata:
     name: data-pipeline-sa
     namespace: prod  # Environment-specific
   spec:
     displayName: "Prod Data Pipeline SA"
   ```

### Workload Identity Configuration

```yaml
# Secure Workload Identity binding
apiVersion: v1
kind: ServiceAccount
metadata:
  name: data-pipeline-workload
  namespace: prod
  annotations:
    iam.gke.io/gcp-service-account: prod-data-pipeline-sa@${PROJECT_ID}.iam.gserviceaccount.com
---
# GCP service account binding
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: workload-identity-binding
spec:
  member: serviceAccount:${PROJECT_ID}.svc.id.goog[prod/data-pipeline-workload]
  role: roles/iam.workloadIdentityUser
  resourceRef:
    apiVersion: iam.cnrm.cloud.google.com/v1beta1
    kind: IAMServiceAccount
    name: data-pipeline-sa
```

## Network Security

### Private GKE Cluster

```bash
# Create private GKE cluster
gcloud container clusters create-auto gitops-data-platform \
  --region=us-central1 \
  --enable-private-nodes \
  --master-ipv4-cidr-block=172.16.0.0/28 \
  --enable-ip-alias \
  --enable-network-policy
```

### VPC and Firewall Rules

```yaml
# Restrict Cloud SQL access
apiVersion: sql.cnrm.cloud.google.com/v1beta1
kind: SQLInstance
metadata:
  name: postgres-primary
spec:
  settings:
    ipConfiguration:
      requireSsl: true
      privateNetwork: "projects/${PROJECT_ID}/global/networks/default"
      ipv4Enabled: false  # Disable public IP
      authorizedNetworks: []  # No external access
```

### Bucket Security

```yaml
apiVersion: storage.cnrm.cloud.google.com/v1beta1
kind: StorageBucket
metadata:
  name: sensitive-data-bucket
spec:
  bucketPolicyOnly: true  # Disable ACLs
  versioning:
    enabled: true
  encryption:
    defaultKmsKeyName: "projects/${PROJECT_ID}/locations/us/keyRings/data-ring/cryptoKeys/bucket-key"
  publicAccessPrevention: "enforced"  # Block public access
```

## Data Protection

### Encryption at Rest

1. **Customer-Managed Encryption Keys (CMEK)**
   ```yaml
   # KMS key for BigQuery
   apiVersion: kms.cnrm.cloud.google.com/v1beta1
   kind: KMSCryptoKey
   metadata:
     name: bigquery-encryption-key
   spec:
     keyRingRef:
       name: data-encryption-ring
     rotationPeriod: "2592000s"  # 30 days
   
   ---
   # Use CMEK for BigQuery dataset
   apiVersion: bigquery.cnrm.cloud.google.com/v1beta1
   kind: BigQueryDataset
   metadata:
     name: encrypted-dataset
   spec:
     defaultEncryptionConfiguration:
       kmsKeyName: "projects/${PROJECT_ID}/locations/us/keyRings/data-ring/cryptoKeys/bigquery-encryption-key"
   ```

2. **Database Encryption**
   ```yaml
   apiVersion: sql.cnrm.cloud.google.com/v1beta1
   kind: SQLInstance
   metadata:
     name: encrypted-postgres
   spec:
     diskEncryptionConfiguration:
       kmsKeyName: "projects/${PROJECT_ID}/locations/us/keyRings/data-ring/cryptoKeys/sql-encryption-key"
   ```

### Data Classification and Labeling

```yaml
# Label sensitive data resources
apiVersion: bigquery.cnrm.cloud.google.com/v1beta1
kind: BigQueryDataset
metadata:
  name: pii-dataset
  labels:
    data-classification: "sensitive"
    compliance: "gdpr"
    retention-period: "7-years"
spec:
  labels:
    data-type: "personally-identifiable"
    access-level: "restricted"
```

## Secret Management

### Using Secret Manager

```yaml
# Store database passwords in Secret Manager
apiVersion: secretmanager.cnrm.cloud.google.com/v1beta1
kind: SecretManagerSecret
metadata:
  name: postgres-password
spec:
  replication:
    automatic: true
---
# Reference secret in Cloud SQL user
apiVersion: sql.cnrm.cloud.google.com/v1beta1
kind: SQLUser
metadata:
  name: app-user
spec:
  instanceRef:
    name: postgres-primary
  password:
    valueFrom:
      secretKeyRef:
        name: postgres-password
        key: "latest"
```

### Kubernetes Secrets Security

```yaml
# Use sealed secrets or external secret operators
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: gcpsm-secret-store
spec:
  provider:
    gcpsm:
      projectId: "${PROJECT_ID}"
      auth:
        workloadIdentity:
          clusterLocation: us-central1
          clusterName: gitops-data-platform
          serviceAccountRef:
            name: external-secrets-sa
```

## GitOps Security

### Repository Security

1. **Branch Protection**
   ```yaml
   # GitHub branch protection rules
   - require_status_checks: true
   - enforce_admins: true
   - required_pull_request_reviews:
       required_approving_review_count: 2
       dismiss_stale_reviews: true
   ```

2. **Signed Commits**
   ```bash
   # Enable commit signing
   git config --global commit.gpgsign true
   git config --global user.signingkey YOUR_GPG_KEY
   ```

### Argo CD Security

1. **RBAC Configuration**
   ```yaml
   # Restrict production access
   apiVersion: argoproj.io/v1alpha1
   kind: AppProject
   metadata:
     name: data-platform
   spec:
     roles:
       - name: prod-deployer
         policies:
           - p, proj:data-platform:prod-deployer, applications, sync, data-platform/prod-*, allow
         groups:
           - sre-team@company.com
   ```

2. **Resource Whitelisting**
   ```yaml
   spec:
     namespaceResourceWhitelist:
       # Only allow specific Config Connector resources
       - group: bigquery.cnrm.cloud.google.com
         kind: BigQueryDataset
       - group: pubsub.cnrm.cloud.google.com
         kind: PubSubTopic
       # Deny dangerous resources
     namespaceResourceBlacklist:
       - group: ""
         kind: Secret
   ```

### Supply Chain Security

1. **Image Scanning**
   ```yaml
   # Use Distroless images
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: data-processor
   spec:
     template:
       spec:
         containers:
           - name: app
             image: gcr.io/distroless/java:11
             securityContext:
               runAsNonRoot: true
               runAsUser: 65534
               readOnlyRootFilesystem: true
   ```

2. **Binary Authorization**
   ```yaml
   # Require signed container images
   apiVersion: binaryauthorization.cnrm.cloud.google.com/v1beta1
   kind: BinaryAuthorizationPolicy
   metadata:
     name: require-attestation
   spec:
     defaultAdmissionRule:
       requireAttestationsBy:
         - "projects/${PROJECT_ID}/attestors/prod-attestor"
       enforcementMode: "ENFORCED_BLOCK_AND_AUDIT_LOG"
   ```

## Monitoring and Auditing

### Audit Logging

```yaml
# Enable audit logs for Config Connector changes
apiVersion: logging.cnrm.cloud.google.com/v1beta1
kind: LoggingLogSink
metadata:
  name: config-connector-audit
spec:
  destination: "storage.googleapis.com/audit-logs-bucket"
  filter: 'resource.type="k8s_cluster" AND protoPayload.serviceName="k8s.io"'
  uniqueWriterIdentity: true
```

### Security Monitoring

```yaml
# Alert on suspicious IAM changes
apiVersion: monitoring.cnrm.cloud.google.com/v1beta1
kind: MonitoringAlertPolicy
metadata:
  name: iam-policy-changes
spec:
  displayName: "Suspicious IAM Changes"
  conditions:
    - displayName: "IAM policy binding changes"
      conditionThreshold:
        filter: 'resource.type="project" AND protoPayload.methodName="SetIamPolicy"'
        comparison: "COMPARISON_GREATER_THAN"
        thresholdValue: 0
  notificationChannels:
    - "projects/${PROJECT_ID}/notificationChannels/security-team"
```

## Compliance

### Data Retention Policies

```yaml
# Automated data deletion for compliance
apiVersion: storage.cnrm.cloud.google.com/v1beta1
kind: StorageBucket
metadata:
  name: gdpr-compliant-bucket
spec:
  lifecycle:
    rule:
      - action:
          type: "Delete"
        condition:
          age: 2555  # 7 years for financial data
          matchesStorageClass:
            - "STANDARD"
            - "NEARLINE"
            - "COLDLINE"
```

### Access Logging

```yaml
# Log all data access
apiVersion: bigquery.cnrm.cloud.google.com/v1beta1
kind: BigQueryDataset
metadata:
  name: sensitive-dataset
spec:
  access:
    - role: "READER"
      userByEmail: "analyst@company.com"
  defaultTableExpirationMs: 7776000000  # 90 days
  labels:
    audit-required: "true"
    data-classification: "sensitive"
```

## Emergency Procedures

### Break Glass Access

```yaml
# Emergency access service account
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMServiceAccount
metadata:
  name: emergency-access-sa
  annotations:
    emergency-contact: "sre-team@company.com"
spec:
  displayName: "Emergency Break Glass Access"
  description: "Use only for production emergencies"
```

### Incident Response

1. **Disable compromised service accounts**:
   ```bash
   gcloud iam service-accounts disable SERVICE_ACCOUNT_EMAIL
   ```

2. **Revoke OAuth tokens**:
   ```bash
   gcloud auth revoke SERVICE_ACCOUNT_EMAIL
   ```

3. **Rotate encryption keys**:
   ```bash
   gcloud kms keys versions create --key=KEY_NAME --keyring=RING_NAME --location=LOCATION
   ```

## Security Checklist

- [ ] All service accounts use Workload Identity
- [ ] Least privilege IAM policies applied
- [ ] Private GKE cluster configured
- [ ] CMEK encryption enabled for sensitive data
- [ ] Secret Manager used for secrets
- [ ] Branch protection enabled on Git repositories
- [ ] Container images scanned and signed
- [ ] Audit logging configured
- [ ] Security monitoring alerts set up
- [ ] Data retention policies defined
- [ ] Emergency procedures documented
