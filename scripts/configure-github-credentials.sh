#!/bin/bash
#
# Configure Argo CD with GitHub Repository Credentials
# This script reads credentials from .env.local and creates the necessary Kubernetes secrets
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env.local"

echo "🔐 Configuring Argo CD GitHub Repository Credentials..."

# Check if .env.local exists
if [[ ! -f "$ENV_FILE" ]]; then
    echo "❌ Error: .env.local file not found!"
    echo ""
    echo "Please create .env.local file with your GitHub credentials:"
    echo "1. Copy .env.example to .env.local"
    echo "2. Fill in your GitHub token and username"
    echo ""
    echo "Commands:"
    echo "  cp .env.example .env.local"
    echo "  # Edit .env.local with your credentials"
    exit 1
fi

# Source the environment file
source "$ENV_FILE"

# Validate required variables
if [[ -z "${GITHUB_TOKEN:-}" ]] || [[ -z "${GITHUB_USERNAME:-}" ]]; then
    echo "❌ Error: Missing required credentials in .env.local"
    echo ""
    echo "Required variables:"
    echo "  GITHUB_TOKEN=your_personal_access_token"
    echo "  GITHUB_USERNAME=your_github_username"
    exit 1
fi

# Check if credentials look valid
if [[ "$GITHUB_TOKEN" == "your_github_personal_access_token_here" ]] || [[ "$GITHUB_USERNAME" == "your_github_username_here" ]]; then
    echo "❌ Error: Please update .env.local with your actual GitHub credentials"
    echo ""
    echo "Current values look like template placeholders."
    echo "Visit: https://github.com/settings/tokens to create a personal access token"
    exit 1
fi

echo "✅ Credentials loaded from .env.local"
echo "   Username: $GITHUB_USERNAME"
echo "   Token: ${GITHUB_TOKEN:0:8}... (${#GITHUB_TOKEN} chars)"

# Create or update the repository secret
echo ""
echo "🔧 Creating Kubernetes secret for GitHub repository..."

kubectl create secret generic argocd-repo-credentials \
    --from-literal=type=git \
    --from-literal=url="https://github.com/YOUR_USERNAME/YOUR_REPOSITORY_NAME" \
    --from-literal=password="$GITHUB_TOKEN" \
    --from-literal=username="$GITHUB_USERNAME" \
    --namespace=argocd \
    --dry-run=client -o yaml | kubectl apply -f -

# Label the secret so Argo CD recognizes it
kubectl label secret argocd-repo-credentials \
    argocd.argoproj.io/secret-type=repository \
    --namespace=argocd \
    --overwrite

echo "✅ GitHub repository credentials configured!"
echo ""
echo "🚀 Next steps:"
echo "1. Applications will now be able to access your private repository"
echo "2. Run 'make status' to check if sync status improves"
echo "3. Access Argo CD UI to manually trigger sync if needed"
echo ""
echo "🌐 Argo CD UI: $(kubectl get service argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo 'make argocd-info')"
