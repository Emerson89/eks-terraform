module "eks-addons" {
  source = "github.com/Emerson89/eks-terraform.git//modules//addons?ref=v1.0.0"

  eks_cluster_id  = "eks_cluster-id"
  openid_connect  = "aws_iam_openid_connect_provider-arn"
  openid_url      = "aws_iam_openid_connect_provider-url"
  cluster_version = "eks_cluster-version"

  addons = {
    "coredns" = {
      "name"           = "coredns"
      "serviceaccount" = "aws-node"
      "policy_arn"     = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    }
    "vpc-cni" = {
      "name"           = "vpc-cni"
      "serviceaccount" = "aws-node"
      "policy_arn"     = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    }
  }
}
