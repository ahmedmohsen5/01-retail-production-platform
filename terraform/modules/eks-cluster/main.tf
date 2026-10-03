resource "aws_cloudwatch_log_group" "eks_control_plane" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_kms_key" "eks_secrets" {
  description             = "Encrypt ${var.cluster_name} Kubernetes secrets"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  tags                    = var.tags
}


resource "aws_eks_cluster" "this" {
  name                      = var.cluster_name
  role_arn                  = var.cluster_role_arn
  version                   = var.kubernetes_version
  enabled_cluster_log_types = var.enabled_cluster_log_types
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks_secrets.arn
    }
  }
  access_config {
    authentication_mode = var.authentication_mode
  }
  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = var.additional_security_group_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }
  tags = var.tags

  depends_on = [aws_cloudwatch_log_group.eks_control_plane]
}

resource "aws_eks_access_entry" "admin" {
  cluster_name  = var.cluster_name
  principal_arn = var.access_entries

  type       = "STANDARD"
  depends_on = [aws_eks_cluster.this]
}

resource "aws_eks_access_policy_association" "admin_assoc" {
  access_scope {
    type = "cluster"
  }
  cluster_name  = var.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.admin.principal_arn
  depends_on    = [aws_eks_access_entry.admin]
}