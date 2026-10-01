# Security validation

PR validation fails on exposed secrets, fixable HIGH/CRITICAL dependency vulnerabilities,
and HIGH/CRITICAL Terraform or Kubernetes misconfigurations. Keep these gates enabled.
Download the `trivy-*` artifacts from a failed run to identify packages, fixed versions,
and affected resources before updating dependencies.

Dependency changes must include regenerated `go.sum` and `yarn.lock` files. Maven uses
Spring Boot 3.5.16 with explicit overrides for fixes newer than its dependency BOM.
Java runtime images install available Ubuntu security updates; PR builds pull current
base images and rebuild runtime stages to avoid stale OS package caches. The checkout
runtime removes npm/corepack because it runs compiled JS
without a package manager, avoiding unused package-manager dependency vulnerabilities.

## Infrastructure

Terraform state and EKS secrets use customer-managed KMS keys with rotation enabled.
Before applying the bootstrap change, grant any non-admin Terraform backend principals
`kms:Encrypt`, `kms:Decrypt`, and `kms:GenerateDataKey` on the `state_kms_key_arn` output.
Existing state object versions retain their previous encryption until rewritten.
These changes require Terraform apply; validation alone does not update AWS.

Two resource-local Trivy exceptions preserve the development network design:

- `AWS-0104`: worker-node egress permits TCP/443 through NAT for public image registries
  and service APIs. Replace with VPC endpoints/an egress proxy before removing this exception.
- `AWS-0040`: operators outside the VPC use the EKS public API. Both the environment
  and cluster module validate IPv4 allowlists; unrestricted `/0` access is rejected.
  Private endpoint access remains enabled. Remove this exception once operators use
  private connectivity.

Public subnets no longer assign instance public IPs automatically; NAT gateways retain
explicit Elastic IPs. Workload pods run as UID/GID 10001, drop all capabilities, forbid
privilege escalation, and use read-only root filesystems with writable `/tmp` volumes.

## Reproduce

```sh
terraform fmt -check -recursive terraform/
terraform -chdir=terraform/bootstrap validate
terraform -chdir=terraform/env/dev validate
trivy config --severity HIGH,CRITICAL --exit-code 1 terraform
trivy config --severity HIGH,CRITICAL --exit-code 1 k8s
trivy fs --scanners vuln --severity HIGH,CRITICAL --offline-scan --ignore-unfixed --exit-code 1 .
trivy fs --scanners secret --offline-scan --exit-code 1 .
```

Build each image with the Dockerfile/context used by PR validation, then run
`trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 IMAGE`.

## Local verification of this remediation

Passed: Terraform format/validation (bootstrap and dev), Trivy HIGH/CRITICAL Terraform
and Kubernetes gates, repository secret scanning, checkout lint/build and immutable
Yarn installation, and container-selector tests.

Java/Go build verification and final vulnerability scans remain unconfirmed: local
Docker builds exhausted host memory and the Docker engine stopped responding. The
vulnerability database download also exceeded its initial five-minute timeout.
Rerun PR validation after pushing; the security gates remain mandatory.
