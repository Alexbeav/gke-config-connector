#!/bin/bash

# Manual cleanup script for orphaned GCP resources
# Use this when Config Connector resources are left after cluster deletion

set -e

PROJECT_ID=${PROJECT_ID:-$(gcloud config get-value project)}
echo "🧹 Cleaning up orphaned GCP resources in project: $PROJECT_ID"

echo "🗑️ Deleting PubSub subscriptions..."
gcloud pubsub subscriptions delete dev-user-events-subscription --quiet 2>/dev/null || echo "   ⚠️ [1/24] dev-user-events-subscription not found or already deleted"
gcloud pubsub subscriptions delete staging-user-events-subscription --quiet 2>/dev/null || echo "   ⚠️ [2/24] staging-user-events-subscription not found or already deleted"
gcloud pubsub subscriptions delete prod-user-events-subscription --quiet 2>/dev/null || echo "   ⚠️ [3/24] prod-user-events-subscription not found or already deleted"

echo "🗑️ Deleting PubSub topics..."
gcloud pubsub topics delete dev-user-events-topic --quiet 2>/dev/null || echo "   ⚠️ [4/24] dev-user-events-topic not found or already deleted"
gcloud pubsub topics delete staging-user-events-topic --quiet 2>/dev/null || echo "   ⚠️ [5/24] staging-user-events-topic not found or already deleted"
gcloud pubsub topics delete prod-user-events-topic --quiet 2>/dev/null || echo "   ⚠️ [6/24] prod-user-events-topic not found or already deleted"

echo "🗑️ Deleting Storage buckets..."
gsutil rm -r gs://dev-data-ingest-bucket 2>/dev/null || echo "   ⚠️ [7/24] dev-data-ingest-bucket not found or already deleted"
gsutil rm -r gs://staging-data-ingest-bucket 2>/dev/null || echo "   ⚠️ [8/24] staging-data-ingest-bucket not found or already deleted"
gsutil rm -r gs://prod-data-ingest-bucket 2>/dev/null || echo "   ⚠️ [9/24] prod-data-ingest-bucket not found or already deleted"

echo "🗑️ Deleting IAM service accounts..."
gcloud iam service-accounts delete dev-data-pipeline-sa@${PROJECT_ID}.iam.gserviceaccount.com --quiet 2>/dev/null || echo "   ⚠️ [10/24] dev-data-pipeline-sa not found or already deleted"
gcloud iam service-accounts delete staging-data-pipeline-sa@${PROJECT_ID}.iam.gserviceaccount.com --quiet 2>/dev/null || echo "   ⚠️ [11/24] staging-data-pipeline-sa not found or already deleted"
gcloud iam service-accounts delete prod-data-pipeline-sa@${PROJECT_ID}.iam.gserviceaccount.com --quiet 2>/dev/null || echo "   ⚠️ [12/24] prod-data-pipeline-sa not found or already deleted"

echo "🗑️ Deleting VPC networks and dependencies..."
# Delete firewall rules first
gcloud compute firewall-rules delete dev-allow-internal --quiet 2>/dev/null || echo "   ⚠️ [13/24] dev-allow-internal firewall not found"
gcloud compute firewall-rules delete staging-allow-internal --quiet 2>/dev/null || echo "   ⚠️ [14/24] staging-allow-internal firewall not found"
gcloud compute firewall-rules delete prod-allow-internal --quiet 2>/dev/null || echo "   ⚠️ [15/24] prod-allow-internal firewall not found"

# Delete NAT routers
gcloud compute routers delete dev-nat-router --region=us-central1 --quiet 2>/dev/null || echo "   ⚠️ [16/24] dev-nat-router not found"
gcloud compute routers delete staging-nat-router --region=us-central1 --quiet 2>/dev/null || echo "   ⚠️ [17/24] staging-nat-router not found"
gcloud compute routers delete prod-nat-router --region=us-central1 --quiet 2>/dev/null || echo "   ⚠️ [18/24] prod-nat-router not found"

# Delete subnets
gcloud compute networks subnets delete dev-private-subnet --region=us-central1 --quiet 2>/dev/null || echo "   ⚠️ [19/24] dev-private-subnet not found"
gcloud compute networks subnets delete staging-private-subnet --region=us-central1 --quiet 2>/dev/null || echo "   ⚠️ [20/24] staging-private-subnet not found"
gcloud compute networks subnets delete prod-private-subnet --region=us-central1 --quiet 2>/dev/null || echo "   ⚠️ [21/24] prod-private-subnet not found"

# Finally delete networks
gcloud compute networks delete dev-secure-vpc --quiet 2>/dev/null || echo "   ⚠️ [22/24] dev-secure-vpc not found or already deleted"
gcloud compute networks delete staging-secure-vpc --quiet 2>/dev/null || echo "   ⚠️ [23/24] staging-secure-vpc not found or already deleted"  
gcloud compute networks delete prod-secure-vpc --quiet 2>/dev/null || echo "   ⚠️ [24/24] prod-secure-vpc not found or already deleted"

echo "✅ Cleanup complete! Checking remaining resources..."
echo ""
echo "🔍 Remaining platform resources:"
gcloud asset search-all-resources --query="name:*user-events* OR name:*data-ingest* OR name:*data-pipeline* OR name:*secure-vpc*" --format="table(name,assetType)" 2>/dev/null || echo "No matching resources found"
