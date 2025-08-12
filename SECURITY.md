# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |

## Reporting a Vulnerability

We take the security of this project seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### Reporting Process

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via:

1. **GitHub Security Advisories** (preferred)
   - Go to the repository's Security tab
   - Click "Report a vulnerability"
   - Provide detailed information about the vulnerability

2. **Email** (alternative)
   - Send an email with details about the vulnerability
   - Include steps to reproduce if possible
   - Provide your assessment of the severity

### What to Include

When reporting a vulnerability, please include:

- Type of issue (e.g., configuration vulnerability, privilege escalation, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### Response Timeline

- **Acknowledgment**: We will acknowledge receipt of your report within 48 hours
- **Initial Response**: We will provide an initial response within 5 business days
- **Resolution**: We aim to resolve critical vulnerabilities within 30 days

### Security Best Practices

This project follows these security principles:

#### Infrastructure Security
- Customer-managed encryption keys (CMEK) for all data at rest
- Private networking for all database connections
- Network security policies and firewall rules
- Workload Identity Federation for secure service-to-service authentication

#### Access Control
- Role-based access control (RBAC) for all resources
- Principle of least privilege
- Multi-environment isolation (dev/staging/prod)
- Service account security with minimal permissions

#### Configuration Security
- OPA Gatekeeper policies for runtime security
- Organization policies for resource constraints
- Security monitoring and alerting
- Regular security assessments

#### GitOps Security
- Git-based audit trail for all changes
- Branch protection rules
- Code review requirements
- Automated security scanning

### Known Security Considerations

#### Sensitive Data Handling
- All secrets must be managed through Google Secret Manager
- Environment variables are used for non-sensitive configuration
- Service account keys are never stored in the repository

#### Network Security
- All resources use private networking where possible
- Public IP addresses are avoided unless necessary
- VPC security controls are enforced

#### Monitoring and Alerting
- Security Command Center integration
- Audit logging for all resource changes
- Automated alerting for security policy violations

### Responsible Disclosure

We kindly ask that you:

- Allow us reasonable time to investigate and fix the issue before public disclosure
- Avoid accessing or modifying data that does not belong to you
- Do not perform testing that could degrade or impact the service
- Do not share information about the vulnerability with others until it has been resolved

### Recognition

We appreciate security researchers who help keep our project safe. If you report a valid vulnerability, we will:

- Acknowledge your contribution (with your permission)
- Keep you informed about the progress of fixing the issue
- Credit you in our release notes (if desired)

## Security Updates

Security updates will be released through:

- GitHub Security Advisories
- GitHub Releases with security tags
- Documentation updates in the repository

## Questions

If you have questions about this security policy, please create an issue with the "security" label or contact the maintainers.

---

**Thank you for helping keep this project secure!**
