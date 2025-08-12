# GitOps CI/CD Pipeline Examples

## GitHub Actions Workflow

### `.github/workflows/infrastructure-ci.yml`

```yaml
name: Infrastructure CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'infrastructure/**'
      - 'argocd/**'
      - 'scripts/**'
  pull_request:
    branches: [ main ]
    paths:
      - 'infrastructure/**'
      - 'argocd/**'
      - 'scripts/**'

env:
  PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  GCP_SA_KEY: ${{ secrets.GCP_SA_KEY }}
  
jobs:
  validate:
    name: Validate Infrastructure
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Google Cloud CLI
      uses: google-github-actions/setup-gcloud@v1
      with:
        service_account_key: ${{ secrets.GCP_SA_KEY }}
        project_id: ${{ secrets.GCP_PROJECT_ID }}
        
    - name: Setup kubectl
      uses: azure/setup-kubectl@v3
      with:
        version: 'v1.28.0'
        
    - name: Validate configurations
      run: |
        make dry-run
        
    - name: Security policy validation
      run: |
        make security-policy-check
        
    - name: Run comprehensive validation
      run: |
        make ci-validate

  security-scan:
    name: Security Scanning
    runs-on: ubuntu-latest
    needs: validate
    steps:
    - uses: actions/checkout@v4
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'config'
        scan-ref: 'infrastructure/'
        format: 'sarif'
        output: 'trivy-results.sarif'
        
    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
        
    - name: OPA Policy Testing
      run: |
        # Install OPA
        curl -L -o opa https://github.com/open-policy-agent/opa/releases/download/v0.55.0/opa_linux_amd64_static
        chmod +x opa
        sudo mv opa /usr/local/bin/
        
        # Test policies
        opa test security-policies/

  deploy-dev:
    name: Deploy to Development
    runs-on: ubuntu-latest
    needs: [validate, security-scan]
    if: github.ref == 'refs/heads/develop'
    environment: development
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Google Cloud CLI
      uses: google-github-actions/setup-gcloud@v1
      with:
        service_account_key: ${{ secrets.GCP_SA_KEY }}
        project_id: ${{ secrets.GCP_PROJECT_ID }}
        
    - name: Get GKE credentials
      run: |
        gcloud container clusters get-credentials gitops-data-platform --region us-central1
        
    - name: Deploy to development
      run: |
        kubectl apply -k infrastructure/environments/dev/
        
    - name: Verify deployment
      run: |
        kubectl wait --for=condition=Ready --timeout=300s -k infrastructure/environments/dev/

  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: [validate, security-scan]
    if: github.ref == 'refs/heads/main'
    environment: staging
    steps:
    - uses: actions/checkout@v4
    
    - name: Manual approval required
      uses: trstringer/manual-approval@v1
      with:
        secret: ${{ github.TOKEN }}
        approvers: platform-team,security-team
        
    - name: Deploy to staging
      run: |
        make sync-staging

  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
    - uses: actions/checkout@v4
    
    - name: Security team approval
      uses: trstringer/manual-approval@v1
      with:
        secret: ${{ github.TOKEN }}
        approvers: security-admin,ciso
        minimum-approvals: 2
        
    - name: Deploy to production
      run: |
        make sync-prod
        
    - name: Post-deployment verification
      run: |
        make security-check
        make status
```

## GitLab CI Pipeline

### `.gitlab-ci.yml`

```yaml
stages:
  - validate
  - security
  - deploy-dev
  - deploy-staging
  - deploy-production

variables:
  PROJECT_ID: $GCP_PROJECT_ID
  CLUSTER_NAME: gitops-data-platform
  REGION: us-central1

validate:
  stage: validate
  image: google/cloud-sdk:alpine
  before_script:
    - apk add --no-cache make
    - echo $GCP_SA_KEY | base64 -d > /tmp/gcp-key.json
    - gcloud auth activate-service-account --key-file /tmp/gcp-key.json
    - gcloud config set project $PROJECT_ID
  script:
    - make dry-run
    - make security-policy-check
    - make ci-validate
  rules:
    - changes:
        - infrastructure/**/*
        - argocd/**/*
        - scripts/**/*

security-scan:
  stage: security
  image: aquasec/trivy:latest
  script:
    - trivy config --format table infrastructure/
    - trivy config --format json infrastructure/ > security-report.json
  artifacts:
    reports:
      security: security-report.json
    expire_in: 1 week
  rules:
    - changes:
        - infrastructure/**/*

deploy-dev:
  stage: deploy-dev
  image: google/cloud-sdk:alpine
  before_script:
    - apk add --no-cache make
    - echo $GCP_SA_KEY | base64 -d > /tmp/gcp-key.json
    - gcloud auth activate-service-account --key-file /tmp/gcp-key.json
    - gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION
  script:
    - kubectl apply -k infrastructure/environments/dev/
  environment:
    name: development
    url: https://dev.data-platform.example.com
  rules:
    - if: $CI_COMMIT_BRANCH == "develop"

deploy-staging:
  stage: deploy-staging
  image: google/cloud-sdk:alpine
  script:
    - make sync-staging
  environment:
    name: staging
    url: https://staging.data-platform.example.com
  when: manual
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

deploy-production:
  stage: deploy-production
  image: google/cloud-sdk:alpine
  script:
    - make sync-prod
  environment:
    name: production
    url: https://data-platform.example.com
  when: manual
  only:
    variables:
      - $SECURITY_APPROVAL == "approved"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

## Azure DevOps Pipeline

### `azure-pipelines.yml`

```yaml
trigger:
  branches:
    include:
    - main
    - develop
  paths:
    include:
    - infrastructure/*
    - argocd/*
    - scripts/*

pool:
  vmImage: 'ubuntu-latest'

variables:
  PROJECT_ID: $(GCP_PROJECT_ID)
  CLUSTER_NAME: 'gitops-data-platform'
  REGION: 'us-central1'

stages:
- stage: Validate
  displayName: 'Validate Infrastructure'
  jobs:
  - job: ValidateConfigs
    displayName: 'Validate Configurations'
    steps:
    - task: GoogleCloudSdkTool@0
      inputs:
        connectionType: 'JsonFile'
        jsonFile: '$(GCP_SA_KEY_FILE)'
        
    - script: |
        make dry-run
        make security-policy-check
        make ci-validate
      displayName: 'Run validation pipeline'

- stage: Security
  displayName: 'Security Scanning'
  dependsOn: Validate
  jobs:
  - job: SecurityScan
    displayName: 'Security Scanning'
    steps:
    - script: |
        # Install Trivy
        sudo apt-get update
        sudo apt-get install wget apt-transport-https gnupg lsb-release
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
        echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
        sudo apt-get update
        sudo apt-get install trivy
        
        # Scan infrastructure
        trivy config infrastructure/
      displayName: 'Run Trivy security scan'

- stage: DeployDev
  displayName: 'Deploy Development'
  dependsOn: [Validate, Security]
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/develop'))
  jobs:
  - deployment: DeployToDev
    displayName: 'Deploy to Development'
    environment: 'development'
    strategy:
      runOnce:
        deploy:
          steps:
          - script: |
              gcloud container clusters get-credentials $(CLUSTER_NAME) --region $(REGION)
              kubectl apply -k infrastructure/environments/dev/
            displayName: 'Deploy to dev environment'

- stage: DeployStaging
  displayName: 'Deploy Staging'
  dependsOn: [Validate, Security]
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: DeployToStaging
    displayName: 'Deploy to Staging'
    environment: 'staging'
    strategy:
      runOnce:
        deploy:
          steps:
          - script: make sync-staging
            displayName: 'Deploy to staging environment'

- stage: DeployProduction
  displayName: 'Deploy Production'
  dependsOn: DeployStaging
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: DeployToProduction
    displayName: 'Deploy to Production'
    environment: 'production'
    strategy:
      runOnce:
        deploy:
          steps:
          - script: |
              make sync-prod
              make security-check
            displayName: 'Deploy to production environment'
```

## Jenkins Pipeline

### `Jenkinsfile`

```groovy
pipeline {
    agent any
    
    environment {
        PROJECT_ID = credentials('gcp-project-id')
        GCP_SA_KEY = credentials('gcp-service-account-key')
        CLUSTER_NAME = 'gitops-data-platform'
        REGION = 'us-central1'
    }
    
    stages {
        stage('Validate') {
            steps {
                script {
                    sh 'make dry-run'
                    sh 'make security-policy-check'
                    sh 'make ci-validate'
                }
            }
        }
        
        stage('Security Scan') {
            parallel {
                stage('Trivy Scan') {
                    steps {
                        sh 'trivy config infrastructure/'
                    }
                }
                stage('OPA Policy Test') {
                    steps {
                        sh 'opa test security-policies/'
                    }
                }
            }
        }
        
        stage('Deploy Dev') {
            when {
                branch 'develop'
            }
            steps {
                sh 'kubectl apply -k infrastructure/environments/dev/'
            }
        }
        
        stage('Deploy Staging') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to staging?', ok: 'Deploy'
                sh 'make sync-staging'
            }
        }
        
        stage('Deploy Production') {
            when {
                allOf {
                    branch 'main'
                    expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
                }
            }
            steps {
                input message: 'Deploy to production? Requires security team approval.', 
                      ok: 'Deploy',
                      submitterParameter: 'APPROVER'
                      
                script {
                    if (env.APPROVER in ['security-admin', 'platform-admin']) {
                        sh 'make sync-prod'
                        sh 'make security-check'
                    } else {
                        error('Deployment to production requires security team approval')
                    }
                }
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'security-reports/*.md', allowEmptyArchive: true
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'security-reports',
                reportFiles: '*.html',
                reportName: 'Security Report'
            ])
        }
        failure {
            emailext (
                subject: "GitOps Pipeline Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "Pipeline failed. Check console output at ${env.BUILD_URL}",
                to: "${env.TEAM_EMAIL}"
            )
        }
    }
}
```

## Local Development Workflow

### Pre-commit Hooks

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running pre-commit validation..."

# Validate configurations
make dry-run || exit 1

# Security policy check
make security-policy-check || exit 1

# Format check
kubectl kustomize infrastructure/base/ > /dev/null || exit 1

echo "✅ Pre-commit validation passed"
```

## Summary

These CI/CD pipelines provide:

- ✅ **Automated validation** on every commit
- 🔒 **Security scanning** with Trivy and OPA
- 🎯 **Environment progression** (dev → staging → prod)
- 👥 **Approval workflows** for production deployments
- 📊 **Artifact archiving** and reporting
- 🚨 **Notification** on failures
- 🔄 **GitOps integration** with Argo CD
