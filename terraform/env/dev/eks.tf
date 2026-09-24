module "eks" {
  source = "../../modules/eks-cluster"

  cluster_name       = "retail-platform-dev"
  kubernetes_version = "1.36"
  cluster_role_arn   = aws_iam_role.eks_cluster_role.arn

  subnet_ids = [for subnet in aws_subnet.private : subnet.id]

  authentication_mode = "API_AND_CONFIG_MAP"

  access_entries = "arn:aws:iam::147723036683:user/ahmed"

  additional_security_group_ids = [
    aws_security_group.eks-sg.id
  ]

  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["197.42.74.172/32"]

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  log_retention_days = 30

  tags = {
    Name        = "retail-platform-dev"
    environment = "dev"
    project     = "retail-platform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy_attachment
  ]

}