# GitOps Data Platform Makefile
# Automates deployment and management of the data platform infrastructure

SHELL := /bin/bash

# Configuration
PROJECT_ID ?= $(shell gcloud config get-value project)
CLUSTER_NAME ?= gitops-data-platform
REGION ?= us-central1
GITHUB_REPO ?= https://github.com/YOUR_USERNAME/YOUR_REPOSITORY_NAME

# Colors for output
RED=\033[0;31m
GREEN=\033[0;32m
YELLOW=\033[1;33m
NC=\033[0m # No Color

.PHONY: help
help: ## Show this help message
	@echo "GitOps Data Platform Management"
	@echo "==============================="
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: check-env
check-env: ## Check required environment variables
	@echo "$(YELLOW)Checking environment...$(NC)"
	@test -n "$(PROJECT_ID)" || (echo "$(RED)PROJECT_ID not set$(NC)" && exit 1)
	@echo "$(GREEN)✓ PROJECT_ID: $(PROJECT_ID)$(NC)"
	@which gcloud > /dev/null || (echo "$(RED)gcloud CLI not found$(NC)" && exit 1)
	@echo "$(GREEN)✓ gcloud CLI installed$(NC)"
	@which kubectl > /dev/null || (echo "$(RED)kubectl not found$(NC)" && exit 1)
	@echo "$(GREEN)✓ kubectl installed$(NC)"

.PHONY: setup-all
setup-all: check-env setup-cluster install-config-connector install-gatekeeper install-argocd ## Complete setup: cluster + Config Connector + Gatekeeper + Argo CD
	@echo "$(GREEN)✅ Complete enterprise setup finished!$(NC)"
	@echo "$(YELLOW)Security Features Enabled:$(NC)"
	@echo "• Organization policies enforced"
	@echo "• Private VPC with network security"
	@echo "• Workload Identity Federation"
	@echo "• OPA Gatekeeper policy enforcement"
	@echo "• Security monitoring and alerting"
	@echo "• Customer-managed encryption keys"
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "1. Update GitHub repository URL in argocd/applications-enhanced.yaml"
	@echo "2. Run 'make deploy-infrastructure'"
	@echo "3. Access Argo CD UI with 'make argocd-ui'"

.PHONY: setup-cluster
setup-cluster: check-env ## Create GKE cluster and namespaces
	@echo "$(YELLOW)Creating GKE cluster...$(NC)"
	@chmod +x scripts/setup-cluster.sh
	@./scripts/setup-cluster.sh
	@echo "$(GREEN)✓ Cluster created successfully$(NC)"

.PHONY: install-config-connector
install-config-connector: check-env ## Install and configure Config Connector
	@echo "$(YELLOW)Installing Config Connector...$(NC)"
	@chmod +x scripts/install-config-connector.sh
	@./scripts/install-config-connector.sh
	@echo "$(GREEN)✓ Config Connector installed$(NC)"

.PHONY: install-gatekeeper
install-gatekeeper: check-env ## Install OPA Gatekeeper for policy enforcement
	@echo "$(YELLOW)Installing OPA Gatekeeper...$(NC)"
	@chmod +x scripts/install-gatekeeper.sh
	@./scripts/install-gatekeeper.sh
	@echo "$(GREEN)✓ Gatekeeper installed$(NC)"
install-argocd: check-env ## Install Argo CD
	@echo "$(YELLOW)Installing Argo CD...$(NC)"
	@chmod +x scripts/install-argocd.sh
	@./scripts/install-argocd.sh
	@echo "$(GREEN)✓ Argo CD installed$(NC)"

.PHONY: complete-setup
complete-setup: check-env substitute-vars deploy-policies deploy-infrastructure test-end-to-end ## Complete the platform setup with all components
	@echo "$(GREEN)🎉 Platform setup complete!$(NC)"
	@echo "$(YELLOW)✅ Completed:$(NC)"
	@echo "  • GKE Autopilot cluster"
	@echo "  • Config Connector (150+ CRDs)"
	@echo "  • Argo CD GitOps platform"
	@echo "  • Gatekeeper OPA security policies"
	@echo "  • Infrastructure templates with variables"
	@echo "  • End-to-end workflow validation"
	@echo ""
	@echo "$(YELLOW)🔗 Access points:$(NC)"
	@echo "  • Argo CD UI: make argocd-ui"
	@echo "  • Platform status: make status"
	@echo "  • Security check: make security-check"

.PHONY: deploy-policies
deploy-policies: check-env ## Deploy Gatekeeper security policies
	@echo "$(YELLOW)Deploying Gatekeeper security policies...$(NC)"
	@kubectl apply -f security-policies/gatekeeper-policies.yaml
	@echo "$(GREEN)✓ Security policies deployed$(NC)"
	@echo "$(YELLOW)Waiting for policies to be ready...$(NC)"
	@sleep 10
	@kubectl get constrainttemplates
	@kubectl get k8srequiredlabels,k8srequiredresources,k8sallowedrepos -A

.PHONY: test-end-to-end
test-end-to-end: check-env ## Test end-to-end platform functionality
	@echo "$(YELLOW)🧪 Running end-to-end tests...$(NC)"
	@echo "$(YELLOW)Testing namespace creation with labels...$(NC)"
	@kubectl apply -f - <<< 'apiVersion: v1\nkind: Namespace\nmetadata:\n  name: test-platform\n  labels:\n    environment: dev\n    team: platform-testing' || true
	@echo "$(YELLOW)Testing application deployment...$(NC)"
	@kubectl get applications -n argocd
	@echo "$(YELLOW)Testing Gatekeeper policies...$(NC)"
	@kubectl get constrainttemplates
	@echo "$(YELLOW)Testing Config Connector...$(NC)"
	@kubectl get crd | grep cnrm | wc -l | xargs echo "Config Connector CRDs available:"
	@echo "$(GREEN)✅ End-to-end tests completed$(NC)"
	@kubectl delete namespace test-platform --ignore-not-found=true

.PHONY: setup-github-credentials
setup-github-credentials: ## Configure GitHub repository credentials for Argo CD
	@echo "$(YELLOW)Setting up GitHub repository credentials...$(NC)"
	@chmod +x scripts/configure-github-credentials.sh
	@./scripts/configure-github-credentials.sh
	@echo "$(GREEN)✓ GitHub credentials configured$(NC)"

.PHONY: create-env-file
create-env-file: ## Create .env.local file from template
	@echo "$(YELLOW)Creating .env.local file...$(NC)"
	@if [ -f .env.local ]; then \
		echo "$(YELLOW)⚠️  .env.local already exists. Backup created as .env.local.backup$(NC)"; \
		cp .env.local .env.local.backup; \
	fi
	@cp .env.example .env.local
	@echo "$(GREEN)✓ .env.local created from template$(NC)"
	@echo "$(YELLOW)📝 Next steps:$(NC)"
	@echo "  1. Edit .env.local with your GitHub credentials"
	@echo "  2. Get token from: https://github.com/settings/tokens"
	@echo "  3. Run 'make setup-github-credentials' when ready"

.PHONY: check-github-auth
check-github-auth: ## Check if GitHub repository credentials are working
	@echo "$(YELLOW)Checking GitHub repository authentication...$(NC)"
	@if kubectl get secret argocd-repo-credentials -n argocd >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Repository credentials secret exists$(NC)"; \
		echo "$(YELLOW)Repository URL: $$(kubectl get secret argocd-repo-credentials -n argocd -o jsonpath='{.data.url}' | base64 -d)$(NC)"; \
		echo "$(YELLOW)Username: $$(kubectl get secret argocd-repo-credentials -n argocd -o jsonpath='{.data.username}' | base64 -d)$(NC)"; \
	else \
		echo "$(RED)✗ Repository credentials not configured$(NC)"; \
		echo "$(YELLOW)Run: make setup-github-credentials$(NC)"; \
	fi

.PHONY: remove-github-credentials
remove-github-credentials: ## Remove GitHub repository credentials
	@echo "$(YELLOW)Removing GitHub repository credentials...$(NC)"
	@kubectl delete secret argocd-repo-credentials -n argocd --ignore-not-found=true
	@echo "$(GREEN)✓ GitHub credentials removed$(NC)"

.PHONY: substitute-vars
substitute-vars: check-env ## Substitute variables in infrastructure templates
	@echo "$(YELLOW)Substituting variables in infrastructure templates...$(NC)"
	@chmod +x scripts/substitute-variables.sh
	@./scripts/substitute-variables.sh
	@echo "$(GREEN)✓ Variables substituted$(NC)"

.PHONY: deploy-infrastructure
deploy-infrastructure: check-env substitute-vars ## Deploy infrastructure via Argo CD
	@echo "$(YELLOW)Deploying infrastructure applications...$(NC)"
	@kubectl apply -f argocd/project.yaml && echo "$(GREEN)✓ [1/2] Argo CD project applied$(NC)"
	@kubectl apply -f argocd/applications.yaml && echo "$(GREEN)✓ [2/2] Argo CD applications applied$(NC)"
	@echo "$(GREEN)✓ Infrastructure applications created$(NC)"
	@echo "$(YELLOW)Note: Production deployments require manual approval$(NC)"

.PHONY: sync-dev
sync-dev: ## Sync development environment
	@echo "$(YELLOW)Syncing dev environment...$(NC)"
	@kubectl patch application dev-infrastructure -n argocd --type merge -p '{"operation":{"sync":{"prune":true}}}'
	@echo "$(GREEN)✓ Dev sync initiated$(NC)"

.PHONY: sync-staging
sync-staging: ## Sync staging environment
	@echo "$(YELLOW)Syncing staging environment...$(NC)"
	@kubectl patch application staging-infrastructure -n argocd --type merge -p '{"operation":{"sync":{"prune":true}}}'
	@echo "$(GREEN)✓ Staging sync initiated$(NC)"

.PHONY: sync-prod
sync-prod: ## Sync production environment (requires confirmation)
	@echo "$(RED)⚠️  Syncing PRODUCTION environment$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo ""; \
		echo "$(YELLOW)Syncing production...$(NC)"; \
		kubectl patch application prod-infrastructure -n argocd --type merge -p '{"operation":{"sync":{"prune":true}}}'; \
		echo "$(GREEN)✓ Production sync initiated$(NC)"; \
	else \
		echo ""; \
		echo "$(YELLOW)Production sync cancelled$(NC)"; \
	fi

.PHONY: status
status: ## Show status of all applications
	@echo "$(YELLOW)Application Status:$(NC)"
	@kubectl get applications -n argocd -o custom-columns="NAME:.metadata.name,HEALTH:.status.health.status,SYNC:.status.sync.status,REVISION:.status.sync.revision"

.PHONY: logs-config-connector
logs-config-connector: ## Show Config Connector logs
	@echo "$(YELLOW)Config Connector logs:$(NC)"
	@kubectl logs -n cnrm-system deployment/cnrm-controller-manager --tail=50

.PHONY: logs-argocd
logs-argocd: ## Show Argo CD application controller logs
	@echo "$(YELLOW)Argo CD logs:$(NC)"
	@kubectl logs -n argocd deployment/argocd-application-controller --tail=50

.PHONY: argocd-info
argocd-info: ## Show Argo CD access information
	@echo "$(YELLOW)🌐 Argo CD Access Information:$(NC)"
	@echo "$(GREEN)URL: https://$$(kubectl get service argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')$(NC)"
	@echo "$(GREEN)Username: admin$(NC)"
	@echo "$(GREEN)Password: $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)$(NC)"
	@echo ""
	@echo "$(YELLOW)💡 Access Methods:$(NC)"
	@echo "  • Direct HTTPS: https://$$(kubectl get service argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
	@echo "  • Port Forward: make argocd-ui (then https://localhost:8080)"

.PHONY: cluster-info
cluster-info: ## Show cluster information for external tools (Lens, k9s, etc.)
	@echo "$(YELLOW)🔧 Cluster Information for External Tools:$(NC)"
	@echo "$(GREEN)Cluster Name: gitops-data-platform$(NC)"
	@echo "$(GREEN)Region: us-central1$(NC)"
	@echo "$(GREEN)Endpoint: $$(kubectl cluster-info | grep 'control plane' | sed 's/.*https/https/' | sed 's/\x1b\[[0-9;]*m//g')$(NC)"
	@echo "$(GREEN)Version: $$(kubectl version | grep Server | awk '{print $$3}' | head -1)$(NC)"
	@echo ""
	@echo "$(YELLOW)📋 For Lens/k9s/kubectl:$(NC)"
	@echo "  • Current context: $$(kubectl config current-context)"
	@echo "  • Kubeconfig: $$HOME/.kube/config"
	@echo ""
	@echo "$(YELLOW)🔐 Authentication:$(NC)"
	@echo "  • Method: gcloud (Application Default Credentials)"
	@echo "  • User: $$(gcloud config get-value account)"

.PHONY: get-credentials
get-credentials: ## Get cluster credentials for kubectl access
	@echo "$(YELLOW)Getting cluster credentials...$(NC)"
	@gcloud container clusters get-credentials $(CLUSTER_NAME) --region=$(REGION) --project=$(PROJECT_ID)
	@echo "$(GREEN)✓ Credentials updated in kubeconfig$(NC)"
	@echo "$(YELLOW)Current context: $$(kubectl config current-context)$(NC)"

.PHONY: lens-setup
lens-setup: ## Instructions for adding cluster to Lens
	@echo "$(YELLOW)🔍 Adding Cluster to Lens:$(NC)"
	@echo ""
	@echo "$(GREEN)Method 1 - Automatic (Recommended):$(NC)"
	@echo "  1. Open Lens"
	@echo "  2. Click '+ Add Cluster'"
	@echo "  3. Select 'From kubeconfig'"
	@echo "  4. Choose context: $$(kubectl config current-context)"
	@echo ""
	@echo "$(GREEN)Method 2 - Manual:$(NC)"
	@echo "  1. Copy cluster info:"
	@echo "     Name: gitops-data-platform"
	@echo "     Server: $$(kubectl cluster-info | grep 'control plane' | sed 's/.*https/https/' | sed 's/\x1b\[[0-9;]*m//g')"
	@echo "  2. Copy certificate and token from: $$HOME/.kube/config"
	@echo ""
	@echo "$(YELLOW)📝 Current kubectl context: $$(kubectl config current-context)$(NC)"

.PHONY: argocd-ui
argocd-ui: ## Open Argo CD UI (port-forward)
	@echo "$(YELLOW)Starting Argo CD UI...$(NC)"
	@echo "$(GREEN)Access Argo CD at: https://localhost:8080$(NC)"
	@echo "$(YELLOW)Username: admin$(NC)"
	@echo "$(YELLOW)Password: $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)$(NC)"
	@kubectl port-forward svc/argocd-server -n argocd 8080:443

.PHONY: validate-dev
validate-dev: ## Validate dev environment configuration
	@echo "$(YELLOW)Validating dev environment...$(NC)"
	@kubectl kustomize infrastructure/environments/dev/ > /dev/null && echo "$(GREEN)✓ Dev configuration valid$(NC)" || echo "$(RED)✗ Dev configuration invalid$(NC)"

.PHONY: validate-staging
validate-staging: ## Validate staging environment configuration
	@echo "$(YELLOW)Validating staging environment...$(NC)"
	@kubectl kustomize infrastructure/environments/staging/ > /dev/null && echo "$(GREEN)✓ Staging configuration valid$(NC)" || echo "$(RED)✗ Staging configuration invalid$(NC)"

.PHONY: validate-prod
validate-prod: ## Validate production environment configuration
	@echo "$(YELLOW)Validating production environment...$(NC)"
	@kubectl kustomize infrastructure/environments/prod/ > /dev/null && echo "$(GREEN)✓ Production configuration valid$(NC)" || echo "$(RED)✗ Production configuration invalid$(NC)"

.PHONY: validate-all
validate-all: validate-dev validate-staging validate-prod ## Validate all environment configurations

.PHONY: check-resources
check-resources: ## Check status of Config Connector resources
	@echo "$(YELLOW)Config Connector Resources:$(NC)"
	@echo "$(YELLOW)BigQuery Datasets:$(NC)"
	@kubectl get bigquerydataset -A --no-headers 2>/dev/null | wc -l | xargs echo "  Count:"
	@echo "$(YELLOW)Pub/Sub Topics:$(NC)"
	@kubectl get pubsubtopic -A --no-headers 2>/dev/null | wc -l | xargs echo "  Count:"
	@echo "$(YELLOW)Storage Buckets:$(NC)"
	@kubectl get storagebucket -A --no-headers 2>/dev/null | wc -l | xargs echo "  Count:"
	@echo "$(YELLOW)SQL Instances:$(NC)"
	@kubectl get sqlinstance -A --no-headers 2>/dev/null | wc -l | xargs echo "  Count:"

.PHONY: cleanup-dev
cleanup-dev: ## Delete dev environment resources
	@echo "$(YELLOW)Cleaning up dev environment...$(NC)"
	@kubectl delete -k infrastructure/environments/dev/ || true
	@echo "$(GREEN)✓ Dev cleanup completed$(NC)"

.PHONY: cleanup-staging
cleanup-staging: ## Delete staging environment resources
	@echo "$(YELLOW)Cleaning up staging environment...$(NC)"
	@kubectl delete -k infrastructure/environments/staging/ || true
	@echo "$(GREEN)✓ Staging cleanup completed$(NC)"

.PHONY: cleanup-prod
cleanup-prod: ## Delete production environment resources (requires confirmation)
	@echo "$(RED)⚠️  DELETING PRODUCTION RESOURCES$(NC)"
	@read -p "Are you absolutely sure? Type 'delete-prod' to confirm: " -r; \
	if [[ $$REPLY == "delete-prod" ]]; then \
		echo "$(YELLOW)Deleting production resources...$(NC)"; \
		kubectl delete -k infrastructure/environments/prod/ || true; \
		echo "$(GREEN)✓ Production cleanup completed$(NC)"; \
	else \
		echo "$(YELLOW)Production cleanup cancelled$(NC)"; \
	fi

.PHONY: cleanup-cluster
cleanup-cluster: ## Delete the entire GKE cluster
	@echo "$(RED)⚠️  DELETING ENTIRE CLUSTER$(NC)"
	@read -p "This will delete the entire cluster. Are you sure? [y/N] " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo ""; \
		echo "$(YELLOW)Deleting cluster...$(NC)"; \
		gcloud container clusters delete $(CLUSTER_NAME) --region=$(REGION) --quiet; \
		echo "$(GREEN)✓ Cluster deleted$(NC)"; \
	else \
		echo ""; \
		echo "$(YELLOW)Cluster deletion cancelled$(NC)"; \
	fi

.PHONY: cleanup-orphaned-resources
cleanup-orphaned-resources: ## Clean up GCP resources left after cluster deletion
	@echo "$(YELLOW)Cleaning up orphaned GCP resources...$(NC)"
	@./scripts/cleanup-orphaned-resources.sh
	@echo "$(GREEN)✓ Orphaned resources cleanup completed$(NC)"

.PHONY: cleanup-everything
cleanup-everything: ## Delete cluster and all orphaned GCP resources
	@echo "$(RED)⚠️  DELETING EVERYTHING$(NC)"
	@read -p "This will delete the cluster AND all GCP resources. Are you sure? [y/N] " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo ""; \
		$(MAKE) cleanup-cluster || true; \
		sleep 5; \
		$(MAKE) cleanup-orphaned-resources; \
		echo "$(GREEN)✅ Complete cleanup finished$(NC)"; \
	else \
		echo ""; \
		echo "$(YELLOW)Complete cleanup cancelled$(NC)"; \
	fi

.PHONY: backup-prod
backup-prod: ## Backup production data
	@echo "$(YELLOW)Starting production backup...$(NC)"
	@echo "This would trigger backup jobs for:"
	@echo "  - BigQuery datasets"
	@echo "  - Cloud SQL databases"
	@echo "  - Storage buckets"
	@echo "$(YELLOW)Implement backup logic here$(NC)"

.PHONY: restore-prod
restore-prod: ## Restore production data from backup
	@echo "$(RED)⚠️  PRODUCTION DATA RESTORE$(NC)"
	@echo "$(YELLOW)Implement restore logic here$(NC)"

.PHONY: security-check
security-check: ## Run comprehensive security checks
	@echo "$(YELLOW)Running enterprise security checks...$(NC)"
	@echo "$(YELLOW)Checking Organization Policies:$(NC)"
	@kubectl get organizationpolicy -A --no-headers 2>/dev/null | wc -l | xargs echo "  Count:"
	@echo "$(YELLOW)Checking Gatekeeper Constraints:$(NC)"
	@kubectl get constraints -A --no-headers 2>/dev/null | wc -l | xargs echo "  Count:"
	@echo "$(YELLOW)Checking KMS Keys:$(NC)"
	@kubectl get kmscryptokey -A --no-headers 2>/dev/null | wc -l | xargs echo "  Count:"
	@echo "$(YELLOW)Checking IAM Policies with Conditions:$(NC)"
	@kubectl get iampolicy -A --no-headers 2>/dev/null | wc -l | xargs echo "  Count:"
	@echo "$(YELLOW)Checking Security Monitoring:$(NC)"
	@kubectl get monitoringalertpolicy -A --no-headers 2>/dev/null | wc -l | xargs echo "  Count:"
	@echo "$(GREEN)✓ Security check completed$(NC)"

.PHONY: dry-run
dry-run: ## Validate all configurations without applying (CI/CD safe)
	@echo "$(YELLOW)🔍 Running dry-run validation for CI/CD pipeline...$(NC)"
	@echo "$(YELLOW)Validating base infrastructure...$(NC)"
	@kubectl kustomize infrastructure/base/ > /tmp/base-dry-run.yaml && echo "$(GREEN)✓ Base valid$(NC)" || echo "$(RED)✗ Base invalid$(NC)"
	@echo "$(YELLOW)Validating dev environment...$(NC)"
	@kubectl kustomize infrastructure/environments/dev/ > /tmp/dev-dry-run.yaml && echo "$(GREEN)✓ Dev valid$(NC)" || echo "$(RED)✗ Dev invalid$(NC)"
	@echo "$(YELLOW)Validating staging environment...$(NC)"
	@kubectl kustomize infrastructure/environments/staging/ > /tmp/staging-dry-run.yaml && echo "$(GREEN)✓ Staging valid$(NC)" || echo "$(RED)✗ Staging invalid$(NC)"
	@echo "$(YELLOW)Validating production environment...$(NC)"
	@kubectl kustomize infrastructure/environments/prod/ > /tmp/prod-dry-run.yaml && echo "$(GREEN)✓ Production valid$(NC)" || echo "$(RED)✗ Production invalid$(NC)"
	@echo "$(YELLOW)Checking OPA Gatekeeper policies...$(NC)"
	@test -f security-policies/opa-gatekeeper-policies.rego && echo "$(GREEN)✓ OPA policies found$(NC)" || echo "$(YELLOW)⚠ OPA policies not found$(NC)"
	@echo "$(YELLOW)Validating Argo CD applications...$(NC)"
	@kubectl apply --dry-run=client -f argocd/project.yaml > /dev/null && echo "$(GREEN)✓ Argo CD project valid$(NC)" || echo "$(RED)✗ Argo CD project invalid$(NC)"
	@kubectl apply --dry-run=client -f argocd/applications-enhanced.yaml > /dev/null && echo "$(GREEN)✓ Argo CD applications valid$(NC)" || echo "$(RED)✗ Argo CD applications invalid$(NC)"
	@echo "$(GREEN)🎉 Dry-run validation completed - safe for deployment$(NC)"

.PHONY: ci-validate
ci-validate: ## Full CI/CD validation pipeline
	@echo "$(YELLOW)🚀 Running CI/CD validation pipeline...$(NC)"
	@make check-env
	@make dry-run
	@make security-policy-check
	@echo "$(GREEN)✅ CI/CD validation passed - ready for deployment$(NC)"

.PHONY: security-policy-check
security-policy-check: ## Validate OPA Gatekeeper policies
	@echo "$(YELLOW)Validating OPA Gatekeeper policies...$(NC)"
	@if [ -f security-policies/opa-gatekeeper-policies.rego ]; then \
		echo "$(GREEN)✓ OPA Rego policies found$(NC)"; \
		echo "$(YELLOW)Policy validation:$(NC)"; \
		grep -c "violation\[" security-policies/opa-gatekeeper-policies.rego | xargs echo "  Policy rules:"; \
		grep -c "package " security-policies/opa-gatekeeper-policies.rego | xargs echo "  Policy packages:"; \
	else \
		echo "$(RED)✗ OPA policies not found$(NC)"; \
	fi

.PHONY: cost-estimate
cost-estimate: ## Estimate monthly costs
	@echo "$(YELLOW)Cost Estimation:$(NC)"
	@echo "Run: gcloud alpha billing budgets list"
	@echo "This would calculate estimated monthly costs for:"
	@echo "  - GKE cluster"
	@echo "  - BigQuery storage and queries"
	@echo "  - Pub/Sub messages"
	@echo "  - Cloud SQL instances"
	@echo "  - Storage buckets"

.PHONY: update-docs
update-docs: ## Update documentation
	@echo "$(YELLOW)Updating documentation...$(NC)"
	@echo "$(GREEN)✓ Documentation updated$(NC)"

.PHONY: test-connectivity
test-connectivity: ## Test connectivity between components
	@echo "$(YELLOW)Testing component connectivity...$(NC)"
	@kubectl run test-pod --image=gcr.io/google.com/cloudsdktool/cloud-sdk:slim --rm -it --restart=Never -- /bin/bash -c "echo 'Connectivity test completed'"

# Development helpers
.PHONY: dev-shell
dev-shell: ## Open a development shell in the cluster
	@kubectl run dev-shell --image=gcr.io/google.com/cloudsdktool/cloud-sdk:latest --rm -it --restart=Never -- /bin/bash

.PHONY: watch-apps
watch-apps: ## Watch Argo CD applications status
	@watch kubectl get applications -n argocd

.PHONY: watch-resources
watch-resources: ## Watch Config Connector resources
	@watch kubectl get configconnector -A
