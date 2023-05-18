### SG

module "sg-cluster" {
  source = "github.com/Emerson89/terraform-modules.git//sg?ref=main"

  sgname                   = "eks_cluster_sg"
  environment              = local.environment
  vpc_id                   = "vpc-id"
  source_security_group_id = module.sg-node.sg_id

  ingress_with_source_security_group = local.ingress_cluster
  ingress_with_cidr_blocks           = local.ingress_cluster_api

  tags = local.tags
}

## EKS

module "iam-eks" {
  source = "github.com/Emerson89/modules-terraform.git//eks//iam-eks?ref=main"

  cluster_name = var.cluster_name
  environment  = local.environment

}

module "eks-master" {
  source = "github.com/Emerson89/modules-terraform.git//eks//master?ref=main"

  cluster_name            = var.cluster_name
  master-role             = module.iam-eks.master-iam-arn
  kubernetes_version      = var.kubernetes_version
  subnet_ids              = ["subnet-abcabcabc", "subnet-abcabcabc"]
  security_group_ids      = [module.sg-cluster.sg_id]
  environment             = local.environment
  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access

}


module "eks-node-infra" {
  source = "github.com/Emerson89/modules-terraform.git//eks//nodes?ref=main"

  cluster_name    = module.eks-master.cluster_name
  cluster_version = module.eks-master.cluster_version
  node-role       = module.iam-eks.node-iam-arn
  private_subnet  = ["subnet-abcabcabc", "subnet-abcabcabc"]
  node_name       = "infra"
  desired_size    = 4
  max_size        = 4
  min_size        = 1
  environment     = local.environment
  instance_types  = ["t3.micro"]
  create_node     = true

  tags = local.tags

}
