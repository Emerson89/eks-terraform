data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.eks_cluster.name
}

resource "aws_eks_cluster" "eks_cluster" {

  name     = var.cluster_name
  role_arn = var.master-role
  version  = var.kubernetes_version

  vpc_config {
    security_group_ids      = var.security_group_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    subnet_ids              = var.subnet_ids

  }

  tags = merge(
    {
      "Name"     = format("%s-%s", var.cluster_name, var.environment)
      "Platform" = "EKS"
      "Type"     = "Container"
    },
    var.tags,
  )

  lifecycle {
    create_before_destroy = false
  }
}

