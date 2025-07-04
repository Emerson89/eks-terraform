data "aws_ssm_parameter" "eks_ami_release_version" {
  count = var.launch_create || var.create_node ? 1 : 0 

  name = local.ami_type[var.ami_type]
}

locals {
  launch_template_id      = var.create_node && var.launch_create ? try(aws_launch_template.this[0].id, null) : var.launch_template_id
  launch_template_version = coalesce(var.launch_template_version, try(aws_launch_template.this[0].default_version, "$Default"))
  ami_type = {
    AL2_x86_64             = var.launch_create && var.cluster_version < "1.33" ? "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2/recommended/image_id" : "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2/recommended/release_version"
    AL2023_x86_64_STANDARD = var.launch_create && var.cluster_version > "1.32" ? "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2023/x86_64/standard/recommended/image_id" : "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2023/x86_64/standard/recommended/release_version"
  }
}

resource "aws_eks_node_group" "eks_node_group" {
  count = var.create_node ? 1 : 0

  cluster_name    = var.cluster_name
  node_group_name = format("%s-%s-node-group", var.node_name, var.environment)
  node_role_arn   = var.node-role
  instance_types  = var.launch_create ? null : var.instance_types
  disk_size       = var.launch_create ? null : var.disk_size
  version         = var.launch_create ? null : var.cluster_version
  release_version = var.launch_create ? null : coalesce(var.release_version, data.aws_ssm_parameter.eks_ami_release_version[0].value)
  labels          = var.labels
  capacity_type   = var.capacity_type

  dynamic "taint" {
    for_each = var.taints

    content {
      key    = taint.value.key
      value  = try(taint.value.value, null)
      effect = taint.value.effect
    }
  }

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

### Fargate

resource "aws_eks_fargate_profile" "this" {
  count = var.create_fargate ? 1 : 0

  cluster_name           = var.cluster_name
  fargate_profile_name   = var.fargate_profile_name
  pod_execution_role_arn = var.pod_execution_role_arn
  subnet_ids             = var.private_subnet

  dynamic "selector" {
    for_each = var.selectors

    content {
      namespace = selector.value.namespace
      labels    = lookup(selector.value, "labels", {})
    }
  }
}
