#!/bin/bash
# install-config-connector.sh - Install and configure Config Connector

set -e

PROJECT_ID=${PROJECT_ID:-$(gcloud config get-value project)}
CLUSTER_NAME=${CLUSTER_NAME:-"gitops-data-platform"}
REGION=${REGION:-"us-central1"}

echo "🔧 Installing Config Connector..."

# Download and extract Config Connector Operator
echo "📦 Downloading Config Connector operator..."
gcloud storage cp gs://configconnector-operator/latest/release-bundle.tar.gz release-bundle.tar.gz
tar zxvf release-bundle.tar.gz

# Install Config Connector operator for Autopilot
echo "🚀 Installing Config Connector operator for Autopilot..."
kubectl apply -f operator-system/autopilot-configconnector-operator.yaml

# Wait for Config Connector operator to be ready
echo "⏳ Waiting for Config Connector operator..."
kubectl wait --for=condition=Ready pod --all -n configconnector-operator-system --timeout=300s

# Create service account for Config Connector
echo "🔑 Setting up service accounts and Workload Identity..."
gcloud iam service-accounts create cnrm-controller-manager \
    --display-name="Config Connector Controller Manager" || true

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:cnrm-controller-manager@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/editor"

# Enable Workload Identity
gcloud iam service-accounts add-iam-policy-binding \
    cnrm-controller-manager@$PROJECT_ID.iam.gserviceaccount.com \
    --member="serviceAccount:$PROJECT_ID.svc.id.goog[cnrm-system/cnrm-controller-manager]" \
    --role="roles/iam.workloadIdentityUser"

# Annotate Kubernetes service account
kubectl annotate serviceaccount cnrm-controller-manager \
    -n cnrm-system \
    iam.gke.io/gcp-service-account=cnrm-controller-manager@$PROJECT_ID.iam.gserviceaccount.com

# Configure Config Connector for cluster mode
echo "🔧 Configuring Config Connector..."
cat <<EOF | kubectl apply -f -
apiVersion: core.cnrm.cloud.google.com/v1beta1
kind: ConfigConnector
metadata:
  name: configconnector.core.cnrm.cloud.google.com
spec:
  mode: cluster
  googleServiceAccount: "cnrm-controller-manager@$PROJECT_ID.iam.gserviceaccount.com"
  stateIntoSpec: Absent
EOF

# Wait for Config Connector to be ready
echo "⏳ Waiting for Config Connector controller to be ready..."
kubectl wait --for=condition=Ready pod --all -n cnrm-system --timeout=300s

# Annotate namespaces for Config Connector
echo "🏷️ Configuring namespaces..."
kubectl annotate namespace default cnrm.cloud.google.com/project-id=$PROJECT_ID && echo "   ✅ [1/4] default namespace annotated"
kubectl annotate namespace dev cnrm.cloud.google.com/project-id=$PROJECT_ID && echo "   ✅ [2/4] dev namespace annotated"
kubectl annotate namespace staging cnrm.cloud.google.com/project-id=$PROJECT_ID && echo "   ✅ [3/4] staging namespace annotated"
kubectl annotate namespace prod cnrm.cloud.google.com/project-id=$PROJECT_ID && echo "   ✅ [4/4] prod namespace annotated"

echo "✅ Config Connector installed and configured successfully!"
echo "You can now create GCP resources using Kubernetes manifests."

# Clean up downloaded files
rm -f release-bundle.tar.gz
rm -rf operator-system/
