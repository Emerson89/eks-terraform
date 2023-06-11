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

module "eks-node-infra" {
  source = "github.com/Emerson89/eks-terraform.git//nodes?ref=main"

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
