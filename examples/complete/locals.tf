locals {

  public_subnets_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared",
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnets_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared",
    "kubernetes.io/role/internal-elb"             = 1
  }

  ingress_node = {
    "ingress_rule_1" = {
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
