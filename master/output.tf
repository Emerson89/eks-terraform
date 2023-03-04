output "cluster_id" {
  value = aws_eks_cluster.eks_cluster.id
}

output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "cluster_version" {
  value = aws_eks_cluster.eks_cluster.version
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_cert" {
  value = data.aws_eks_cluster.this.certificate_authority[0].data
}