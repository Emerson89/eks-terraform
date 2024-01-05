data "aws_region" "current" {}

data "aws_ami" "eks-worker" {
  count = var.create_node_spotinst ? 1 : 0
  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-*"]
  }
  most_recent = true
  owners      = ["amazon"]
}

resource "spotinst_elastigroup_aws" "this" {
  count = var.create_node_spotinst ? 1 : 0

  name                       = format("%s-%s", var.node_name, var.environment)
  spot_percentage            = var.spot_percentage
  ondemand_count             = var.ondemand_count
  orientation                = "availabilityOriented"
  draining_timeout           = 120
  utilize_reserved_instances = true
  fallback_to_ondemand       = true
  lifetime_period            = "days"

  ebs_block_device {
    device_name           = "/dev/xvda"
    volume_type           = var.volume_type
    volume_size           = var.disk_size
    delete_on_termination = true
    encrypted             = false
  }

  revert_to_spot {
    perform_at   = var.perform_at
    time_windows = var.time_windows
  }

  desired_capacity              = var.desired_size
  min_size                      = var.min_size
  max_size                      = var.max_size
  capacity_unit                 = "instance"
  instance_types_ondemand       = var.instance_types_ondemand
  instance_types_spot           = var.instance_types_spot
  instance_types_preferred_spot = var.instance_types_preferred_spot
  subnet_ids                    = var.private_subnet
  product                       = "Linux/UNIX"
  security_groups               = var.security-group-node
  enable_monitoring             = false
  ebs_optimized                 = true
  image_id                      = data.aws_ami.eks-worker[0].id
  user_data = base64encode(<<-EOT
                                  #!/bin/bash
                                  set -o xtrace
                                  /etc/eks/bootstrap.sh --apiserver-endpoint '${var.endpoint}' --b64-cluster-ca '${var.certificate_authority}' '${var.cluster_name}' --kubelet-extra-args --node-labels=node.group=${var.cluster_name}-private,spot=true
                                  EOT
  )

  dynamic "instance_types_weights" {
    for_each = var.instance_types_weights
    content {
      instance_type = instance_types_weights.value.instance_type
      weight        = instance_types_weights.value.weight
    }
  }

  tags {
    key   = "Name"
    value = format("%s-%s", var.node_name, var.environment)
  }

  tags {
    key   = "kubernetes.io/cluster/${var.cluster_name}"
    value = "owned"
  }

  iam_instance_profile                               = var.node-role
  health_check_type                                  = "K8S_NODE"
  health_check_grace_period                          = 300
  health_check_unhealthy_duration_before_replacement = 120
  placement_tenancy                                  = "default"
  preferred_availability_zones                       = var.preferred_availability_zones
  integration_kubernetes {
    integration_mode         = "pod"
    cluster_identifier       = var.cluster_name
    autoscale_is_enabled     = var.autoscale_is_enabled
    autoscale_is_auto_config = var.autoscale_is_auto_config
    autoscale_labels {
      key   = "node.group"
      value = "${var.node_name}-${var.environment}"
    }
  }

  region = data.aws_region.current.name

}
