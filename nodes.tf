locals {
  ingress_with_source_security_group = merge(
    {
      ingress_nodes_ephemeral = {
        description = "Node to node ingress on ephemeral ports"
        protocol    = "tcp"
        from_port   = 1025
        to_port     = 65535
        type        = "ingress"
        self        = true
      },
      ingress_cluster_443 = {
        description = "Cluster API to node groups"
        protocol    = "tcp"
        from_port   = 443
        to_port     = 443
        type        = "ingress"
        self        = true
      }
      ingress_cluster_kubelet = {
        description                   = "Cluster API to node kubelets"
        protocol                      = "tcp"
        from_port                     = 10250
        to_port                       = 10250
        type                          = "ingress"
        source_cluster_security_group = true
      }
      ingress_coredns_tcp = {
        description = "Node to node CoreDNS"
        protocol    = "tcp"
        from_port   = 53
        to_port     = 53
        type        = "ingress"
        self        = true
      }
      ingress_coredns_udp = {
        description = "Node to node CoreDNS UDP"
        protocol    = "udp"
        from_port   = 53
        to_port     = 53
        type        = "ingress"
        self        = true
      }
    },
    var.additional_rules_security_group,
  )
  egress = {
    "engress_rule" = {
      "from_port"   = "0"
      "to_port"     = "0"
      "protocol"    = "-1"
      "cidr_blocks" = ["0.0.0.0/0"]
    }
  }
  node_sg_name = "nodesecuritygroup"

  network_interfaces = [
    {
      security_groups = [try(aws_security_group.this[0].id, [])]
    }
  ]

}

### SEGURITY_GROUP

resource "aws_security_group" "this" {
  count = var.security_additional ? 1 : 0

  name        = format("%s-%s-sg", local.node_sg_name, var.environment)
  description = "Security Group managed by Terraform"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      "Name"     = format("%s-%s", local.node_sg_name, var.environment)
      "Platform" = "network"
      "Type"     = "segurity-group"
    },
    var.tags,
  )
}

resource "aws_security_group_rule" "with_source_security_group" {

  for_each                 = var.security_additional ? local.ingress_with_source_security_group : {}
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  type                     = each.value.type
  security_group_id        = try(aws_security_group.this[0].id, "")
  description              = lookup(each.value, "description", null)
  self                     = lookup(each.value, "self", null)
  source_security_group_id = try(each.value.source_cluster_security_group, false) ? try(aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id, "") : lookup(each.value, "source_security_group_id", null)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "egress_rule" {

  type              = "egress"
  for_each          = var.security_additional ? local.egress : {}
  from_port         = each.value["from_port"]
  to_port           = each.value["to_port"]
  protocol          = each.value["protocol"]
  cidr_blocks       = each.value["cidr_blocks"]
  security_group_id = try(aws_security_group.this[0].id, "")
}

module "nodes" {
  source = "./modules/nodes"

  for_each = var.nodes

  cluster_name    = try(aws_eks_cluster.eks_cluster.name, null)
  cluster_version = try(each.value.cluster_version, aws_eks_cluster.eks_cluster.version)
  node-role       = try(aws_iam_role.node.arn, "")
  private_subnet  = try(var.private_subnet, [])
  node_name       = try(each.value.node_name, null)
  desired_size    = try(each.value.desired_size, null)
  max_size        = try(each.value.max_size, null)
  min_size        = try(each.value.min_size, null)
  environment     = var.environment
  instance_types  = try(each.value.instance_types, [])
  disk_size       = try(each.value.disk_size, null)
  capacity_type   = try(each.value.capacity_type, "ON_DEMAND")
  release_version = try(each.value.release_version, "")
  create_node     = try(each.value.create_node, false)

  labels   = try(each.value.labels, {})
  taints   = try(each.value.taints, {})
  ami_type = try(each.value.ami_type, "AL2_x86_64")

  launch_create           = try(each.value.launch_create, false)
  launch_template_version = try(each.value.launch_template_version, null)
  cidr_services           = try(aws_eks_cluster.eks_cluster.kubernetes_network_config[0].service_ipv4_cidr, "")
  name                    = try(each.value.name_lt, null)
  image_id                = try(each.value.image_id, "")
  instance_types_launch   = try(each.value.instance_types_launch, "")
  volume-size             = try(each.value.volume-size, null)
  volume-type             = try(each.value.volume-type, null)
  network_interfaces      = var.security_additional ? local.network_interfaces : try(each.value.network_interfaces, [])
  tag_specifications      = try(each.value.tag_specifications, [])
  use-max-pods            = try(each.value.use-max-pods, false)
  max-pods                = try(each.value.max-pods, 17)
  endpoint                = try(aws_eks_cluster.eks_cluster.endpoint, "")
  certificate_authority   = try(data.aws_eks_cluster.this.certificate_authority[0].data, "")

  asg_create                 = try(each.value.asg_create, false)
  name_asg                   = try(each.value.name_asg, "")
  vpc_zone_identifier        = try(each.value.vpc_zone_identifier, [])
  iam_instance_profile       = try(aws_iam_instance_profile.iam-node-instance-profile-eks.name, null)
  taints_lt                  = try(each.value.taints_lt, "")
  labels_lt                  = try(each.value.labels_lt, "")
  capacity_rebalance         = try(each.value.capacity_rebalance, true)
  default_cooldown           = try(each.value.default_cooldown, 300)
  use_mixed_instances_policy = try(each.value.use_mixed_instances_policy, false)
  mixed_instances_policy     = try(each.value.use_mixed_instances_policy, {})
  termination_policies       = try(each.value.termination_policies, ["OldestInstance"])
  asg_tags                   = try(each.value.asg_tags, [])

  create_fargate         = try(each.value.create_fargate, false)
  fargate_profile_name   = try(each.value.fargate_profile_name, "")
  selectors              = try(each.value.selectors, [])
  pod_execution_role_arn = try(aws_iam_role.this[0].arn, null)

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = var.tags
}

module "node-spot" {
  source = "./modules/nodes-spot"

  for_each = var.nodes_spot

  create_node_spotinst                               = try(each.value.create_node_spotinst, false)
  cluster_name                                       = try(aws_eks_cluster.eks_cluster.name, null)
  cluster_version                                    = try(each.value.cluster_version, aws_eks_cluster.eks_cluster.version)
  node-role                                          = aws_iam_instance_profile.iam-node-instance-profile-eks.name
  image_id                                           = try(each.value.image_id, "")
  private_subnet                                     = try(var.private_subnet, [])
  node_name                                          = try(each.value.node_name, null)
  desired_size                                       = try(each.value.desired_size, null)
  max_size                                           = try(each.value.max_size, null)
  min_size                                           = try(each.value.min_size, null)
  cpu_credits                                        = try(each.value.cpu_credits, "standard")
  orientation                                        = try(each.value.orientation, "balanced")
  draining_timeout                                   = try(each.value.draining_timeout, 120)
  utilize_reserved_instances                         = try(each.value.utilize_reserved_instances, false)
  fallback_to_ondemand                               = try(each.value.fallback_to_ondemand, true)
  capacity_unit                                      = try(each.value.capacity_unit, "instance")
  product                                            = try(each.value.product, "Linux/UNIX")
  enable_monitoring                                  = try(each.value.enable_monitoring, false)
  ebs_optimized                                      = try(each.value.ebs_optimized, false)
  health_check_type                                  = try(each.value.health_check_type, "K8S_NODE")
  health_check_grace_period                          = try(each.value.health_check_grace_period, 300)
  health_check_unhealthy_duration_before_replacement = try(each.value.health_check_unhealthy_duration_before_replacement, 120)
  placement_tenancy                                  = try(each.value.placement_tenancy, "default")
  environment                                        = var.environment
  preferred_availability_zones                       = try(each.value.preferred_availability_zones, ["us-east-1c"])
  instance_types_ondemand                            = try(each.value.instance_types_ondemand, "t3a.medium")
  instance_types_spot                                = try(each.value.instance_types_spot, ["t3.large", "t3a.large", "m4.large", "m5.large", "m5a.large"])
  instance_types_preferred_spot                      = try(each.value.instance_types_preferred_spot, ["t3.medium", "t3a.medium"])
  autoscale_is_auto_config                           = try(each.value.autoscale_is_auto_config, true)
  autoscale_is_enabled                               = try(each.value.autoscale_is_enabled, true)
  spot_percentage                                    = try(each.value.spot_percentage, 50)
  ebs_block_device                                   = try(each.value.ebs_block_device, [])
  instance_types_weights                             = try(each.value.instance_types_weights, [])
  taints_lt                                          = try(each.value.taints_lt, "")
  labels_lt                                          = try(each.value.labels_lt, "")

  security-group-node   = var.security_additional ? [aws_security_group.this[0].id] : []
  endpoint              = try(aws_eks_cluster.eks_cluster.endpoint, "")
  certificate_authority = try(data.aws_eks_cluster.this.certificate_authority[0].data, "")
  spotinst_tags         = try(each.value.spotinst_tags, [])

  tags = var.tags

}
