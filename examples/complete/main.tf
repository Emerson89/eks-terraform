provider "aws" {
  profile = var.profile
  region  = var.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_cert)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.profile]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_cert)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.profile]
      command     = "aws"
    }
  }
}
##
locals {
  environment = "prd"
  tags = {
    Environment = "prd"
  }
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

#module "iam-eks" {
#   source = "github.com/Emerson89/eks-terraform.git//iam-eks?ref=main"
#   cluster_name = local.cluster_name
#   environment  = local.environment
#}

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

module "eks" {
  source = "../../"

  cluster_name = local.cluster_name
  #master-role             = module.iam-eks.master-iam-arn
  kubernetes_version      = "1.23"
  subnet_ids              = concat(tolist(module.vpc.private_ids), tolist(module.vpc.public_ids))
  security_group_ids      = [module.sg-cluster.sg_id]
  environment             = local.environment
  endpoint_private_access = true
  endpoint_public_access  = true
  ##Create aws-auth
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true
  #node-role                 = module.iam-eks.node-iam-arn

  ##addons
  create_ebs     = false
  create_core    = false
  create_vpc_cni = false

  aws-autoscaler-controller    = true
  aws-load-balancer-controller = true
  custom_values_alb = {
    #values = [templatefile("${path.module}/values.yaml", {
    #  aws_region   = "us-east-1"
    #  cluster_name = "${module.eks.cluster_name}"
    #  name         = "${module.eks.service_account_name}"
    #})]
    set = [
      {
        name  = "nodeSelector.Environment"
        value = "prd"
      },
      {
        name  = "vpcId"
        value = module.vpc.vpc_id
      },
      # {
      #   name  = "tolerations[0].key"
      #   value = "key1"
      # },
      # {
      #   name  = "tolerations[0].operator"
      #   value = "Equal"
      # },
      # {
      #   name  = "tolerations[0].value"
      #   value = "prd"
      # },
      # {
      #   name  = "tolerations[0].effect"
      #   value = "NoSchedule"
      # },

    ]
  }

  #vpc_id = module.vpc.vpc_id
  
  ## CUSTOM_HELM

  custom_helm = {
    aws-secrets-manager = {
      "name"             = "aws-secrets-manager"
      "namespace"        = "kube-system"
      "repository"       = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
      "chart"            = "secrets-store-csi-driver-provider-aws"
      "version"          = "" ## When empty, the latest version will be installed
      "create_namespace" = false

      "values" = [] ## When empty, default values will be used
    }
    external-dns = {
      "name"             = "external-dns"
      "namespace"        = "kube-system"
      "repository"       = "https://kubernetes-sigs.github.io/external-dns/"
      "chart"            = "external-dns"
      "version"          = "" ## When empty, the latest version will be installed
      "create_namespace" = false
      
      "values" = []
    }
  }

  ## NODES
  nodes = {
    infra = {
      create_node = true
      node_name   = "infra"
      #cluster_name    = "${local.cluster_name}"
      cluster_version = "1.23"
      desired_size    = 1
      max_size        = 2
      min_size        = 1
      instance_types  = ["t3.medium"]
      disk_size       = 20
      labels = {
        Environment = "prd"
      }
      #taints = {
      #  dedicated = {
      #    key    = "environment"
      #    value  = "prd"
      #    effect = "NO_SCHEDULE"
      #  }
      #}
    }
    infra-lt = {
      create_node   = false
      launch_create = false
      name_lt       = "lt"
      node_name     = "infra-lt"
      #cluster_name          = "${local.cluster_name}"
      cluster_version       = "1.23"
      desired_size          = 1
      max_size              = 2
      min_size              = 1
      instance_types_launch = "t3.medium"
      volume-size           = 20
      volume-type           = "gp3"


      labels = {
        Environment = "prd"
      }
      taints = {
        dedicated = {
          key    = "environment"
          value  = "prd"
          effect = "NO_SCHEDULE"
        }
      }
    }
    infra-fargate = {
      create_node          = false
      create_fargate       = false
      fargate_profile_name = "infra-fargate"
      #cluster_name         = local.cluster_name
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            k8s-app = "kube-dns"
          }
        },
        {
          namespace = "default"
        }
      ]
    }
    infra-asg = {
      create_node   = false
      launch_create = false
      asg_create    = false
      #cluster_name          = "${local.cluster_name}"
      cluster_version       = "1.23"
      name_lt               = "lt-asg"
      desired_size          = 1
      max_size              = 2
      min_size              = 1
      instance_types_launch = "t3.medium"
      volume-size           = 20
      volume-type           = "gp3"
      name_asg              = "infra"
      vpc_zone_identifier   = "${module.vpc.private_ids}"
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


      labels = {
        Environment = "prd"
      }
      taints = {
        dedicated = {
          key    = "environment"
          value  = "prd"
          effect = "NO_SCHEDULE"
        }
      }
    }

    #endpoint              = module.eks-master.cluster_endpoint
    #certificate_authority = module.eks-master.cluster_cert
    #node-role             = module.iam-eks.node-iam-arn
    #iam_instance_profile  = module.iam-eks.node-iam-name-profile

  }

  private_subnet = module.vpc.private_ids

  tags = local.tags

}

