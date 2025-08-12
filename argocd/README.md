# Argo CD Applications

This directory contains Argo CD Application definitions that implement GitOps for the data platform infrastructure.

## Applications

- **dev-infrastructure**: Manages development environment resources
- **staging-infrastructure**: Manages staging environment resources  
- **prod-infrastructure**: Manages production environment resources
- **base-infrastructure**: Manages shared base resources

## GitOps Workflow

1. **Developers** commit infrastructure changes to Git
2. **Argo CD** detects changes and syncs applications
3. **Config Connector** provisions/updates GCP resources
4. **Monitoring** tracks application health and sync status

## Sync Policies

- **Dev**: Auto-sync enabled with self-healing
- **Staging**: Manual sync required for controlled deployments
- **Prod**: Manual sync with additional approval workflows

## Application Structure

Each application:
- Points to specific environment overlay
- Has environment-appropriate sync policies
- Includes health checks and rollback capabilities
- Provides notifications for sync events
