provider "aws" {
  profile = var.profile
  region  = var.region
}

locals {
  environment = "hmg"
  tags = {
    Environment = "hmg"
  }

  tags_eks = {
    Environment = "hmg"
  }

  cluster_name = "k8s"

  public_subnets_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared",
    "kubernetes.io/role/elb"                      = 1,
  }

  private_subnets_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared",
    "kubernetes.io/role/internal-elb"             = 1,
  }
}

#### VPC
module "vpc" {
  source = "github.com/Emerson89/vpc-aws-terraform.git?ref=v1.0.0"

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

}

### EKS

module "eks" {
  source = "github.com/Emerson89/eks-terraform.git?ref=v2.0.0"

  cluster_name            = local.cluster_name
  kubernetes_version      = "1.33"
  subnet_ids              = concat(tolist(module.vpc.private_ids), tolist(module.vpc.public_ids))
  environment             = local.environment
  endpoint_private_access = true
  endpoint_public_access  = true

  private_subnet = [module.vpc.private_ids[0]]

  tags = local.tags_eks

  ## Controller ASG
  aws-autoscaler-controller = true

  authentication_mode = "API_AND_CONFIG_MAP"

  create_access_entry = true

  # eks_access_entry = {
  #   test = {
  #     principal_arn = "arn:aws:iam::xxxxxxxxxxxx:user/test-user"
  #     type          = "STANDARD"

  #     policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  #     access_scope = {
  #       test = {
  #         type = "cluster"
  #       }
  #     }
  #   }
  # }

  ## GROUPS NODES
  nodes = {
    infra = {
      create_node             = true
      node_name               = "infra"
      cluster_version_manager = "1.33"
      desired_size            = 1
      max_size                = 5
      min_size                = 1
      instance_types          = ["t3.medium", "t3a.medium"]
      disk_size               = 20
      capacity_type           = "SPOT"
      ## https://docs.aws.amazon.com/pt_br/eks/latest/userguide/retrieve-ami-id.html
      ami_type        = "AL2023_x86_64_STANDARD"
      #release_version         = "1.28.5-20240227" ## If empty, update ami if available
    }
  }
}

