locals {
  spot_tags = concat([
    {
      key   = "Name"
      value = format("%s-%s", var.node_name, var.environment)
    },
    {
      key   = "kubernetes.io/cluster/${var.cluster_name}"
      value = "owned"
    },
    ],
  var.spotinst_tags)
}
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
  orientation                = var.orientation
  draining_timeout           = var.draining_timeout
  utilize_reserved_instances = var.utilize_reserved_instances
  fallback_to_ondemand       = var.fallback_to_ondemand

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device
    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", true)
      device_name           = lookup(ebs_block_device.value, "device_name", "/dev/xvda")
      encrypted             = lookup(ebs_block_device.value, "encrypted", false)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      kms_key_id            = lookup(ebs_block_device.value, "kms_key_id", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", "")
      volume_size           = lookup(ebs_block_device.value, "volume_size", 20)
      volume_type           = lookup(ebs_block_device.value, "volume_type", "gp3")
      throughput            = lookup(ebs_block_device.value, "throughput", null)
    }
  }

  revert_to_spot {
    perform_at   = var.perform_at
    time_windows = var.time_windows
  }

  desired_capacity              = var.desired_size
  min_size                      = var.min_size
  max_size                      = var.max_size
  capacity_unit                 = var.capacity_unit
  instance_types_ondemand       = var.instance_types_ondemand
  instance_types_spot           = var.instance_types_spot
  instance_types_preferred_spot = var.instance_types_preferred_spot
  subnet_ids                    = var.private_subnet
  product                       = var.product
  security_groups               = var.security-group-node
  enable_monitoring             = var.enable_monitoring
  ebs_optimized                 = var.ebs_optimized
  cpu_credits                   = var.cpu_credits
  image_id                      = var.image_id != "" ? var.image_id : data.aws_ami.eks-worker[0].id
  user_data = base64encode(<<-EOT
                                  #!/bin/bash
                                  set -o xtrace
                                  /etc/eks/bootstrap.sh --apiserver-endpoint '${var.endpoint}' --b64-cluster-ca '${var.certificate_authority}' '${var.cluster_name}' --kubelet-extra-args '${var.taints_lt} ${var.labels_lt}'
                                  EOT
  )

  dynamic "instance_types_weights" {
    for_each = var.instance_types_weights
    content {
      instance_type = instance_types_weights.value.instance_type
      weight        = instance_types_weights.value.weight
    }
  }

  dynamic "tags" {
    for_each = local.spot_tags

    content {
      key   = tags.value.key
      value = tags.value.value
    }
  }

  iam_instance_profile                               = var.node-role
  health_check_type                                  = var.health_check_type
  health_check_grace_period                          = var.health_check_grace_period
  health_check_unhealthy_duration_before_replacement = var.health_check_unhealthy_duration_before_replacement
  placement_tenancy                                  = var.placement_tenancy
  preferred_availability_zones                       = var.preferred_availability_zones

  integration_kubernetes {
    integration_mode         = "pod"
    cluster_identifier       = var.cluster_name
    autoscale_is_enabled     = var.autoscale_is_enabled
    autoscale_is_auto_config = var.autoscale_is_auto_config
    dynamic "autoscale_labels" {
      for_each = var.autoscale_labels
      content {
        key   = try(autoscale_labels.value.key, "node.group")
        value = "${var.node_name}-${var.environment}"
      }
    }
  }

  region = data.aws_region.current.name

}
