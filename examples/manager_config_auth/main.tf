data "aws_eks_cluster" "this" {
  name = "eks_cluster_name"
}

data "aws_eks_cluster_auth" "this" {
  name = "eks_cluster_name"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}


## EKS

module "eks-master" {
  source = "github.com/Emerson89/eks-terraform.git?ref=v1.0.0"

  cluster_name            = local.cluster_name
  kubernetes_version      = "1.23"
  subnet_ids              = ["subnet-abcabcabc", "subnet-abcabcabc", "subnet-abdcabcd"]
  security_group_ids      = ["sg-abcdabcdabcd"]
  environment             = local.environment
  endpoint_private_access = true
  endpoint_public_access  = true

  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true
  mapRoles = [
    {
      rolearn  = "arn:aws:iam::xxxxxxxxxxxx:role/role-access"
      username = "role-access"
      groups   = ["read-only"] ## Group criado rbac
    }
  ]
  mapUsers = [
    {
      userarn  = "arn:aws:iam::xxxxxxxxxxxx:user/test"
      username = "test"
      groups   = ["Admin"] ## Group criado rbac

    }
  ]
}

module "rbac" {
  source = "github.com/Emerson89/eks-terraform.git//modules//rbac?ref=v1.0.0"

  rbac = {
    admin = {
      metadata = [{
        name = "admin-cluster-role"
        labels = {
          "kubernetes.io/bootstrapping" : "rbac-defaults"
        }
        annotations = {
          "rbac.authorization.kubernetes.io/autoupdate" : true
        }
      }]
      rules = [{
        api_groups = ["*"]
        verbs      = ["*"]
        resources  = ["*"]
      }]
      subjects = [{
        kind = "Group"
        name = "Admin"
      }]
    }
    read-only = {
      metadata = [{
        name = "read-only"
      }]
      rules = [{
        api_groups = [""]
        resources  = ["namespaces", "pods"]
        verbs      = ["get", "list", "watch"]
      }]
      subjects = [{
        kind = "Group"
        name = "read-only"
      }]
    }
    ServiceAccount = {
      service-account-create = true
      metadata = [{
        name = "svcaccount"
      }]
      rules = [{
        api_groups = [""]
        resources  = ["namespaces", "pods"]
        verbs      = ["get", "list", "watch"]
      }]
      subjects = [{
        kind      = "ServiceAccount"
        name      = "svcaccount"
        namespace = "kube-system"
      }]
    }
  }

}
