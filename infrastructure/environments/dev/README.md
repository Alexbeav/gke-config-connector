# Development Environment

This overlay configures the data platform for the development environment.

## Configuration

- **Namespace**: `dev`
- **Resource Prefix**: `dev-`
- **Storage Class**: Reduced redundancy for cost savings
- **Retention**: Shorter retention periods
- **Scaling**: Minimal resources for development workloads

## Resources

All base resources are deployed with development-specific configurations:

- BigQuery datasets with 30-day retention
- Pub/Sub topics with 3-day message retention
- Cloud Storage buckets with minimal lifecycle policies
- Cloud SQL with smaller instance sizes
- IAM service accounts with development permissions

## Usage

```bash
# Apply dev environment resources
kubectl apply -k infrastructure/environments/dev/

# Verify resources
kubectl get -n dev configconnector
```
