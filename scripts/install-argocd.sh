#!/bin/bash

# install-argocd.sh - Install Argo CD for GitOps

set -e

echo "🚀 Installing Argo CD..."

# Create Argo CD namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f - && echo "   ✅ [1/4] argocd namespace created"

# Install Argo CD
echo "📦 Installing Argo CD manifests..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml && echo "   ✅ [2/4] Argo CD manifests applied"

# Wait for Argo CD to be ready
echo "⏳ Waiting for Argo CD to be ready..."
kubectl wait --for=condition=Available deployment --all -n argocd --timeout=300s && echo "   ✅ [3/4] Argo CD deployments ready"

# Get initial admin password
echo "🔑 Getting Argo CD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Patch Argo CD server service to LoadBalancer (optional - for external access)
echo "🌐 Exposing Argo CD server..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}' && echo "   ✅ [4/4] Argo CD server exposed via LoadBalancer"

echo "✅ Argo CD installed successfully!"
echo ""
echo "📋 Access Information:"
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"
echo ""
echo "🌐 To access Argo CD:"
echo "1. Port forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "2. Open: https://localhost:8080"
echo "3. Or wait for LoadBalancer IP: kubectl get svc argocd-server -n argocd"
