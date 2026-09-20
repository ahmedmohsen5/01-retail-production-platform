module "eks_managed_node_group" {
  source = "../../modules/eks-managed-node-group"

  cluster_name    = module.eks.cluster_name
  cluster_version = module.eks.kubernetes_version
  node_group_name = "retail-platform-dev-general"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    for subnet in aws_subnet.private : subnet.id
  ]

  security_group_ids = [
    module.eks.cluster_security_group_id, aws_security_group.eks-node-sg.id
  ]

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  instance_types = ["c7i-flex.large"]

  min_size     = 1
  desired_size = 2
  max_size     = 3
  disk_size    = 20

  max_unavailable     = 1
  node_repair_enabled = true

  labels = {
    role        = "general"
    environment = "dev"
  }

  tags = {
    environment = "dev"
    project     = "retail-platform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy_attachment,
    aws_iam_role_policy_attachment.eks_node_ecr_pull_policy,
    aws_route.private_nat,
    aws_route_table_association.private
  ]
}