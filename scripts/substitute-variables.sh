#!/bin/bash
#
# Variable Substitution Script for GitOps Data Platform
# Replaces template variables with actual values in infrastructure files
#

set -euo pipefail

# Get current project configuration
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# For demo purposes, use placeholder values for optional variables
ORGANIZATION_DOMAIN="example.com"
ORGANIZATION_ID="123456789012"
ACCESS_POLICY_ID="accessPolicies/123456789"

echo "🔄 Substituting variables in infrastructure templates..."
echo "Project ID: $PROJECT_ID"
echo "Project Number: $PROJECT_NUMBER"

# Create a temporary directory for processed files
TEMP_DIR=$(mktemp -d)
echo "Working directory: $TEMP_DIR"

# Copy infrastructure files to temp directory
cp -r infrastructure/ "$TEMP_DIR/"

# Function to substitute variables in files
substitute_vars() {
    local file="$1"
    echo "Processing: $file"
    
    # Use different delimiters to avoid conflicts with forward slashes
    # Substitute all variables
    sed -i "s|\${PROJECT_ID}|$PROJECT_ID|g" "$file"
    sed -i "s|\${PROJECT_NUMBER}|$PROJECT_NUMBER|g" "$file"
    sed -i "s|\${ORGANIZATION_DOMAIN}|$ORGANIZATION_DOMAIN|g" "$file"
    sed -i "s|\${ORGANIZATION_ID}|$ORGANIZATION_ID|g" "$file"
    sed -i "s|\${ACCESS_POLICY_ID}|$ACCESS_POLICY_ID|g" "$file"
}

# Find and process all YAML files
find "$TEMP_DIR/infrastructure" -name "*.yaml" -type f | while read -r file; do
    substitute_vars "$file"
done

# Copy processed files back
echo "📋 Copying processed files back to infrastructure/"
rm -rf infrastructure-processed/
mkdir -p infrastructure-processed/
cp -r "$TEMP_DIR/infrastructure/"* infrastructure-processed/

echo "✅ Variable substitution complete!"
echo "📁 Processed files are in: infrastructure-processed/"
echo ""
echo "Next steps:"
echo "1. Review processed files: ls -la infrastructure-processed/"
echo "2. Deploy with: kubectl apply -k infrastructure-processed/environments/dev/"
echo "3. Check status with: make status"

# Cleanup
rm -rf "$TEMP_DIR"
