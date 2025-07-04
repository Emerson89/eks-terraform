output "cluster_id" {
  value = aws_eks_cluster.eks_cluster.id
}

output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "cluster_version" {
  value = aws_eks_cluster.eks_cluster.version
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_cert" {
  value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "cluster_oidc" {
  value = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "oidc_arn" {
  value = aws_iam_openid_connect_provider.this.arn
}

output "oidc_url" {
  value = aws_iam_openid_connect_provider.this.url
}

output "master-iam-name" {
  value = aws_iam_role.master.name
}

output "master-iam-arn" {
  value = aws_iam_role.master.arn
}

output "node-iam-name" {
  value = aws_iam_role.node.name
}

output "node-iam-arn" {
  value = aws_iam_role.node.arn
}

output "node-iam-name-profile" {
  value = aws_iam_instance_profile.iam-node-instance-profile-eks.name
}

output "cluster_auth" {
  value = data.aws_eks_cluster_auth.this.token
}

output "cluster_service_cidr" {
  value = aws_eks_cluster.eks_cluster.kubernetes_network_config[0].service_ipv4_cidr
}