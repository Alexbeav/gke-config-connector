#!/bin/bash

# setup-cluster.sh - Create GKE Autopilot cluster with Config Connector

set -e

# Configuration
PROJECT_ID=${PROJECT_ID:-$(gcloud config get-value project)}
CLUSTER_NAME=${CLUSTER_NAME:-"gitops-data-platform"}
REGION=${REGION:-"us-central1"}

echo "🚀 Creating GKE Autopilot cluster: $CLUSTER_NAME"
echo "Project: $PROJECT_ID"
echo "Region: $REGION"

# Check if PROJECT_ID is set
if [ -z "$PROJECT_ID" ]; then
    echo "❌ PROJECT_ID is not set. Please run: export PROJECT_ID=your-project-id"
    exit 1
fi

# Enable required APIs
echo "📡 Enabling required APIs..."
gcloud services enable container.googleapis.com \
    pubsub.googleapis.com \
    bigquery.googleapis.com \
    storage.googleapis.com \
    sqladmin.googleapis.com \
    iam.googleapis.com \
    cloudresourcemanager.googleapis.com \
    compute.googleapis.com \
    --project=$PROJECT_ID

# Create GKE Autopilot cluster with security hardening
echo "🔧 Creating hardened GKE Autopilot cluster..."
gcloud container clusters create-auto $CLUSTER_NAME \
    --region=$REGION \
    --logging=SYSTEM,WORKLOAD \
    --monitoring=SYSTEM \
    --release-channel=regular \
    --enable-master-global-access \
    --binauthz-evaluation-mode=PROJECT_SINGLETON_POLICY_ENFORCE \
    --security-posture=standard \
    --workload-vulnerability-scanning=standard \
    --project=$PROJECT_ID
# Get cluster credentials
echo "🔑 Getting cluster credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID

# Create namespaces for different environments
echo "📁 Creating namespaces..."
kubectl create namespace config-connector-system --dry-run=client -o yaml | kubectl apply -f - && echo "   ✅ [1/6] config-connector-system namespace created"
kubectl create namespace cnrm-system --dry-run=client -o yaml | kubectl apply -f - && echo "   ✅ [2/6] cnrm-system namespace created"
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f - && echo "   ✅ [3/6] dev namespace created"
kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f - && echo "   ✅ [4/6] staging namespace created"
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f - && echo "   ✅ [5/6] prod namespace created"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f - && echo "   ✅ [6/6] argocd namespace created"

echo "✅ GKE cluster created successfully!"
echo "Next steps:"
echo "1. Run 'make install-config-connector'"
echo "2. Run 'make install-gatekeeper'"
echo "3. Run 'make install-argocd'"
