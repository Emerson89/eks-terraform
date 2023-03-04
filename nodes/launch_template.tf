resource "random_uuid" "custom" {}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-*"]
  }
  most_recent = true
  owners      = ["amazon"]
}

resource "aws_launch_template" "this" {
  count = var.launch_create ? 1 : 0

  name                   = format("%s-%s-%s", var.name, var.environment, random_uuid.custom.result)
  update_default_version = true

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.volume-size != "" ? var.volume-size : 20
      volume_type           = var.volume-type != "" ? var.volume-type : "gp3"
      delete_on_termination = true
    }
  }

  network_interfaces {
    delete_on_termination = true
    security_groups       = var.security-group-node

  }

  image_id      = data.aws_ami.eks-worker.id
  instance_type = var.instance_types_launch

  user_data = base64encode(<<-EOT
  #!/bin/bash
  set -o xtrace

  /etc/eks/bootstrap.sh \
  --apiserver-endpoint '${var.endpoint}' \
  --b64-cluster-ca '${var.certificate_authority}' \
  '${var.cluster_name}'
  EOT
  )

  tags = {
    Name        = format("%s-%s", var.name, random_uuid.custom.result)
    Environment = var.environment
    Platform    = "k8s"
    Type        = "node-launch-template"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = format("%s-node-%s", var.name, var.environment)
      Environment = var.environment
      Platform    = "k8s"
      Type        = "node"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name        = format("%s-node-%s-%s", var.name, var.environment, random_uuid.custom.result)
      Environment = var.environment
      Platform    = "k8s"
      Type        = "node"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

