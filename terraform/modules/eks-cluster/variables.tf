variable "cluster_name" {
  description = "Name of the Amazon EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version used by the Amazon EKS control plane."
  type        = string
}

variable "cluster_role_arn" {
  description = "ARN of the existing IAM role used by the Amazon EKS control plane."
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the subnets used by the Amazon EKS control plane."
  type        = list(string)
}

variable "additional_security_group_ids" {
  description = "IDs of additional security groups associated with the Amazon EKS control plane."
  type        = list(string)
}

variable "endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled."
  type        = bool
}

variable "endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled."
  type        = bool
}

variable "public_access_cidrs" {
  description = "CIDR blocks permitted to reach the public Amazon EKS API server endpoint."
  type        = list(string)
}

variable "enabled_cluster_log_types" {
  description = "Amazon EKS control-plane log types enabled for the cluster."
  type        = set(string)
}

variable "log_retention_days" {
  description = "Number of days to retain Amazon EKS control-plane logs in CloudWatch Logs."
  type        = number
}

variable "tags" {
  description = "Tags applied to resources created by the module."
  type        = map(string)
}

variable "authentication_mode" {
  type = string
}

variable "access_entries" {
  type = string
}