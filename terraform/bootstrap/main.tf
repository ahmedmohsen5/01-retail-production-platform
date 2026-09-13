data "aws_caller_identity" "current" {}

locals {
  state_bucket_name = "${var.project_name}-${data.aws_caller_identity.current.account_id}-${var.aws_region}-state"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = local.state_bucket_name
  force_destroy = false

  tags = {
    Name        = local.state_bucket_name
    Environment = "production"
    Project     = var.project_name
    managed_by  = "terraform"
  }
  lifecycle {
    prevent_destroy = false
  }
}

