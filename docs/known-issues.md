# Known Issues and Limitations

## GKE Autopilot Limitations

### OPA Gatekeeper Installation Issue

**Issue**: OPA Gatekeeper fails to install on GKE Autopilot clusters with the following error:
```
Error from server (GKE Admission Webhook Controller): admission webhook "admissionwebhookcontroller.common-webhooks.networking.gke.io" denied the request: GKE Admission Webhook Controller: the following (group,resource) pairs are not allowed in webhook rules: ('*','*'), see: https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-security#built-in-security
```

**Root Cause**: GKE Autopilot has built-in security restrictions that prevent certain admission webhooks from using wildcard ('*','*') rules. This is a security feature to prevent potentially dangerous webhooks from intercepting all Kubernetes API requests.

**Official Documentation**: https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-security#built-in-security

**Impact**: 
- ❌ OPA Gatekeeper cannot be installed via the standard manifest
- ✅ All other platform components work perfectly (Config Connector, ArgoCD, infrastructure deployment)
- ✅ Platform remains enterprise-ready with other security controls

**Workarounds**:

1. **Use Pod Security Standards (Recommended)**
   ```bash
   # Enable Pod Security Standards instead of Gatekeeper
   kubectl label namespace default pod-security.kubernetes.io/enforce=restricted
   kubectl label namespace default pod-security.kubernetes.io/audit=restricted
   kubectl label namespace default pod-security.kubernetes.io/warn=restricted
   ```

2. **Use Config Connector Validation**
   - Config Connector provides resource validation at the infrastructure level
   - Use organization policies for GCP-level governance
   - Implement pre-commit hooks for policy validation

3. **Use Standard GKE (Not Autopilot)**
   - Standard GKE allows full Gatekeeper installation
   - Requires more operational overhead but provides complete flexibility

**Platform Status**: 
- ✅ **PRODUCTION READY** with Pod Security Standards
- ✅ All core functionality working
- ✅ Security posture maintained through other controls

## Alternative Security Controls

When Gatekeeper is not available, the platform uses:

1. **Config Connector Validation** - Resource schema validation
2. **Pod Security Standards** - Pod-level security policies
3. **GCP Organization Policies** - Cloud-level governance
4. **IAM Policies** - Access control
5. **Network Policies** - Traffic control
6. **Workload Identity** - Service authentication

These alternatives provide enterprise-grade security without requiring Gatekeeper.

## Cleanup Considerations

### Orphaned GCP Resources After Cluster Deletion

**Issue**: When you run `make cleanup-cluster`, it only deletes the GKE cluster but leaves behind GCP resources that were created by Config Connector (PubSub topics, Storage buckets, IAM service accounts, etc.).

**Root Cause**: Config Connector creates real GCP resources that exist independently of the Kubernetes cluster. When the cluster is deleted, these resources become "orphaned" because the Config Connector controllers that manage them are gone.

**Impact**:
- ❌ Resources continue to exist and may incur costs
- ❌ Resources may prevent project cleanup or cause conflicts in future deployments
- ✅ Data is preserved (which may be desired in some cases)

**Solutions**:

1. **Clean up environments first (Recommended)**:
   ```bash
   make cleanup-dev
   make cleanup-staging  
   make cleanup-prod     # If applicable
   make cleanup-cluster  # Then delete cluster
   ```

2. **Use the complete cleanup target**:
   ```bash
   make cleanup-everything  # Deletes cluster AND orphaned resources
   ```

3. **Clean up orphaned resources manually**:
   ```bash
   make cleanup-orphaned-resources  # After cluster is already deleted
   ```

**Note**: The Google Cloud Asset API may have indexing delays, so resources might appear in `gcloud asset search-all-resources` for a few minutes after actual deletion.
