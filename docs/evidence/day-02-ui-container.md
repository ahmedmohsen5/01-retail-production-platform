# Day 02 - Build and Run UI Container From Source

## Source
Upstream repository: https://github.com/aws-containers/retail-store-sample-app
Upstream commit: 1a28474f2461459f42e6b393db59e7d1434d4aec

## Ownership Rule
Only application source code and API contracts came from upstream.
The Dockerfile used for this test was created in this repository from scratch.
No upstream Dockerfile, Docker Compose, Kubernetes, Helm, Terraform, or CI/CD implementation was used to complete this task.

## Build
Image tag: retail-ui:local-v1
Image ID: sha256:26a031e4dcf5dd2041bcb74e83599e483bf9c903bd124f34cbdd22e19415a2c2
Dockerfile: docker/ui/Dockerfile

## Runtime
retail-ui | retail-ui:local-v1 | Up 2 minutes | 0.0.0.0:8888->8080/tcp, [::]:8888->8080/tcp

## Validation
URL: http://localhost:8888
HTTP status: 200
Browser check: PASS

## Result
PASS - The UI application was built from source with our Dockerfile and ran successfully as our local Docker image.