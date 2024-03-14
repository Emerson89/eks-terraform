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
  source = "github.com/Emerson89/eks-terraform.git?ref=v1.0.7"

  cluster_name            = local.cluster_name
  kubernetes_version      = "1.28"
  subnet_ids              = concat(tolist(module.vpc.private_ids), tolist(module.vpc.public_ids))
  environment             = local.environment
  endpoint_private_access = true
  endpoint_public_access  = true

  ## create_aws_auth_configmap **Required Self manager nodes and Spotinst**
  create_aws_auth_configmap = false
  manage_aws_auth_configmap = true

  ## Additional security-group cluster **Required karpenter and Spotinst**
  security_additional = true
  vpc_id              = module.vpc.vpc_id
  # additional_rules_security_group = {
  #   # Karpenter
  #   ingress_cluster_8443_webhook = {
  #     description                   = "Cluster API to node 8443/tcp webhook"
  #     protocol                      = "tcp"
  #     from_port                     = 8443
  #     to_port                       = 8443
  #     type                          = "ingress"
  #     source_cluster_security_group = true
  #   }
  #   # ALB controller, NGINX
  #   ingress_cluster_9443_webhook = {
  #     description                   = "Cluster API to node 9443/tcp webhook"
  #     protocol                      = "tcp"
  #     from_port                     = 9443
  #     to_port                       = 9443
  #     type                          = "ingress"
  #     source_cluster_security_group = true
  #   }
  # }

  private_subnet = module.vpc.private_ids

  tags = local.tags_eks

  ## Addons EKS
  create_ebs     = false
  create_core    = false
  create_vpc_cni = false
  create_proxy   = false

  ## Configuration custom values recommendation to use "set"

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

  ## Configuration custom values recommendation to use "set"
  # custom_values_ebs = {
  #   set = [
  #     {
  #       name  = "resources.requests.cpu"
  #       value = "10m"
  #     },
  #     {
  #       name  = "resources.requests.memory"
  #       value = "40Mi"
  #     }
  #   ]
  # }

  ## External DNS 
  external-dns = false

  ## Controller ASG
  aws-autoscaler-controller = false

  ## karpenter ASG test v1.24 k8s
  karpenter         = false
  version_karpenter = "v0.34.0"

  ## Controller ALB
  aws-load-balancer-controller = false

  ## Custom values
  custom_values_alb = {
    set = [
      {
        name  = "vpcId" ## Variable obrigatory for controller alb
        value = module.vpc.vpc_id
      },
      {
        name  = "tag"
        value = "v2.5.4"
      },
      # {
      #   name  = "nodeSelector.Environment"
      #   value = "hmg"
      # },
      # {
      #   name  = "tolerations[0].key"
      #   value = "environment"
      # },
      # {
      #   name  = "tolerations[0].operator"
      #   value = "Equal"
      # },
      # {
      #   name  = "tolerations[0].value"
      #   value = "hmg"
      # },
      # {
      #   name  = "tolerations[0].effect"
      #   value = "NoSchedule"
      # }
    ]
  }

  ## CUSTOM_HELM

  # custom_helm = {
  #   aws-secrets-manager = {
  #     name             = "aws-secrets-manager"
  #     namespace        = "kube-system"
  #     repository       = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  #     chart            = "secrets-store-csi-driver-provider-aws"
  #     version          = "0.3.4"
  #     create_namespace = false
  #     #values = file("${path.module}/values.yaml")
  #     values = []
  #   }
  #   secret-csi = {
  #     name             = "secret-csi"
  #     namespace        = "kube-system"
  #     repository       = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  #     chart            = "secrets-store-csi-driver"
  #     version          = "v1.3.4"
  #     create_namespace = false
  #     #values = file("${path.module}/values.yaml")
  #     values = []
  #   }
  # }

  nodes_spot = {

    spotinst = {
      create_node_spotinst = false

      node_name                    = "spotinst"
      cluster_version              = "1.28"
      desired_size                 = 1
      max_size                     = 3
      min_size                     = 1
      preferred_availability_zones = ["us-east-1c"]
      instance_types_spot          = ["t3.medium", "t3a.medium"]
      spot_percentage              = 100
      taints_lt                    = "--register-with-taints=dedicated=${local.environment}:NoSchedule"
      labels_lt                    = "--node-labels=eks.amazonaws.com/nodegroup=spotinst"
      #image_id                     = "ami-0df33cb954c3f5200" ## If empty, update ami if available
      ebs_block_device = [
        {
          volume_type = "gp3"
          volume_size = 20
        },
      ]
      spotinst_tags = [
        {
          key   = "Environment"
          value = "${local.environment}"
        }
      ]
    }
  }
}