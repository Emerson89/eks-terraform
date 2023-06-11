module "eks-node-infra" {
  source = "github.com/Emerson89/eks-terraform.git//nodes?ref=main"

  cluster_name    = "k8s"
  cluster_version = "1.23"
  node-role       = "arn-abcdabcdabcd"
  private_subnet  = ["subnet-abcabcabc", "subnet-abcabcabc", "subnet-abdcabcd"]
  node_name       = "infra"
  desired_size    = 1
  max_size        = 2
  min_size        = 1
  environment     = "stg"
  instance_types  = ["t3.micro"]
  create_node     = true

  tags = {
    Environment = "stg"
  }

}
