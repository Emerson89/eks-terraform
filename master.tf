data "aws_partition" "current" {}

data "aws_iam_session_context" "current" {
  count = var.create_access_entry ? 1 : 0

  arn = try(data.aws_caller_identity.current.arn, "")
}

locals {
  bootstrap_cluster_creator_admin_permissions = merge(
    {
      adm = {
        principal_arn = try(data.aws_iam_session_context.current[0].issuer_arn, "")
        type          = "STANDARD"

        policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

        access_scope = {
          admin = {
            type = "cluster"
          }
        }
      }
    },
    var.eks_access_entry,
  )
}

data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.eks_cluster.name
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.eks_cluster.name
}

resource "aws_cloudwatch_log_group" "this" {
  # The log group name format is /aws/eks/<cluster-name>/cluster
  # Reference: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
}

resource "aws_eks_access_entry" "this" {
  for_each = var.create_access_entry ? local.bootstrap_cluster_creator_admin_permissions : {}

  cluster_name      = aws_eks_cluster.eks_cluster.id
  principal_arn     = each.value.principal_arn
  kubernetes_groups = lookup(each.value, "kubernetes_groups", [])
  type              = lookup(each.value, "type", "")
}

resource "aws_eks_access_policy_association" "this" {
  for_each = var.create_access_entry ? local.bootstrap_cluster_creator_admin_permissions : {}

  cluster_name  = aws_eks_cluster.eks_cluster.id
  policy_arn    = each.value.policy_arn
  principal_arn = each.value.principal_arn

  dynamic "access_scope" {
    for_each = lookup(each.value, "access_scope", [])
    content {
      type       = access_scope.value.type
      namespaces = lookup(access_scope.value, "namespace", [])
    }
  }
}

resource "aws_eks_cluster" "eks_cluster" {

  name     = var.cluster_name
  role_arn = aws_iam_role.master.arn
  version  = var.kubernetes_version

  access_config {
    authentication_mode                         = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  vpc_config {
    security_group_ids      = var.security_additional ? [aws_security_group.this[0].id] : var.security_group_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    subnet_ids              = var.subnet_ids

  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.this
  ]

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
