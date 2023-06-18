provider "aws" {
  profile = var.profile
  region  = var.region
}

provider "kubernetes" {
  host                   = module.eks-master.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks-master.cluster_cert)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks-master.cluster_name, "--profile", var.profile]
    command     = "aws"
  }
}

##
locals {
  environment = "stg"
  tags = {
    Environment = "stg"
  }
  name_lt      = "lt"
  cluster_name = "k8s"
}

#### VPC
module "vpc" {
  source = "github.com/Emerson89/terraform-modules.git//vpc?ref=main"

  name                 = "vpc-k8s"
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = local.tags

  private_subnets         = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  public_subnets          = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  map_public_ip_on_launch = true
  environment             = local.environment

  public_subnets_tags  = local.public_subnets_tags
  private_subnets_tags = local.private_subnets_tags

  igwname = "igw-k8s"
  natname = "nat-k8s"
  rtname  = "rt-k8s"

  route_table_routes_private = {
    "nat" = {
      "cidr_block"     = "0.0.0.0/0"
      "nat_gateway_id" = "${module.vpc.nat}"
    }
  }
  route_table_routes_public = {
    "igw" = {
      "cidr_block" = "0.0.0.0/0"
      "gateway_id" = "${module.vpc.igw}"
    }
  }
}

### EKS

module "iam-eks" {
  source = "../../"

  cluster_name = local.cluster_name
  environment  = local.environment

}

##SG_EKS
module "sg-cluster" {
  source = "github.com/Emerson89/terraform-modules.git//sg?ref=main"

  sgname                   = "sgcluster"
  environment              = local.environment
  vpc_id                   = module.vpc.vpc_id
  source_security_group_id = module.sg-node.sg_id

  ingress_with_source_security_group = local.ingress_cluster
  ingress_with_cidr_blocks           = local.ingress_cluster_api

  tags = local.tags
}

module "sg-node" {
  source = "github.com/Emerson89/terraform-modules.git//sg?ref=main"

  sgname                   = "sgnode"
  environment              = local.environment
  vpc_id                   = module.vpc.vpc_id
  source_security_group_id = module.sg-cluster.sg_id

  ingress_with_source_security_group = local.ingress_node

  tags = local.tags
}

module "eks-master" {
  source = "../../"

  cluster_name              = local.cluster_name
  master-role               = module.iam-eks.master-iam-arn
  kubernetes_version        = "1.23"
  subnet_ids                = concat(tolist(module.vpc.private_ids), tolist(module.vpc.public_ids))
  security_group_ids        = [module.sg-cluster.sg_id]
  enabled_cluster_log_types = ["api", "audit", "authenticator"]
  environment               = local.environment
  endpoint_private_access   = true
  endpoint_public_access    = true
  addons                    = local.addons

  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true
  node-role                 = module.iam-eks.node-iam-arn
  mapUsers = [
    {
      userarn  = "arn:aws:iam::xxxxxxxxxxxxxx:user/user@example.com"
      username = "user"
      groups   = ["system:masters"]

    },
    {
      userarn  = "arn:aws:iam::xxxxxxxxxxxxxx:user/user2@example.com"
      username = "user2"
      groups   = ["system:masters"]

    },
  ]
}

module "nodes" {
  source = "../../"

  for_each = var.nodes

  cluster_name    = module.eks-master.cluster_name
  cluster_version = try(module.eks-master.cluster_version, null)
  node-role       = try(module.iam-eks.node-iam-arn, null)
  private_subnet  = module.subnet-prd.private_ids
  node_name       = try(each.value.node_name, null)
  desired_size    = try(each.value.desired_size, null)
  max_size        = try(each.value.max_size, null)
  min_size        = try(each.value.min_size, null)
  environment     = var.environment
  instance_types  = try(each.value.instance_types, [])
  disk_size       = try(each.value.disk_size, null)
  capacity_type   = try(each.value.capacity_type, "ON_DEMAND")
  create_node     = try(each.value.create_node, false)

  labels = try(each.value.labels, {})
  taints = try(each.value.taints, {})

  launch_create         = try(each.value.launch_create, false)
  name                  = try(each.value.name_lt, null)
  instance_types_launch = try(each.value.instance_types_launch, "")
  volume-size           = try(each.value.volume-size, null)
  volume-type           = try(each.value.volume-type, null)
  network_interfaces    = try(each.value.network_interfaces, [])
  tag_specifications    = try(each.value.tag_specifications, [])
  endpoint              = try(module.eks-master.cluster_endpoint, null)
  certificate_authority = try(module.eks-master.cluster_cert, null)

  create_fargate       = try(each.value.create_fargate, false)
  fargate_profile_name = try(each.value.fargate_profile_name, null)
  selectors            = try(each.value.selectors, [])

  tags = local.tags
}

module "eks-node-manager" {
  source = "github.com/Emerson89/eks-terraform.git//nodes?ref=main"

  cluster_name    = module.eks-master.cluster_name
  cluster_version = module.eks-master.cluster_version
  node-role       = module.iam-eks.node-iam-arn
  private_subnet  = module.vpc.private_ids
  node_name       = "manager"
  desired_size    = 1
  max_size        = 2
  min_size        = 1
  environment     = local.environment
  instance_types  = ["t3.micro"]
  disk_size       = 30
  create_node     = true

  tags = {
    Environment = local.tags
  }

}

module "eks-node-manager-launch" {
  source = "github.com/Emerson89/eks-terraform.git//nodes?ref=main"

  cluster_name    = module.eks-master.cluster_name
  cluster_version = module.eks-master.cluster_version
  node-role       = module.iam-eks.node-iam-arn
  private_subnet  = module.vpc.private_ids
  node_name       = "manager-node-launch"
  desired_size    = 1
  max_size        = 2
  min_size        = 1
  environment     = local.environment
  create_node     = true

  launch_create         = true
  name                  = local.name_lt
  instance_types_launch = "t3.micro"
  volume-size           = 30
  network_interfaces = [
    {
      security_groups = [module.sg-node.sg_id]
    }
  ]
  endpoint              = module.eks-master.cluster_endpoint
  certificate_authority = module.eks-master.cluster_cert

  tags = local.tags

}

module "eks-node-self-manager" {
  source = "github.com/Emerson89/eks-terraform.git//nodes?ref=main"

  cluster_name    = module.eks-master.cluster_name
  cluster_version = module.eks-master.cluster_version
  desired_size    = 1
  max_size        = 2
  min_size        = 1
  environment     = local.environment
  create_node     = false

  launch_create         = true
  name                  = local.name_lt
  instance_types_launch = "t3.micro"
  volume-size           = 30
  network_interfaces = [
    {
      security_groups = [module.sg-node.sg_id]
    }
  ]
  tag_specifications = [
    {
      resource_type = "instance"

      tags = {
        Name = format("%s-node-%s", local.name_lt, local.environment)
        Type = "EC2"
      }
    },
    {
      resource_type = "volume"

      tags = {
        Name = format("%s-volume-%s", local.name_lt, local.environment)
        Type = "EBS"
      }
    }
  ]
  endpoint              = module.eks-master.cluster_endpoint
  certificate_authority = module.eks-master.cluster_cert
  iam_instance_profile  = module.iam-eks.node-iam-name-profile
  taints_lt             = "dedicated=${local.enviroment}:NoSchedule"

  ## ASG
  vpc_zone_identifier = module.vpc.private_ids
  asg_create          = true
  name_asg            = "infra"
  extra_tags = [
    {
      key                 = "Environment"
      value               = "${local.environment}"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "${local.environment}"
      propagate_at_launch = true
    },
    {
      key                 = "kubernetes.io/cluster/${local.cluster_name}"
      value               = "owner"
      propagate_at_launch = true
    },
  ]

  tags = local.tags

}

module "eks-node-self-manager-spot" {
  source = "github.com/Emerson89/eks-terraform.git//nodes?ref=main"

  cluster_name    = module.eks-master.cluster_name
  cluster_version = module.eks-master.cluster_version
  desired_size    = 1
  max_size        = 2
  min_size        = 1
  environment     = local.environment
  create_node     = false

  launch_create         = true
  name                  = local.name_lt
  instance_types_launch = "t3.micro"
  volume-size           = 30
  network_interfaces = [
    {
      security_groups = [module.sg-node.sg_id]
    }
  ]
  tag_specifications = [
    {
      resource_type = "instance"

      tags = {
        Name = format("%s-node-%s", local.name_lt, local.environment)
        Type = "EC2"
      }
    },
    {
      resource_type = "volume"

      tags = {
        Name = format("%s-volume-%s", local.name_lt, local.environment)
        Type = "EBS"
      }
    }
  ]
  endpoint              = module.eks-master.cluster_endpoint
  certificate_authority = module.eks-master.cluster_cert
  iam_instance_profile  = module.iam-eks.node-iam-name-profile
  taints_lt             = "dedicated=${local.enviroment}:NoSchedule"

  ## ASG
  vpc_zone_identifier        = module.vpc.private_ids
  capacity_rebalance         = true
  default_cooldown           = 300
  use_mixed_instances_policy = true
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "price-capacity-optimized"
      spot_instance_pools                      = 0
    }
    override = [
      {
        instance_type = "t3.micro"
      },
      {
        instance_type = "t3a.micro"
      }
    ]

  }

  termination_policies = ["AllocationStrategy", "OldestLaunchTemplate", "OldestInstance"]
  name_asg             = "infra-spot"
  extra_tags = [
    {
      key                 = "Environment"
      value               = "${local.environment}"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "${local.environment}"
      propagate_at_launch = true
    },
    {
      key                 = "kubernetes.io/cluster/${local.cluster_name}"
      value               = "owner"
      propagate_at_launch = true
    },
  ]

  tags = local.tags

}
