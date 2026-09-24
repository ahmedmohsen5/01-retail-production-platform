# Publish images to Amazon ECR

The `AWS Identity and Image Publish` workflow in
`.github/workflows/aws-identity-test.yml` runs manually. After the AWS identity
check succeeds, it builds UI, catalog, cart, orders, and checkout in parallel
using `application/` as the Docker build context, then pushes each image to its
matching `retail-<service>` ECR repository.

Before the first run:

1. Review and apply the Terraform changes in `terraform/env/dev` to create the
   ECR repositories and grant the GitHub Actions role permission to push images.
2. Configure GitHub repository Actions variables `AWS_ROLE_ARN`,
   `AWS_ACCOUNT_ID`, and `AWS_REGION` for that role and those repositories.
3. Commit and push the workflow, then select **Actions → AWS Identity and Image
   Publish → Run workflow** on `main`. The configured OIDC trust permits `main`.

Images use the tag `<commit-sha>-<run-id>-<run-attempt>`, so repeated runs do not
overwrite immutable ECR tags. Each successful matrix job writes the full image
URI to the workflow summary. Use those URIs when updating Kubernetes manifests;
this workflow only publishes images and does not deploy them.

The role policy scopes image push operations to the five service repositories.
ECR authentication requires `ecr:GetAuthorizationToken` on `*`, as described in
the [AWS ECR push permissions documentation](https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-push-iam.html).
