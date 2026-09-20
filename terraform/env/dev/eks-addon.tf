locals {
  eks_addon_versions = {
    eks_pod_identity_agent = "v1.3.10-eksbuild.3"
    vpc_cni                = "v1.22.4-eksbuild.3"
    coredns                = "v1.14.3-eksbuild.23"
    kube_proxy             = "v1.36.0-eksbuild.25"
  }
  addon_tags = {
    environment = "dev"
    project     = "retail-platform"
  }
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "eks-pod-identity-agent"
  addon_version = local.eks_addon_versions.eks_pod_identity_agent

  tags = local.addon_tags
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = module.eks.cluster_name
  addon_name    = "vpc-cni"
  addon_version = local.eks_addon_versions.vpc_cni

  pod_identity_association {
    service_account = "aws-node"
    role_arn        = aws_iam_role.vpc_cni_pod_identity.arn
  }

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = local.addon_tags
  depends_on = [
    aws_iam_role_policy_attachment.vpc_cni_pod_identity
  ]
}

resource "aws_eks_addon" "core" {
  for_each = {
    coredns    = local.eks_addon_versions.coredns
    kube-proxy = local.eks_addon_versions.kube_proxy
  }
  cluster_name  = module.eks.cluster_name
  addon_name    = each.key
  addon_version = each.value

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = local.addon_tags
}