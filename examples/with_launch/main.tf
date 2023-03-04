module "iam-eks" {
  source = "github.com/Emerson89/eks-terraform.git//iam-eks?ref=main"

  cluster_name = var.cluster_name
  environment  = var.environment

}

module "eks-master" {
  source = "github.com/Emerson89/eks-terraform.git//master?ref=main"

  cluster_name            = var.cluster_name
  master-role             = module.iam-eks.master-iam-arn
  kubernetes_version      = var.kubernetes_version
  subnet_ids              = ["subnet-abcabcabc", "subnet-abcabcabc"]
  security_group_ids      = ["sg-abcabcabc"]
  environment             = var.environment
  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access
  addons                  = local.addons

}


module "eks-node-infra" {
  source = "github.com/Emerson89/eks-terraform.gi//nodes?ref=main"

  cluster_name    = module.eks-master.cluster_name
  cluster_version = module.eks-master.cluster_version
  node-role       = module.iam-eks.node-iam-arn
  private_subnet  = module.vpc.private_ids
  node_name       = "infra"
  desired_size    = 4
  max_size        = 4
  min_size        = 1
  environment     = var.environment
  instance_types  = ["t3.micro"]
  create_node     = true

  ## Vars launch-template if var.create_launch = true

  launch_create         = true
  name                  = "lt-infra"
  security-group-node   = ["sg-abcabcabc"]
  endpoint              = module.eks-master.cluster_endpoint
  certificate_authority = module.eks-master.cluster_cert

  tags = local.applied_tags

}
