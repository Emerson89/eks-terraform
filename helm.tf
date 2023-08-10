locals {
  name_alb            = "aws-load-balancer-controller"
  name_asg            = "cluster-autoscaler"
  name_external-dns   = "external-dns"
  name_metrics-server = "metrics-server"
  name_ebs            = "aws-ebs-csi-driver"
  name_efs            = "aws-efs-csi-driver"

}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token

}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token

  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

## EFS

module "iam-efs" {
  source = "./modules/iam"

  count = var.aws-efs-csi-driver ? 1 : 0

  iam_roles = {
    "aws-efs-csi-driver-${var.environment}" = {
      "openid_connect" = "${aws_iam_openid_connect_provider.this.arn}"
      "openid_url"     = "${aws_iam_openid_connect_provider.this.url}"
      "serviceaccount" = "efs-csi-*"
      "string"         = "StringLike"
      "policy"         = file("${path.module}/templates/policy-efs.json")
    }
  }
}

module "efs-helm" {
  source = "./modules/helm"

  count = var.aws-efs-csi-driver ? 1 : 0

  helm_release = {

    name       = try(var.custom_values_efs["name"], local.name_efs)
    namespace  = try(var.custom_values_efs["namespace"], "kube-system")
    repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
    chart      = "aws-efs-csi-driver"

    values = try(var.custom_values_efs["values"], [templatefile("${path.module}/templates/values-efs.yaml", {
      aws_region    = "${data.aws_region.current.name}"
      aws_arn_efs   = module.iam-efs[0].arn[0]
      filesystem_id = var.filesystem_id
    })])

  }

  set = try(var.custom_values_efs["set"], {})

  depends_on = [
    module.nodes
  ]

}
## EBS

module "iam-ebs" {
  source = "./modules/iam"

  count = var.aws-ebs-csi-driver ? 1 : 0

  iam_roles = {
    "aws-ebs-csi-driver-${var.environment}" = {
      "openid_connect" = "${aws_iam_openid_connect_provider.this.arn}"
      "openid_url"     = "${aws_iam_openid_connect_provider.this.url}"
      "serviceaccount" = "ebs-csi-controller-sa"
      "string"         = "StringEquals"
      "policy"         = file("${path.module}/templates/policy-ebs.json")
    }
  }
}

module "ebs-helm" {
  source = "./modules/helm"

  count = var.aws-ebs-csi-driver ? 1 : 0

  helm_release = {

    name       = try(var.custom_values_ebs["name"], local.name_ebs)
    namespace  = try(var.custom_values_ebs["namespace"], "kube-system")
    repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
    chart      = "aws-ebs-csi-driver"

    values = try(var.custom_values_ebs["values"], [templatefile("${path.module}/templates/values-ebs.yaml", {
      aws_region   = "${data.aws_region.current.name}"
      cluster_name = "${aws_eks_cluster.eks_cluster.name}"
      aws_arn_ebs  = module.iam-ebs[0].arn[0]
    })])

  }

  set = try(var.custom_values_ebs["set"], {})

  depends_on = [
    module.nodes
  ]

}

## ALB
module "iam-alb" {
  source = "./modules/iam"

  count = var.aws-load-balancer-controller ? 1 : 0

  iam_roles = {
    "aws-load-balancer-controller-${var.environment}" = {
      "openid_connect" = "${aws_iam_openid_connect_provider.this.arn}"
      "openid_url"     = "${aws_iam_openid_connect_provider.this.url}"
      "serviceaccount" = "aws-load-balancer-controller"
      "string"         = "StringEquals"
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
      aws_arn_alb  = module.iam-alb[0].arn[0]
    })])

  }

  set = try(var.custom_values_alb["set"], {})

  depends_on = [
    module.nodes
  ]
}


## ASG

module "iam-asg" {
  source = "./modules/iam"

  count = var.aws-autoscaler-controller ? 1 : 0

  iam_roles = {
    "cluster-autoscaler-${var.environment}" = {
      "openid_connect" = "${aws_iam_openid_connect_provider.this.arn}"
      "openid_url"     = "${aws_iam_openid_connect_provider.this.url}"
      "serviceaccount" = "cluster-autoscaler-aws-cluster-autoscaler"
      "string"         = "StringEquals"
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
      aws_arn_asg  = module.iam-asg[0].arn[0]
      version_k8s  = "${aws_eks_cluster.eks_cluster.version}"
    })])

  }

  set = try(var.custom_values_asg["set"], {})

  depends_on = [
    module.nodes
  ]

}


## ExternalDNS

module "external-dns" {
  source = "./modules/helm"

  count = var.external-dns ? 1 : 0

  helm_release = {

    name       = try(var.custom_values_external-dns["name"], local.name_external-dns)
    namespace  = try(var.custom_values_external-dns["namespace"], "kube-system")
    repository = "https://kubernetes-sigs.github.io/external-dns/"
    chart      = "external-dns"

    values = try(var.custom_values_external-dns["values"], [templatefile("${path.module}/templates/values-external.yaml", {
      domain = "${var.domain}"
      }
    )])

  }

  set = try(var.custom_values_external-dns["set"], {})

  depends_on = [
    module.nodes
  ]

}

## Metrics Server

module "metrics-server" {
  source = "./modules/helm"

  count = var.metrics-server ? 1 : 0

  helm_release = {

    name       = try(var.custom_values_metrics-server["name"], local.name_metrics-server)
    namespace  = try(var.custom_values_metrics-server["namespace"], "kube-system")
    repository = "https://kubernetes-sigs.github.io/metrics-server/"
    chart      = "metrics-server"

    values = try(var.custom_values_metrics-server["values"], [])

  }

  set = try(var.custom_values_metrics-server["set"], {})

  depends_on = [
    module.nodes
  ]

}

## CUSTOM

module "custom" {
  source = "./modules/helm"

  for_each = var.custom_helm

  helm_release = {

    name             = try(each.value.name, "")
    namespace        = try(each.value.namespace, "")
    repository       = try(each.value.repository, "")
    version          = try(each.value.version, "")
    chart            = try(each.value.chart, "")
    create_namespace = try(each.value.create_namespace, false)

    values = try(each.value.values, [])

  }

  set = try(each.value.set, {})

  depends_on = [
    module.nodes
  ]

}
