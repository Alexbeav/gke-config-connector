#!/bin/bash

# install-gatekeeper.sh - Install OPA Gatekeeper for policy-as-code enforcement

set -e

echo "🛡️ Installing OPA Gatekeeper for policy enforcement..."

# Install Gatekeeper
echo "📦 Installing Gatekeeper..."
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml && echo "   ✅ [1/7] Gatekeeper manifests applied"

# Wait for Gatekeeper to be ready
echo "⏳ Waiting for Gatekeeper to be ready..."
kubectl wait --for=condition=Ready pod --all -n gatekeeper-system --timeout=300s && echo "   ✅ Gatekeeper pods ready"

# Create constraint templates for security policies
echo "📝 Creating security constraint templates..."

# Constraint template for required security labels
cat <<EOF | kubectl apply -f - && echo "   ✅ [2/7] K8sRequiredSecurityLabels constraint template created"
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredsecuritylabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredSecurityLabels
      validation:
        type: object
        properties:
          labels:
            type: array
            items:
              type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredsecuritylabels
        
        violation[{"msg": msg}] {
          required := input.parameters.labels
          provided := input.review.object.metadata.labels
          missing := required[_]
          not provided[missing]
          msg := sprintf("Missing required security label: %v", [missing])
        }
EOF

# Constraint template for disallowing privileged containers
cat <<EOF | kubectl apply -f - && echo "   ✅ [3/7] K8sDisallowPrivileged constraint template created"
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8sdisallowprivileged
spec:
  crd:
    spec:
      names:
        kind: K8sDisallowPrivileged
      validation:
        type: object
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sdisallowprivileged
        
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          container.securityContext.privileged
          msg := "Privileged containers are not allowed"
        }
        
        violation[{"msg": msg}] {
          container := input.review.object.spec.initContainers[_]
          container.securityContext.privileged
          msg := "Privileged init containers are not allowed"
        }
EOF

# Constraint template for required resource limits
cat <<EOF | kubectl apply -f - && echo "   ✅ [4/7] K8sRequiredResources constraint template created"
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredresources
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredResources
      validation:
        type: object
        properties:
          limits:
            type: array
            items:
              type: string
          requests:
            type: array
            items:
              type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredresources
        
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          required_limits := input.parameters.limits
          required_limit := required_limits[_]
          not container.resources.limits[required_limit]
          msg := sprintf("Container missing required resource limit: %v", [required_limit])
        }
        
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          required_requests := input.parameters.requests
          required_request := required_requests[_]
          not container.resources.requests[required_request]
          msg := sprintf("Container missing required resource request: %v", [required_request])
        }
EOF

echo "⏳ Waiting for constraint templates to be ready..."
sleep 10

# Create security constraints
echo "🔒 Creating security constraints..."

# Require security labels on Config Connector resources
cat <<EOF | kubectl apply -f - && echo "   ✅ [5/7] Security labels constraint created"
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredSecurityLabels
metadata:
  name: must-have-security-labels
spec:
  match:
    kinds:
      - apiGroups: ["*.cnrm.cloud.google.com"]
        kinds: ["*"]
  parameters:
    labels: ["component", "managed-by", "environment"]
EOF

# Disallow privileged containers
cat <<EOF | kubectl apply -f - && echo "   ✅ [6/7] Privileged containers constraint created"
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sDisallowPrivileged
metadata:
  name: no-privileged-containers
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
      - apiGroups: ["apps"]
        kinds: ["Deployment", "StatefulSet", "DaemonSet"]
  excludedNamespaces: ["kube-system", "gatekeeper-system", "cnrm-system"]
EOF

# Require resource limits and requests
cat <<EOF | kubectl apply -f - && echo "   ✅ [7/7] Resource limits constraint created"
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredResources
metadata:
  name: must-have-resources
spec:
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment", "StatefulSet"]
  excludedNamespaces: ["kube-system", "gatekeeper-system", "cnrm-system"]
  parameters:
    limits: ["memory", "cpu"]
    requests: ["memory", "cpu"]
EOF

echo "✅ Gatekeeper installed and configured successfully!"
echo "Security policies are now enforced cluster-wide."
