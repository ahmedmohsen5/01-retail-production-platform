data "aws_iam_policy_document" "ebs_csi_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = ["kube-system"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = ["ebs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "retail-platform-dev-ebs-csi"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_policy.json
  tags               = local.addon_tags

}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name = module.eks.cluster_name
  addon_name   = "aws-ebs-csi-driver"
  pod_identity_association {
    service_account = "ebs-csi-controller-sa"
    role_arn        = aws_iam_role.ebs_csi.arn
  }
  tags = local.addon_tags
  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi,
    aws_eks_addon.pod_identity_agent
  ]
}