data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

locals {
  github_oidc_subject = "repo:ahmedmohsen5@36478683/01-retail-production-platform@1357361143:ref:refs/heads/main"
}


data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_oidc_subject]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "retail-platform-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
  tags = {
    Name        = "retail-platform-github-actions-role"
    environment = "dev"
    project     = "retail-platform"
  }
}



