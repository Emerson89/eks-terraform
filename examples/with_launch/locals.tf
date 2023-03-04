locals {
  tags_eks = {

    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
    "kubernetes.io/role/internal-elb"           = 1
  }
  applied_tags = merge(var.tags, local.tags_eks)

  addons = {
    "ebs-csi-controller-sa" = {
      "name"       = "aws-ebs-csi-driver"
      "data"       = "ebs-csi-controller-sa"
      "policy_arn" = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      "version"    = "v1.14.1-eksbuild.1"
    }
  }

}