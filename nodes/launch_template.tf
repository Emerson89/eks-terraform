resource "random_uuid" "custom" {}

data "aws_ami" "eks-worker" {
  count = var.launch_create ? 1 : 0
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
  
  iam_instance_profile {
    name = var.iam_instance_profile
  }
  
  image_id      = data.aws_ami.eks-worker[0].id
  instance_type = var.instance_types_launch

  user_data = base64encode(<<-EOT
  MIME-Version: 1.0
  Content-Type: multipart/mixed; boundary="//"
  
  --//
  Content-Type: text/x-shellscript; charset="us-ascii"
  #!/bin/bash
    
  if [ ${var.use-max-pods} = true ]; then
    /etc/eks/bootstrap.sh ${var.cluster_name} --b64-cluster-ca ${var.certificate_authority} --apiserver-endpoint ${var.endpoint} --use-max-pods=${var.use-max-pods}  --kubelet-extra-args '--max-pods=${var.max-pods}'
  else
    /etc/eks/bootstrap.sh ${var.cluster_name} --b64-cluster-ca ${var.certificate_authority} --apiserver-endpoint ${var.endpoint}
  fi
  --//--
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

