provider "aws" {
  profile = var.profile
  region  = var.region
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_cert)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--profile", var.profile]
    command     = "aws"
  }
}

## module
module "eks-node-infra" {
  source = "github.com/Emerson89/eks-terraform.git//nodes?ref=main"

  cluster_name    = local.cluster_name
  cluster_version = "1.23"
  desired_size    = 1
  max_size        = 2
  min_size        = 1
  environment     = local.environment
  create_node     = false

  launch_create         = true
  name                  = local.name_lt
  instance_types_launch = "t3.micro"
  network_interfaces = [
    {
      security_groups = ["sg-abcdabcdabcd"]
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
  endpoint              = "cluster-endpoint"
  certificate_authority = "cluster-cert"
  iam_instance_profile  = "arn-abcdabcdabcd"
  taints_lt             = "dedicated=${local.environment}:NoSchedule"

  ## ASG
  asg_create                 = true
  vpc_zone_identifier        = ["subnet-abcabcabc", "subnet-abcabcabc", "subnet-abdcabcd"]
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
  name_asg             = "infra"
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
