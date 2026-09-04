# Retail Production Platform

A production-oriented DevOps / Platform Engineering project built around the AWS Retail Store Sample App as the application workload.

The purpose of this repository is to design and build the infrastructure, delivery platform, security controls, observability, and operational practices independently rather than reuse an existing DevOps implementation.

## Project Goal

Build a complete production delivery path for a realistic microservices application, including:

- Containerization
- Infrastructure as Code
- AWS infrastructure
- Kubernetes / Amazon EKS
- CI pipelines
- GitOps continuous delivery
- Security and IAM
- Observability
- Reliability testing
- Troubleshooting and operational documentation

## Application Source

The application workload is based on the open-source **AWS Retail Store Sample App** maintained by AWS.

Upstream repository:

`https://github.com/aws-containers/retail-store-sample-app`

Baseline commit used for this project:

`1a28474f2461459f42e6b393db59e7d1434d4aec`

The upstream application is licensed under the MIT-0 License.

Upstream copyright and license information are preserved under:

`third-party/aws-retail-store-sample-app/LICENSE`

See `UPSTREAM.md` for provenance details.

## DevOps / Platform Work Built by Me

The DevOps and Platform Engineering implementation in this repository is designed and built independently as part of this project.

This includes, as the project develops:

- Docker build strategy
- Terraform infrastructure
- AWS networking and IAM
- Amazon EKS platform configuration
- GitHub Actions CI
- Amazon ECR image delivery
- Argo CD / GitOps deployment
- Kubernetes manifests and platform configuration
- Security controls
- Prometheus / Grafana / Loki observability
- Health checks and reliability controls
- Failure testing and troubleshooting
- Architecture and operational documentation

The upstream application's existing infrastructure or deployment implementation is not treated as my own work.

## Current Phase

**Phase 1 — Baseline & Architecture**

Current objective:

Establish repository provenance, attribution, ownership boundaries, and the initial engineering baseline before implementing the platform.

## Repository Structure

```text
01-retail-production-platform/
├── README.md
├── UPSTREAM.md
└── third-party/
    └── aws-retail-store-sample-app/
        └── LICENSE
```

The repository structure will evolve as infrastructure, CI/CD, Kubernetes, observability, and operational components are implemented.

## Engineering Principle

Application code provides the workload.

The DevOps / Platform Engineering solution is the work being designed, implemented, validated, and documented in this repository.
