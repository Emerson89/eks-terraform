locals {
  launch_template_id      = var.create_node && var.launch_create ? try(aws_launch_template.this[0].id, null) : var.launch_template_id
  launch_template_version = coalesce(var.launch_template_version, try(aws_launch_template.this[0].default_version, "$Default"))
}

resource "aws_eks_node_group" "eks_node_group" {
  count = var.create_node ? 1 : 0

  cluster_name    = var.cluster_name
  node_group_name = format("%s-node-group", var.node_name)
  node_role_arn   = var.node-role
  instance_types  = var.launch_create ? null : var.instance_types
  disk_size       = var.launch_create ? null : var.disk_size

  subnet_ids = var.private_subnet

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  dynamic "launch_template" {
    for_each = var.launch_create ? [1] : []

    content {
      id      = local.launch_template_id
      version = local.launch_template_version
    }
  }

  tags = merge(
    {
      "Name"                                          = format("%s-%s", var.node_name, var.environment)
      "Platform"                                      = "EKS"
      "Type"                                          = "Container"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      "k8s.io/cluster-autoscaler/enabled"             = true
    },
    var.tags,
  )

  lifecycle {
    create_before_destroy = false
    ignore_changes        = [scaling_config.0.desired_size]
  }

  timeouts {
    create = "10m"
  }
}
