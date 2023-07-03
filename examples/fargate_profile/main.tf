locals {
  environment  = "stg"
  cluster_name = "k8s"
}

module "fargate-profile" {
  source = "github.com/Emerson89/eks-terraform.git//modules//nodes?ref=v1.0.0"

  environment    = local.environment
  create_node    = false
  cluster_name   = local.cluster_name
  private_subnet = "subnet-abdabdabd123"

  create_fargate = true
  selectors = [
    {
      namespace = "kube-system"
      labels = {
        k8s-app = "kube-dns"
      }
    },
    {
      namespace = "default"
    }
  ]

  tags = local.tags
}
