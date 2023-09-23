provider "aws" {
  profile = var.profile
  region  = var.region
}

##
locals {
  environment = "hmg"
  tags = {
    Environment = "hmg"
  }
  cluster_name = "k8s"
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
  source = "github.com/Emerson89/eks-terraform.git?ref=v1.0.2"

  cluster_name            = local.cluster_name
  kubernetes_version      = "1.24"
  subnet_ids              = concat(tolist(module.vpc.private_ids), tolist(module.vpc.public_ids))
  environment             = local.environment
  endpoint_private_access = true
  endpoint_public_access  = true

  ## Additional security-group cluster
  security_additional = false
  vpc_id              = module.vpc.vpc_id

  private_subnet = module.vpc.private_ids

  tags = local.tags

  ## Addons EKS
  create_ebs     = false
  create_core    = false
  create_vpc_cni = false
  create_proxy   = false

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

  ## NODES
  nodes = {
    infra = {
      create_node             = true
      node_name               = "infra"
      cluster_version_manager = "1.24"
      desired_size            = 1
      max_size                = 3
      min_size                = 1
      instance_types          = ["t3.medium"]
      disk_size               = 20
    }
    infra-lt = {
      create_node           = true
      launch_create         = true
      name_lt               = "lt"
      node_name             = "infra-lt"
      cluster_version       = "1.24"
      desired_size          = 1
      max_size              = 3
      min_size              = 1
      instance_types_launch = "t3.medium"
      volume-size           = 20
      volume-type           = "gp3"

      labels = {
        Environment = "${local.environment}"
      }

      taints = {
        dedicated = {
          key    = "environment"
          value  = "${local.environment}"
          effect = "NO_SCHEDULE"
        }
      }
    }

    infra-fargate = {
      create_node          = false
      create_fargate       = false
      fargate_profile_name = "infra-fargate"
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
      create_node           = false
      launch_create         = false
      asg_create            = false
      cluster_version       = "1.24"
      name_lt               = "lt-asg"
      desired_size          = 1
      max_size              = 2
      min_size              = 1
      instance_types_launch = "t3.medium"
      volume-size           = 20
      volume-type           = "gp3"
      taints_lt             = "--register-with-taints=dedicated=${local.environment}:NoSchedule"
      labels_lt             = "--node-labels=eks.amazonaws.com/nodegroup=infra"
      name_asg              = "infra"
      vpc_zone_identifier   = "${module.vpc.private_ids}"
      asg_tags = [
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
    }
  }

}

