variable "cluster_name" {
  description = "Name of the existing Amazon EKS cluster."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version used by the Amazon EKS cluster and managed node group."
  type        = string
}

variable "node_group_name" {
  description = "Name of the Amazon EKS managed node group."
  type        = string
}

variable "ami_type" {
  description = "Amazon EKS optimized AMI type used by the managed node group."
  type        = string
}

variable "capacity_type" {
  description = "Capacity purchasing model used by the managed node group, such as ON_DEMAND or SPOT."
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the existing IAM role assumed by the Amazon EKS worker nodes."
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the private subnets where the managed worker nodes are deployed."
  type        = list(string)
}

variable "security_group_ids" {
  description = "IDs of the security groups attached to worker nodes through the launch template."
  type        = list(string)
}

variable "instance_types" {
  description = "EC2 instance types permitted for the managed node group."
  type        = list(string)
}

variable "min_size" {
  description = "Minimum number of worker nodes maintained by the managed node group."
  type        = number
}

variable "desired_size" {
  description = "Desired number of worker nodes in the managed node group."
  type        = number

  validation {
    condition = (
      var.min_size <= var.desired_size &&
      var.desired_size <= var.max_size
    )
    error_message = "Scaling must satisfy min_size <= desired_size <= max_size."
  }
}

variable "max_size" {
  description = "Maximum number of worker nodes allowed in the managed node group."
  type        = number
}

variable "disk_size" {
  description = "Size in GiB of the root EBS volume configured for each worker node."
  type        = number
}

variable "labels" {
  description = "Kubernetes labels applied to nodes in the managed node group."
  type        = map(string)
}

variable "tags" {
  description = "Tags applied to resources created by the managed node-group module."
  type        = map(string)
}

variable "max_unavailable" {
  description = "Maximum number of unavailable nodes during a managed node-group update."
  type        = number

  validation {
    condition     = var.max_unavailable >= 1
    error_message = "max_unavailable must be at least 1."
  }
}

variable "node_repair_enabled" {
  description = "Whether EKS managed node auto-repair is enabled."
  type        = bool
}