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
    ## karpenter
    #"karpenter.sh/discovery" = local.cluster_name
  }

  private_subnets_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared",
    "kubernetes.io/role/internal-elb"             = 1,
    ## karpenter
    #"karpenter.sh/discovery" = local.cluster_name

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
  source = "github.com/Emerson89/eks-terraform.git?ref=v1.0.8"

  cluster_name            = local.cluster_name
  kubernetes_version      = "1.28"
  subnet_ids              = concat(tolist(module.vpc.private_ids), tolist(module.vpc.public_ids))
  environment             = local.environment
  endpoint_private_access = true
  endpoint_public_access  = true

  ## create_aws_auth_configmap **Required Self manager nodes and Spotinst**
  create_aws_auth_configmap = false
  manage_aws_auth_configmap = true

  ## Additional security-group cluster **Required Spotinst**
  security_additional = false
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

  private_subnet = [module.vpc.private_ids[0]]

  tags = local.tags_eks

  ## Addons EKS
  create_ebs     = false
  create_core    = false
  create_vpc_cni = false
  create_proxy   = false

  ## Configuration custom values recommendation to use "set"

  ## Velero
  velero        = false
  ## bucket name used by velero if "true" conflicts with bucket_name_velero
  create_bucket = false 
  #bucket_name_velero = "velero-123456" ## Bucket name already created for use in velero conflicts with create_bucket
  version_chart_velero = "6.1.0"
  version_image_velero = "v1.13.1"
  version_plugin_aws   = "1.7.0"

  ## Controller ingress-nginx
  ingress-nginx = false
  ## Enable Snippet and internal
  # custom_values_nginx = {
  #   set = [
  #     {
  #       name  = "controller.service.type"
  #       value = "LoadBalancer"
  #     },
  #     {
  #       name  = "controller.allowSnippetAnnotations"
  #       value = "true"
  #     },
  #     {
  #       name  = "controller.service.external.enabled"
  #       value = "false"
  #     },
  #     {
  #       name  = "controller.service.internal.enabled"
  #       value = "true"
  #     },
  #     {
  #       name  = "controller.service.internal.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-internal"
  #       value = "true"
  #     }
  #   ]
  # }

  ## Cert-manager
  cert-manager = false
  ## Version chart
  version_chart_cert = "v1.14.4"

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
  aws-autoscaler-controller = true

  ## karpenter ASG test v1.24 k8s
  karpenter               = false
  version_chart_karpenter = "v0.34.0"

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

  ## GROUPS NODES
  nodes = {
    infra = {
      create_node             = true
      node_name               = "infra"
      cluster_version_manager = "1.28"
      desired_size            = 1
      max_size                = 5
      min_size                = 1
      instance_types          = ["t3.medium", "t3a.medium"]
      disk_size               = 20
      capacity_type           = "SPOT"
      #release_version         = "1.28.5-20240227" ## If empty, update ami if available
    }

    infra-lt = {
      create_node           = false
      launch_create         = false
      name_lt               = "lt"
      node_name             = "infra-lt"
      cluster_version       = "1.28"
      desired_size          = 1
      max_size              = 3
      min_size              = 1
      instance_types_launch = "t3.medium"
      volume-size           = 20
      volume-type           = "gp3"
      #image_id              = "ami-0df33cb954c3f5200" ## If empty, update ami if available

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
      fargate_auth         = false
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
      cluster_version       = "1.28"
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

  # nodes_spot = {

  #   spotinst = {
  #     create_node_spotinst = false

  #     node_name                    = "spotinst"
  #     cluster_version              = "1.28"
  #     desired_size                 = 1
  #     max_size                     = 3
  #     min_size                     = 1
  #     preferred_availability_zones = ["us-east-1c"]
  #     instance_types_spot          = ["t3.medium", "t3a.medium"]
  #     spot_percentage              = 100
  #     taints_lt                    = "--register-with-taints=dedicated=${local.environment}:NoSchedule"
  #     labels_lt                    = "--node-labels=eks.amazonaws.com/nodegroup=spotinst"
  #     #image_id                     = "ami-0df33cb954c3f5200" ## If empty, update ami if available
  #     ebs_block_device = [
  #       {
  #         volume_type = "gp3"
  #         volume_size = 20
  #       },
  #     ]
  #     spotinst_tags = [
  #       {
  #         key   = "Environment"
  #         value = "${local.environment}"
  #       }
  #     ]
  #   }
  # }
}

