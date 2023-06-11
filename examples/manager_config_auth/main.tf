provider "aws" {
  profile = var.profile
  region  = var.region
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_cert)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--profile", var.profile]
    command     = "aws"
  }
}

## EKS

module "iam-eks" {
  source = "github.com/Emerson89/eks-terraform.git//iam-eks?ref=main"

  cluster_name = local.cluster_name
  environment  = local.environment

}

module "eks-master" {
  source = "github.com/Emerson89/eks-terraform.git//master?ref=main"

  cluster_name            = local.cluster_name
  master-role             = module.iam-eks.master-iam-arn
  kubernetes_version      = "1.23"
  subnet_ids              = ["subnet-abcabcabc", "subnet-abcabcabc", "subnet-abdcabcd"]
  security_group_ids      = ["sg-abcdabcdabcd"]
  environment             = local.environment
  endpoint_private_access = true
  endpoint_public_access  = true

  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true
  node-role                 = module.iam-eks.node-iam-arn
  mapUsers = [
    {
      userarn  = "arn:aws:iam::xxxxxxxxxxxxxx:user/user@example.com"
      username = "user"
      groups   = ["system:masters"]

    },
    {
      userarn  = "arn:aws:iam::xxxxxxxxxxxxxx:user/user2@example.com"
      username = "user2"
      groups   = ["system:masters"]

    },
  ]
}

