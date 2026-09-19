output "cluster_name" {
  description = "Name of the Amazon EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the Amazon EKS cluster."
  value       = aws_eks_cluster.this.arn
}

output "kubernetes_version" {
  description = "Kubernetes version used by the Amazon EKS control plane."
  value       = aws_eks_cluster.this.version
}

output "endpoint" {
  description = "Endpoint URL of the Amazon EKS API server."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_security_group_id" {
  description = "ID of the cluster security group created and managed by Amazon EKS."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
