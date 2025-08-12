# Base Infrastructure Resources

This directory contains the base Kubernetes manifests for GCP resources managed by Config Connector.

## Resource Types

- **BigQuery**: Datasets and tables for data analytics
- **Pub/Sub**: Topics and subscriptions for event streaming  
- **Cloud Storage**: Buckets for data storage
- **Cloud SQL**: PostgreSQL instances for relational data
- **IAM**: Service accounts and policy bindings

## Usage

These base resources are used by environment-specific overlays in the `environments/` directory.

Each environment can customize:
- Resource names (with environment prefixes)
- Scaling parameters
- Location/region settings
- Security policies

## Kustomization

All resources use Kustomize for configuration management, allowing:
- Environment-specific parameter substitution
- Resource name prefixing
- Label and annotation injection
- Configuration composition
