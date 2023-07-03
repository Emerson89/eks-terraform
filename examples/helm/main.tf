data "aws_eks_cluster" "this" {
  name = "eks_cluster_name"
}

data "aws_eks_cluster_auth" "this" {
  name = "eks_cluster_name"
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token

  }
}

odule "metrics-server" {
  source = "github.com/Emerson89/eks-terraform.git//modules//helm?ref=v1.0.0"

  helm_release = {

    name       = try(var.custom_values_metrics-server["name"], "metrics-server")
    namespace  = try(var.custom_values_metrics-server["namespace"], "kube-system")
    repository = "https://kubernetes-sigs.github.io/metrics-server/"
    chart      = "metrics-server"

    values = try(var.custom_values_metrics-server["values"], [])

  }

  set = try(var.custom_values_metrics-server["set"], {})

}