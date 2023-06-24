resource "aws_iam_instance_profile" "iam-node-instance-profile-eks" {
  name = format("iam-node-instance-profile-eks-%s-%s", var.cluster_name, var.environment)
  role = aws_iam_role.node.name
}

resource "aws_iam_role" "node" {
  name = format("%s-%s-node-role", var.cluster_name, var.environment)

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  tags = merge(
    {
      "Name"     = format("%s-%s-node", var.cluster_name, var.environment)
      "Platform" = "k8s"
      "Type"     = "Roles"
    },
    var.tags,
  )
}


resource "aws_iam_role" "master" {
  name = format("%s-%s-role", var.cluster_name, var.environment)

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  tags = merge(
    {
      "Name"     = format("%s-%s-master", var.cluster_name, var.environment)
      "Platform" = "k8s"
      "Type"     = "Roles"
    },
    var.tags,
  )
}

resource "aws_iam_policy" "amazon_eks_node_group_autoscaler_policy" {

  name        = format("amazon_eks_node_group_autoscaler_policy-%s", var.cluster_name)
  path        = "/"
  description = "IAM Policy for EKS Node groups allowing to AutoScaling"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
  EOF
}

resource "aws_iam_role_policy_attachment" "eks_nodes_autoscaler_attachment" {
  policy_arn = aws_iam_policy.amazon_eks_node_group_autoscaler_policy.arn # Managed by Amazon
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.master.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}
