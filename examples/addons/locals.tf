locals {
  environment = "stg"
  tags = {
    Environment = "stg"
  }
  
  ingress_cluster = {
    "ingress_rule_1" = {
      "from_port" = "443"
      "to_port"   = "443"
      "protocol"  = "tcp"
    },
  }

  ingress_cluster_api = {
    "ingress_rule_1" = {
      "from_port"   = "0"
      "to_port"     = "65535"
      "protocol"    = "-1"
      "cidr_blocks" = ["10.0.0.0/16"]
    },
  }

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

}