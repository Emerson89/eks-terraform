locals {
  aws_auth_configmap_data = {
    mapRoles = yamlencode(concat([
      {
        rolearn  = "${var.node-role}"
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
      },
      ],
    var.mapRoles))
    mapUsers    = yamlencode(var.mapUsers)
    mapAccounts = yamlencode(var.mapAccounts)
  }
}

resource "kubernetes_config_map" "aws_auth" {
  count = var.create_aws_auth_configmap ? 1 : 0

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = local.aws_auth_configmap_data

  lifecycle {
    ignore_changes = [data, metadata[0].labels, metadata[0].annotations]
  }
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  count = var.manage_aws_auth_configmap ? 1 : 0

  force = true

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = local.aws_auth_configmap_data

  depends_on = [
    kubernetes_config_map.aws_auth,
  ]
}