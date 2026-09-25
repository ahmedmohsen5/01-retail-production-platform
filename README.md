# Retail Production Platform

A production-oriented DevOps / Platform Engineering project built around the AWS Retail Store Sample App as the application workload.

The purpose of this repository is to design and build the infrastructure, delivery platform, security controls, observability, and operational practices independently rather than reuse an existing DevOps implementation.

## Start the AWS project

From PowerShell, run:

```powershell
.\start_project.ps1
```

Before the first run, commit and push the updated workflow in
`.github/workflows/aws-identity-test.yml` to `main`. Install AWS CLI, Terraform,
GitHub CLI, and kubectl; authenticate AWS and run `gh auth login`. Your GitHub
account needs permission to dispatch workflows and set repository variables.
The script builds the application committed on remote `main`; local application
changes must be pushed first.

The existing S3 state backend in `terraform/env/dev/backend.hcl` and GitHub OIDC
provider must already exist. The AWS identity must have infrastructure permissions
and EKS access (currently configured in `terraform/env/dev/eks.tf`). This command
creates or updates billable AWS infrastructure and automatically applies the
Terraform plan.

The script detects your public IPv4 address, writes the ignored
`terraform/env/dev/startup.auto.tfvars.json`, initializes and applies Terraform,
sets the GitHub AWS variables, and starts the image publishing workflow. After
that exact build succeeds, it verifies the five ECR images, replaces image tags in
the Kubernetes deployment files, updates kubeconfig, applies the manifests, and
waits for all deployments to roll out. Native command failures stop the script.
The final output lists pods and services; a load balancer address may take longer
to appear. Each run publishes a new set of images.

Optional overrides:

```powershell
.\start_project.ps1 -PublicIp '203.0.113.10' -BuildTimeoutMinutes 90
.\start_project.ps1 -BackendConfig 'C:\config\dev-backend.hcl'
```

Use your actual public IP for `-PublicIp`. Relative backend paths resolve under
`terraform/env/dev`. A build timeout stops local deployment but does not cancel
the GitHub run. The script leaves generated image changes available for review
and does not commit or push them. Direct Terraform runs also require
`eks_public_access_cidrs`, through the generated file or your own variable file.

## Destroy the dev project

```powershell
.\destroy_project.ps1
```

This command automatically destroys the dev Terraform stack and permanently
deletes all images in its ECR repositories. It checks the AWS account, generates
a destroy plan, removes retail Kubernetes services and ingresses while the load
balancer controller is still running, deletes the retail namespace, and removes
the infrastructure. It also works after a partial destroy. Failures stop the
script; fix the reported issue and rerun it.

Use the same AWS credentials and backend as startup. AWS CLI and Terraform are
required; kubectl and working EKS API access are required if the cluster still
exists. Stop any running startup or image publishing workflow before teardown.
Resources created manually outside Terraform and outside the retail namespace
are not covered. The source files, bootstrap state bucket, shared GitHub OIDC
provider, and GitHub repository remain available for the next startup.

Optional: `-BackendConfig 'C:\config\dev-backend.hcl'`. Account and region
defaults are `147723036683` and `us-east-1`; use `-ExpectedAccountId` and `-Region`
only when targeting a different configured dev environment.

## Platform goals

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

