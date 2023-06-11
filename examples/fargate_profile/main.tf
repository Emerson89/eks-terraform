locals {
  environment  = "stg"
  cluster_name = "k8s"
}

module "fargate-profile" {
  source = "github.com/Emerson89/eks-terraform.git//nodes?ref=main"

  environment  = local.environment
  create_node  = false
  cluster_name = local.cluster_name

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
