provider "aws" {
  profile = var.profile
  region  = "us-east-1"
}

provider "kubernetes" {
  host                   = module.eks-master.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks-master.cluster_cert)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks-master.cluster_name, "--profile", var.profile]
    command     = "aws"
  }
}