locals {
  name_alb            = "aws-load-balancer-controller"
  name_asg            = "cluster-autoscaler"
  name_external-dns   = "external-dns"
  name_metrics-server = "metrics-server"
  name_ebs            = "aws-ebs-csi-driver"
  name_efs            = "aws-efs-csi-driver"
  name_ingress_nginx  = "ingress-nginx"
  name_cert_manager   = "cert-manager"
  name_velero         = "velero"
  name_karpenter      = "karpenter"

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

## karpenter

module "iam-karpenter" {
  source = "./modules/iam"

  count = var.karpenter ? 1 : 0

  iam_roles = {
    "karpenter-${var.environment}" = {
      "openid_connect" = "${aws_iam_openid_connect_provider.this.arn}"
      "openid_url"     = "${aws_iam_openid_connect_provider.this.url}"
      "serviceaccount" = "karpenter"
      "string"         = "StringEquals"
      "namespace"      = "karpenter"
      "policy" = templatefile("${path.module}/templates/policy-karpenter.json", {
        KARPENTER_NODE_ROLE = "${aws_iam_role.node.arn}"
        AWS_REGION          = "${data.aws_region.current.name}"
        AWS_ACCOUNT_ID      = "${data.aws_caller_identity.current.id}"
        CLUSTER_NAME        = "${aws_eks_cluster.eks_cluster.name}"
      })
    }
  }
}

module "karpenter" {
  source = "./modules/helm"

  count = var.karpenter ? 1 : 0

  helm_release = {

    name             = try(var.custom_values_karpenter["name"], local.name_karpenter)
    namespace        = try(var.custom_values_karpenter["namespace"], "karpenter")
    repository       = "oci://public.ecr.aws/karpenter"
    chart            = "karpenter"
    version          = var.version_chart_karpenter
    create_namespace = true

    values = try(var.custom_values_karpenter["values"], [templatefile("${path.module}/templates/values-karpenter.yaml", {
      CLUSTER_NAME      = "${aws_eks_cluster.eks_cluster.name}"
      aws_arn_karpenter = module.iam-karpenter[0].arn[0]
      webhook_enabled   = var.webhook_enabled
    })])

  }

  set = try(var.custom_values_karpenter["set"], {})

  depends_on = [
    module.nodes,
    module.node-spot,
    aws_eks_access_entry.this,
    aws_eks_access_policy_association.this
  ]
}


## Velero

resource "aws_s3_bucket" "this" {
  count = var.velero && var.create_bucket ? 1 : 0

  bucket_prefix = "velero-"
  force_destroy = var.force_destroy

  tags = merge(
    {
      "Name"     = format("%s-%s", "velero", var.environment)
      "Platform" = "Storage"
      "Type"     = "S3"
    },
    var.tags,
  )
}

module "iam-velero" {
  source = "./modules/iam"

  count = var.velero ? 1 : 0

  iam_roles = {
    "velero-${var.environment}" = {
      "openid_connect" = "${aws_iam_openid_connect_provider.this.arn}"
      "openid_url"     = "${aws_iam_openid_connect_provider.this.url}"
      "serviceaccount" = "velero"
      "string"         = "StringEquals"
      "namespace"      = "velero"
      "policy" = templatefile("${path.module}/templates/policy-velero.json", {
        bucket_name = var.create_bucket ? "${aws_s3_bucket.this[0].bucket}" : var.bucket_name_velero
      })
    }
  }
}

module "velero" {
  source = "./modules/helm"

  count = var.velero ? 1 : 0

  helm_release = {

    name             = try(var.custom_values_velero["name"], local.name_velero)
    namespace        = try(var.custom_values_velero["namespace"], "velero")
    repository       = "https://vmware-tanzu.github.io/helm-charts"
    chart            = "velero"
    version          = var.version_chart_velero
    create_namespace = true

    values = try(var.custom_values_velero["values"], [templatefile("${path.module}/templates/values-velero.yaml", {
      aws_region           = "${data.aws_region.current.name}"
      bucket_name          = var.create_bucket ? "${aws_s3_bucket.this[0].bucket}" : var.bucket_name_velero
      aws_arn_velero       = module.iam-velero[0].arn[0]
      version_image_velero = var.version_image_velero
      version_plugin_aws   = var.version_plugin_aws
    })])

  }

  set = try(var.custom_values_velero["set"], {})

  depends_on = [
    module.nodes,
    module.node-spot,
    aws_eks_access_entry.this,
    aws_eks_access_policy_association.this
  ]
}

## Ingress-nginx

module "ingress-helm" {
  source = "./modules/helm"

  count = var.ingress-nginx ? 1 : 0

  helm_release = {

    name             = try(var.custom_values_nginx["name"], local.name_ingress_nginx)
    namespace        = try(var.custom_values_nginx["namespace"], "ingress-nginx")
    repository       = "https://kubernetes.github.io/ingress-nginx"
    chart            = "ingress-nginx"
    version          = var.version_chart_nginx
    create_namespace = true

    values = try(var.custom_values_nginx["values"], [])

  }

  set = try(var.custom_values_nginx["set"], {})

  depends_on = [
    module.nodes,
    module.node-spot,
    aws_eks_access_entry.this,
    aws_eks_access_policy_association.this
  ]

}

## Certmanager
module "cert-helm" {
  source = "./modules/helm"

  count = var.cert-manager ? 1 : 0

  helm_release = {

    name             = try(var.custom_values_nginx["name"], local.name_cert_manager)
    namespace        = try(var.custom_values_nginx["namespace"], "cert-manager")
    repository       = "https://charts.jetstack.io"
    chart            = "cert-manager"
    version          = var.version_chart_cert
    create_namespace = true

    values = try(var.custom_values_cert_manager["values"], [file("${path.module}/templates/values-cert.yaml")])

  }

  set = try(var.custom_values_cert_manager["set"], {})

  depends_on = [
    module.nodes,
    module.node-spot,
    aws_eks_access_entry.this,
    aws_eks_access_policy_association.this
  ]

}

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
      "namespace"      = "kube-system"
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
    version    = var.version_chart_efs

    values = try(var.custom_values_efs["values"], [templatefile("${path.module}/templates/values-efs.yaml", {
      aws_region    = "${data.aws_region.current.name}"
      aws_arn_efs   = module.iam-efs[0].arn[0]
      filesystem_id = var.filesystem_id
    })])

  }

  set = try(var.custom_values_efs["set"], {})

  depends_on = [
    module.nodes,
    module.node-spot,
    aws_eks_access_entry.this,
    aws_eks_access_policy_association.this
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
      "namespace"      = "kube-system"
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
    version    = var.version_chart_ebs
    chart      = "aws-ebs-csi-driver"

    values = try(var.custom_values_ebs["values"], [templatefile("${path.module}/templates/values-ebs.yaml", {
      aws_region   = "${data.aws_region.current.name}"
      cluster_name = "${aws_eks_cluster.eks_cluster.name}"
      aws_arn_ebs  = module.iam-ebs[0].arn[0]
    })])

  }

  set = try(var.custom_values_ebs["set"], {})

  depends_on = [
    module.nodes,
    module.node-spot,
    aws_eks_access_entry.this,
    aws_eks_access_policy_association.this
  ]

}

resource "kubernetes_annotations" "this" {
  count = var.aws-ebs-csi-driver ? 1 : 0

  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  force       = true

  metadata {
    name = "gp2"
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"
  }

  depends_on = [
    module.ebs-helm[0]
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
      "namespace"      = "kube-system"
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
    version    = var.version_chart_alb

    values = try(var.custom_values_alb["values"], [templatefile("${path.module}/templates/values-alb.yaml", {
      aws_region   = "${data.aws_region.current.name}"
      cluster_name = "${aws_eks_cluster.eks_cluster.name}"
      aws_arn_alb  = module.iam-alb[0].arn[0]
    })])

  }

  set = try(var.custom_values_alb["set"], {})

  depends_on = [
    module.nodes,
    module.node-spot,
    aws_eks_access_entry.this,
    aws_eks_access_policy_association.this
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
      "namespace"      = "kube-system"
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
    version    = var.version_chart_asg

    values = try(var.custom_values_asg["values"], [templatefile("${path.module}/templates/values-asg.yaml", {
      aws_region   = "${data.aws_region.current.name}"
      cluster_name = "${aws_eks_cluster.eks_cluster.name}"
      aws_arn_asg  = module.iam-asg[0].arn[0]
      version_k8s  = "${aws_eks_cluster.eks_cluster.version}"
    })])

  }

  set = try(var.custom_values_asg["set"], {})

  depends_on = [
    module.nodes,
    module.node-spot,
    aws_eks_access_entry.this,
    aws_eks_access_policy_association.this
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
    version    = var.version_chart_external_dns

    values = try(var.custom_values_external-dns["values"], [templatefile("${path.module}/templates/values-external.yaml", {
      domain = "${var.domain}"
      }
    )])

  }

  set = try(var.custom_values_external-dns["set"], {})

  depends_on = [
    module.nodes,
    module.node-spot,
    aws_eks_access_entry.this,
    aws_eks_access_policy_association.this
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
    module.nodes,
    module.node-spot,
    aws_eks_access_entry.this,
    aws_eks_access_policy_association.this
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
    module.nodes,
    module.node-spot,
    aws_eks_access_entry.this,
    aws_eks_access_policy_association.this
  ]
}
