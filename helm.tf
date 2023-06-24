locals {
  name_alb = "aws-load-balancer-controller"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

#data "aws_vpc" "selected" {
#  count = var.aws-load-balancer-controller ? 1 : 0
#
#  id = try(var.vpc_id, "")
#}

# resource "aws_iam_role" "this" {
#   count = var.aws-load-balancer-controller ? 1 : 0

#   name = local.name_alb

#   assume_role_policy = local.assume_role_policy_alb

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_iam_role_policy" "this" {
#   count = var.aws-load-balancer-controller ? 1 : 0

#   name = local.name_alb
#   role = aws_iam_role.this[0].id

#   policy = file("${path.module}/templates/policy-alb.json")

# }

# resource "kubernetes_service_account" "service-account" {
#   count = var.aws-load-balancer-controller ? 1 : 0

#   metadata {
#     name      = "aws-load-balancer-controller"
#     namespace = "kube-system"
#     labels = {
#       "app.kubernetes.io/name"      = "aws-load-balancer-controller"
#       "app.kubernetes.io/component" = "controller"
#     }
#     annotations = {
#       "eks.amazonaws.com/role-arn"               = "${module.iam.arn}"
#       "eks.amazonaws.com/sts-regional-endpoints" = "true"
#     }
#   }
# }

module "iam" {
  source = "./modules/iam"
  
  count = var.aws-load-balancer-controller ? 1 : 0

  iam_roles = {
    "aws-load-balancer-controller" = {
      "openid_connect" = "${aws_iam_openid_connect_provider.this.arn}"
      "openid_url"     = "${aws_iam_openid_connect_provider.this.url}"
      "serviceaccount" = "aws-load-balancer-controller"
      "policy"         = file("${path.module}/templates/policy-alb.json")
    }
  }
}

module "alb" {
  source = "./modules/helm"

  count = var.aws-load-balancer-controller ? 1 : 0

  helm_release = {

    name       = try(var.custom_values_alb["name"], local.name_alb)
    namespace  = try(var.custom_values_alb["namespace"], "kube-system")
    repository = "https://aws.github.io/eks-charts"
    chart      = "aws-load-balancer-controller"

    values = try(var.custom_values_alb["values"], [templatefile("${path.module}/templates/values-alb.yaml", {
      aws_region   = "${data.aws_region.current.name}"
      cluster_name = "${aws_eks_cluster.eks_cluster.name}"
      name         = "aws-load-balancer-controller"
    })])

  }

  set = try(var.custom_values_alb["set"], {})

  # depends_on = [
  #   kubernetes_service_account.service-account
  # ]

}
