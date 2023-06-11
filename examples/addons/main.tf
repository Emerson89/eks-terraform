module "eks-master" {
  source = "github.com/Emerson89/modules-terraform.git//eks//master?ref=main"

  cluster_name            = "k8s"
  master-role             = "arn-abcdabcdabcd"
  kubernetes_version      = "1.23"
  subnet_ids              = ["subnet-abcabcabc", "subnet-abcabcabc", "subnet-abdcabcd"]
  security_group_ids      = ["sg-abcdabcdabcd"]
  environment             = local.environment
  endpoint_private_access = "true"
  endpoint_public_access  = "true"
  addons                  = local.addons

}
