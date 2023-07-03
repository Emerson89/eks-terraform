locals {
  environment = "stg"
  tags = {
    Environment = "stg"
  }
}

module "eks-node-infra" {
  source = "github.com/Emerson89/eks-terraform.git//modules//nodes?ref=v1.0.0"

  cluster_name    = "k8s"
  cluster_version = "1.23"
  node-role       = "arn-abcabcdabcd"
  private_subnet  = ["subnet-abcabcabc", "subnet-abcabcabc", "subnet-abdcabcd"]
  node_name       = "infra"
  desired_size    = 1
  max_size        = 2
  min_size        = 1
  environment     = local.environment
  create_node     = true

  launch_create         = true
  name                  = "lt-infra"
  instance_types_launch = "t3.micro"
  volume-size           = 30

  network_interfaces = [
    {
      security_groups = ["sg-abcdabcdabcd"]
    }
  ]
  endpoint              = var.cluster_endpoint
  certificate_authority = var.cluster_ca_cert

  tags = local.tags

}
