output "launch_template_id" {
  description = "ID of the EC2 launch template used by the managed node group."
  value       = aws_launch_template.this.id
}

output "node_group_name" {
  description = "Name of the EKS managed node group."
  value       = aws_eks_node_group.this.node_group_name
}

output "node_group_arn" {
  description = "ARN of the EKS managed node group."
  value       = aws_eks_node_group.this.arn
}

output "node_group_status" {
  description = "Current status of the EKS managed node group."
  value       = aws_eks_node_group.this.status
}