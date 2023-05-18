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

}