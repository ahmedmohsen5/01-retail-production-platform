data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]


    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name               = "retail-platform-dev-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
  tags = {
    Name        = "retail-platform-dev-eks-cluster-role"
    environment = "dev"
    project     = "retail-platform"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_node_role" {
  name               = "retail-platform-dev-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json
  tags = {
    Name        = "retail-platform-dev-eks-node-role"
    environment = "dev"
    project     = "retail-platform"
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_ecr_pull_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

#--------------------------------------------pod identity---------------------------------


data "aws_iam_policy_document" "vpc_cni_pod_identity" {
  statement {
    sid    = "AllowEksPodIdentity"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = ["kube-system"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = ["aws-node"]
    }
  }
}

resource "aws_iam_role" "vpc_cni_pod_identity" {
  name               = "retail-platform-dev-vpc-cni-pod-identity-role"
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_pod_identity.json
  tags = {
    Name        = "retail-platform-dev-vpc-cni-pod-identity-role"
    environment = "dev"
    project     = "retail-platform"
  }
}

resource "aws_iam_role_policy_attachment" "vpc_cni_pod_identity" {
  role       = aws_iam_role.vpc_cni_pod_identity.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

#----------------------------ingress policy--------------------
data "aws_iam_policy_document" "aws_load_balancer_controller_pod_identity" {
  statement {
    sid    = "AllowEksPodIdentity"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-namespace"
      values   = ["kube-system"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes-service-account"
      values   = ["aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  name               = "retail-platform-dev-aws-load-balancer-controller-role"
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_pod_identity.json

  tags = {
    Name        = "retail-platform-dev-aws-load-balancer-controller-role"
    environment = "dev"
    project     = "retail-platform"
  }
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "retail-platform-dev-aws-load-balancer-controller-policy"
  description = "Permissions for AWS Load Balancer Controller v3.5.0"
  policy      = file("${path.module}/policies/aws-load-balancer-controller-v3.5.0.json")

  tags = {
    environment = "dev"
    project     = "retail-platform"
  }
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

resource "aws_eks_pod_identity_association" "aws_load_balancer_controller" {
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.aws_load_balancer_controller.arn

  tags = {
    environment = "dev"
    project     = "retail-platform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.aws_load_balancer_controller
  ]
}
