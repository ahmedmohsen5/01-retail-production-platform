resource "aws_launch_template" "this" {
  name_prefix            = "${var.node_group_name}-"
  vpc_security_group_ids = var.security_group_ids
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.disk_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = var.node_group_name })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = var.cluster_name
  version         = var.cluster_version
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  ami_type       = var.ami_type
  capacity_type  = var.capacity_type
  instance_types = var.instance_types

  scaling_config {
    min_size     = var.min_size
    desired_size = var.desired_size
    max_size     = var.max_size
  }

  launch_template {
    id      = aws_launch_template.this.id
    version = tostring(aws_launch_template.this.latest_version)
  }

  update_config {
    max_unavailable = var.max_unavailable
  }

  node_repair_config {
    enabled = var.node_repair_enabled
  }

  labels = var.labels

  tags = merge(var.tags, {
    Name = var.node_group_name
  })
}