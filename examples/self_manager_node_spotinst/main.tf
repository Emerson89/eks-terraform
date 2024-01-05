provider "aws" {
  profile = ""
  region  = ""
}

provider "spotinst" {
  token   = ""
  account = ""
}

##
locals {
  environment = "hmg"
  tags = {
    Environment = "hmg"
  }
  cluster_name = "k8s"

  public_subnets_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared",
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnets_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared",
    "kubernetes.io/role/internal-elb"             = 1
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
  source = "github.com/Emerson89/eks-terraform.git?ref=v1.0.6"

  cluster_name              = local.cluster_name
  kubernetes_version        = "1.24"
  subnet_ids                = concat(tolist(module.vpc.private_ids), tolist(module.vpc.public_ids))
  environment               = local.environment
  endpoint_private_access   = true
  endpoint_public_access    = true
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = false

  ## Additional security-group cluster
  security_additional = true
  vpc_id              = module.vpc.vpc_id

  private_subnet = module.vpc.private_ids

  tags = local.tags

  ## Addons EKS
  create_ebs     = false
  create_core    = false
  create_vpc_cni = false
  create_proxy   = false

  ## Velero
  velero = false

  ## Controller ingress-nginx
  ingress-nginx = false

  ## Cert-manager
  cert-manager = false

  ## EFS controller
  aws-efs-csi-driver = false
  filesystem_id      = "fs-92107410"

  ## Controller EBS Helm
  aws-ebs-csi-driver = false

  ## Configuration custom values
  #custom_values_ebs = {
  #  values = [templatefile("${path.module}/values-ebs.yaml", {
  #    aws_region   = "us-east-1"
  #    cluster_name = "${local.cluster_name}"
  #  })]
  #}

  ## External DNS 
  external-dns = false

  ## Controller ASG
  aws-autoscaler-controller = false

  ## Controller ALB
  aws-load-balancer-controller = false

  ## Custom values
  custom_values_alb = {
    set = [
      {
        name  = "nodeSelector.Environment"
        value = "hmg"
      },
      {
        name  = "vpcId" ## Variable obrigatory for controller alb
        value = module.vpc.vpc_id
      },
      {
        name  = "tag"
        value = "v2.5.4"
      },
      {
        name  = "tolerations[0].key"
        value = "environment"
      },
      {
        name  = "tolerations[0].operator"
        value = "Equal"
      },
      {
        name  = "tolerations[0].value"
        value = "hmg"
      },
      {
        name  = "tolerations[0].effect"
        value = "NoSchedule"
      }
    ]
  }

  ## GROUPS NODES
  nodes_spot = {
    spotinst = {
      create_node_spotinst         = true
      node_name                    = "spotinst"
      cluster_version              = "1.24"
      desired_size                 = 1
      max_size                     = 3
      min_size                     = 1
      volume_type                  = "gp3"
      volume_size                  = 20
      preferred_availability_zones = ["us-east-1c"]
      instance_types_spot          = ["m4.large", "m5.large", "m5a.large", "r4.large", "r5.large", "r5a.large"]
    }
  }
}

