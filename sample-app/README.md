# Sample Data Pipeline Application

This directory contains a sample data processing application that demonstrates how to use the infrastructure managed by Config Connector.

## Components

- **data-ingester**: Publishes events to Pub/Sub topics
- **data-processor**: Consumes events and stores in BigQuery
- **analytics-service**: Queries BigQuery for business intelligence

## Usage

The application uses Workload Identity to authenticate with GCP services:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: data-pipeline-workload
  annotations:
    iam.gke.io/gcp-service-account: data-pipeline-sa@PROJECT_ID.iam.gserviceaccount.com
```

## Environment Variables

```bash
PROJECT_ID=your-gcp-project
PUBSUB_TOPIC=user-events-topic
BIGQUERY_DATASET=logs-dataset
BIGQUERY_TABLE=user-events-table
```

## Deployment

```bash
# Deploy to development
kubectl apply -f sample-app/ -n dev

# Deploy to staging  
kubectl apply -f sample-app/ -n staging

# Deploy to production
kubectl apply -f sample-app/ -n prod
```
