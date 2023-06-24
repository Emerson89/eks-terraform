locals {
  environment = "stg"

  addons = {
    "ebs-csi-controller-sa" = {
      count = "${var.create_ebs}" ? 1 : 0
      "name"           = "aws-ebs-csi-driver"
      "serviceaccount" = "ebs-csi-controller-sa"
      "policy_arn"     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      "version"        = "v1.14.1-eksbuild.1"
    }
    "coredns" = {
      "name"           = "coredns"
      "serviceaccount" = "aws-node"
      "policy_arn"     = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
      "version"        = "v1.8.7-eksbuild.3"
    }
  }

}