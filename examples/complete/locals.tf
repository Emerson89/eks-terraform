locals {

  addons = {
    "ebs-csi-controller-sa" = {
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

  public_subnets_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
    "kubernetes.io/role/elb"                    = 1
  }

  private_subnets_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
    "kubernetes.io/role/internal-elb"           = 1
  }

  ingress_cluster = {
    "ingress_rule_1" = {
      "from_port" = "443"
      "to_port"   = "443"
      "protocol"  = "tcp"
    },
  }

  ingress_node = {
    "ingress_rule_1" = {
      "from_port" = "1025"
      "to_port"   = "65535"
      "protocol"  = "tcp"
    },
    "ingress_rule_2" = {
      "from_port" = "0"
      "to_port"   = "65535"
      "protocol"  = "-1"
    },
  }

  ingress_cluster_api = {
    "ingress_rule_1" = {
      "from_port"   = "443"
      "to_port"     = "443"
      "protocol"    = "tcp"
      "cidr_blocks" = ["${module.vpc.vpc_cidr}"]
    },
  }
}
