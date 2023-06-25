locals {
  name_alb = "aws-load-balancer-controller"
  name_asg = "cluster-autoscaler"
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
    "aws-load-balancer-controller-${var.environment}" = {
      "openid_connect" = "${aws_iam_openid_connect_provider.this.arn}"
      "openid_url"     = "${aws_iam_openid_connect_provider.this.url}"
      "serviceaccount" = "aws-load-balancer-controller-${var.environment}"
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
      name         = "aws-load-balancer-controller-${var.environment}"
    })])

  }

  set = try(var.custom_values_alb["set"], {})

  # depends_on = [
  #   kubernetes_service_account.service-account
  # ]

}


## ASG

module "iam-asg" {
  source = "./modules/iam"

  count = var.aws-autoscaler-controller ? 1 : 0

  iam_roles = {
    "cluster-autoscaler-${var.environment}" = {
      "openid_connect" = "${aws_iam_openid_connect_provider.this.arn}"
      "openid_url"     = "${aws_iam_openid_connect_provider.this.url}"
      "serviceaccount" = "cluster-autoscaler-${var.environment}"
      "policy" = templatefile("${path.module}/templates/policy-asg.json", {
        cluster_name = "${aws_eks_cluster.eks_cluster.name}"
      })
    }
  }
}

module "asg" {
  source = "./modules/helm"

  count = var.aws-autoscaler-controller ? 1 : 0

  helm_release = {

    name       = try(var.custom_values_asg["name"], local.name_asg)
    namespace  = try(var.custom_values_asg["namespace"], "kube-system")
    repository = "https://kubernetes.github.io/autoscaler"
    chart      = "cluster-autoscaler"

    values = try(var.custom_values_asg["values"], [templatefile("${path.module}/templates/values-asg.yaml", {
      aws_region   = "${data.aws_region.current.name}"
      cluster_name = "${aws_eks_cluster.eks_cluster.name}"
      name         = "cluster-autoscaler-${var.environment}"
      version_k8s  = "${aws_eks_cluster.eks_cluster.version}"
    })])

  }

  set = try(var.custom_values_asg["set"], {})

  # depends_on = [
  #   kubernetes_service_account.service-account
  # ]

}

module "custom" {
  source = "./modules/helm"

  for_each = var.custom_helm

  helm_release = {

    name       = try(each.value.name, "")
    namespace  = try(each.value.namespace, "")
    repository = try(each.value.repository, "")
    version    = try(each.value.version, "")
    chart      = try(each.value.chart, "")

    values = try(each.value.values, [])

  }

  set = try(each.value.set, {})

}