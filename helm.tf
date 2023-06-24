locals {
  name_alb = "aws-load-balancer-controller"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

#data "aws_vpc" "selected" {
#  count = var.enable_alb ? 1 : 0
#
#  id = try(var.vpc_id, "")
#}

resource "aws_iam_role" "this" {
  count = var.enable_alb ? 1 : 0

  name = local.name_alb

  assume_role_policy = local.assume_role_policy_alb

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "this" {
  count = var.enable_alb ? 1 : 0

  name = local.name_alb
  role = aws_iam_role.this[0].id

  policy = file("${path.module}/templates/policy-alb.json")

}

resource "kubernetes_service_account" "service-account" {
  count = var.enable_alb ? 1 : 0

  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = "${aws_iam_role.this[0].arn}"
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

module "alb" {
  source = "./modules/helm"

  count = var.enable_alb ? 1 : 0

  helm_release = {

    name       = try(var.addons_alb["name"], local.name_alb)
    namespace  = try(var.addons_alb["namespace"], "kube-system")
    repository = "https://aws.github.io/eks-charts"
    chart      = "aws-load-balancer-controller"

    values = try(var.addons_alb["values"], [templatefile("${path.module}/templates/values-alb.yaml", {
      aws_region   = "${data.aws_region.current.name}"
      cluster_name = "${aws_eks_cluster.eks_cluster.name}"
      name         = "${kubernetes_service_account.service-account[0].metadata.0.name}"
    })])

  }

  set = try(var.addons_alb["set"], {})

  depends_on = [
    kubernetes_service_account.service-account
  ]

}
