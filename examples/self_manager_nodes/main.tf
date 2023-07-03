module "eks-node-infra" {
  source = "github.com/Emerson89/eks-terraform.git//modules//nodes?ref=main"

  cluster_name    = "k8s"
  cluster_version = "1.23"
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
  endpoint              = var.cluster_endpoint
  certificate_authority = var.cluster_ca_cert
  iam_instance_profile  = "arn-abcbdabcdbabc"
  ##Taint
  taint_lt = "--register-with-taints=dedicated=${local.environment}:NoSchedule"
  ##Labels
  labels_lt = "--node-labels=eks.amazonaws.com/nodegroup=infra"

  ## ASG
  vpc_zone_identifier = ["subnet-abcabcabc", "subnet-abcabcabc", "subnet-abdcabcd"]
  asg_create          = true
  name_asg            = "infra"
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

  tags = local.tags

}
