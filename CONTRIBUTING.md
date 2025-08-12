# Contributing to GKE Config Connector GitOps Platform

Thank you for your interest in contributing to this project! This document provides guidelines for contributing to the GKE Config Connector GitOps Platform.

## 🚀 Getting Started

### Prerequisites

- GCP account with billing enabled
- Basic knowledge of Kubernetes, GitOps, and GCP services
- Familiarity with Argo CD and Config Connector

### Setting Up Your Development Environment

1. **Fork the repository**
   ```bash
   # Fork this repository on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/gke-config-connector.git
   cd gke-config-connector
   ```

2. **Configure your environment**
   ```bash
   # Copy and configure environment variables
   cp .env.example .env.local
   # Edit .env.local with your actual values
   ```

3. **Update configuration files**
   - Update `Makefile` with your repository URL
   - Update `argocd/applications-enhanced.yaml` with your repository URL

## 📝 How to Contribute

### Types of Contributions

We welcome the following types of contributions:

1. **Infrastructure Improvements**
   - New GCP resource configurations
   - Enhanced security policies
   - Performance optimizations

2. **Documentation**
   - README improvements
   - New guides and tutorials
   - API documentation

3. **Bug Fixes**
   - Configuration errors
   - Script improvements
   - Security vulnerabilities

4. **Features**
   - New environments (beyond dev/staging/prod)
   - Additional monitoring capabilities
   - CI/CD pipeline enhancements

### Contribution Process

1. **Create an Issue**
   - Describe the problem or feature request
   - Provide context and use cases
   - Wait for feedback before starting work

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

3. **Make Changes**
   - Follow the existing code style
   - Test your changes thoroughly
   - Update documentation if needed

4. **Test Your Changes**
   ```bash
   # Validate configurations
   make validate-all
   
   # Test in development environment
   make setup-all
   make deploy-infrastructure
   ```

5. **Submit a Pull Request**
   - Provide a clear description of changes
   - Reference any related issues
   - Include screenshots if applicable

## 🔒 Security Guidelines

### Sensitive Information

- **NEVER** commit secrets, tokens, or credentials
- **ALWAYS** use environment variables for sensitive data
- Review the `.gitignore` file before committing

### Security Best Practices

- Follow principle of least privilege for IAM roles
- Use customer-managed encryption keys (CMEK) where applicable
- Implement proper network security controls
- Regular security scanning and updates

## 📋 Code Standards

### YAML Files

- Use 2-space indentation
- Include proper labels and annotations
- Follow Kubernetes naming conventions
- Add comments for complex configurations

### Shell Scripts

- Use `/bin/bash` shebang
- Include error handling
- Add descriptive comments
- Follow Google Shell Style Guide

### Documentation

- Use clear, concise language
- Include code examples
- Keep documentation up-to-date
- Follow Markdown best practices

## 🧪 Testing

### Local Testing

1. **Configuration Validation**
   ```bash
   make validate-all
   ```

2. **Resource Deployment**
   ```bash
   make setup-all
   make deploy-infrastructure
   ```

3. **Security Policy Testing**
   ```bash
   kubectl apply -f security-policies/
   ```

### CI/CD Testing

- All pull requests trigger automated validation
- Security policies are tested automatically
- Documentation is validated for markdown errors

## 🎯 Project Structure

```
├── infrastructure/          # Infrastructure as Code
│   ├── base/               # Base resource templates
│   └── environments/       # Environment-specific configs
├── argocd/                 # GitOps application definitions
├── scripts/                # Automation scripts
├── security-policies/      # OPA Gatekeeper policies
├── docs/                   # Additional documentation
└── monitoring/             # Monitoring configurations
```

## 🤝 Community

### Communication

- Use GitHub Issues for bug reports and feature requests
- Start discussions in GitHub Discussions
- Be respectful and constructive in all interactions

### Code of Conduct

- Be welcoming and inclusive
- Respect different viewpoints and experiences
- Focus on what is best for the community
- Show empathy towards other community members

## 📚 Resources

- [GKE Config Connector Documentation](https://cloud.google.com/config-connector/docs)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Google Cloud Documentation](https://cloud.google.com/docs)

## ❓ Questions?

If you have questions about contributing, please:

1. Check existing issues and documentation
2. Create a new issue with the "question" label
3. Provide as much context as possible

Thank you for contributing to make this project better! 🎉
