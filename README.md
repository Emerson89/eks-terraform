# EKS Terraform 

Some of the addon/controller policies that are currently supported include:

- [EBS-CSI-DRIVER](#https://github.com/kubernetes-sigs/aws-ebs-csi-driver)
- [Cluster Autoscaler](#https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler)
- [External DNS](#https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns)
- [Load Balancer Controller](#https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/helm/aws-load-balancer-controller/README.md)
- [Metrics-Server](#https://github.com/helm/charts/tree/master/stable/metrics-server)

### Addons EKS 

- [kube-proxy](#kube-proxy)
- [vpc-cni](#vpc-cni)
- [core](#core)
- [ebs](#ebs)
#
## Usage

```hcl
module "eks" {
  source = "github.com/Emerson89/eks-terraform.git?ref=v1.0.0"

  cluster_name            = "k8s"
  kubernetes_version      = "1.23"
  subnet_ids              = ["subnet-abcabc123","subnet-abcabc123","subnet-abcabc123"]
  security_group_ids      = ["sg-abcabc123"]
  environment             = "stg"
  endpoint_private_access = true
  endpoint_public_access  = true
  ##Create aws-auth
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  ## AWS-AUTH
  mapRoles = [
    {
      rolearn  = "arn:aws:iam::xxxxxxxxxxxx:role/role-access"
      username = "role-access"
      groups   = ["read-only"] ## Group create rbac
    }
  ]
  mapUsers = [
    {
      userarn  = "arn:aws:iam::xxxxxxxxxxxx:user/test"
      username = "test"
      groups   = ["Admin"] ## Group create rbac

    }
  ]
  ## Addons EKS
  create_ebs     = false
  create_core    = false
  create_vpc_cni = false
  create_proxy   = false

  ## Controller EBS Helm
  aws-ebs-csi-driver = true

  ## Configuration custom values
  #custom_values_ebs = {
  #  values = [templatefile("${path.module}/values-ebs.yaml", {
  #    aws_region   = "us-east-1"
  #    cluster_name = "k8s"
  #    name         = "aws-ebs-csi-driver-stg"
  #  })]
  #}

  ## External DNS 

  external-dns = true
  domain       = "domain.io" ## Variable obrigatory for external dns

  ## Controller ASG
  aws-autoscaler-controller = true

  ## Controller ALB

  aws-load-balancer-controller = true
  custom_values_alb = {
    set = [
      {
        name  = "nodeSelector.Environment"
        value = "prd"
      },
      {
        name  = "vpcId" ## Variable obrigatory for controller alb
        value = "vpc-abcdabcd123
      },
      {
        name  = "tolerations[0].key"
        value = "key1"
      },
      {
        name  = "tolerations[0].operator"
        value = "Equal"
      },
      {
        name  = "tolerations[0].value"
        value = "prd"
      },
      {
        name  = "tolerations[0].effect"
        value = "NoSchedule"
      }
    ]
  }

  ## CUSTOM_HELM

  custom_helm = {
    aws-secrets-manager = {
      "name"             = "aws-secrets-manager"
      "namespace"        = "kube-system"
      "repository"       = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
      "chart"            = "secrets-store-csi-driver-provider-aws"
      "version"          = "" ## When empty, the latest version will be installed
      "create_namespace" = false

      "values" = [] ## When empty, default values will be used
    }
  }

  ## RBAC
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

  ## NODES
  nodes = {
    ## Manager nodes
    infra = {
      create_node     = true
      node_name       = "infra"
      cluster_version = "1.23"
      desired_size    = 1
      max_size        = 2
      min_size        = 1
      instance_types  = ["t3.medium"]
      disk_size       = 20
      capacity_type  = "SPOT"
      labels = {
        Environment = "stg"
      }
      taints = {
        dedicated = {
          key    = "environment"
          value  = "stg"
          effect = "NO_SCHEDULE"
        }
      }
    }

    ## Used launch template
    infra-lt = {
      create_node           = true
      launch_create         = true
      name_lt               = "lt"
      node_name             = "infra-lt"
      cluster_version       = "1.23"
      desired_size          = 1
      max_size              = 2
      min_size              = 1
      instance_types_launch = "t3.micro"
      volume-size           = 20
      volume-type           = "gp3"

      labels = {
        Environment = "stg"
      }

      taints = {
        dedicated = {
          key    = "environment"
          value  = "stg"
          effect = "NO_SCHEDULE"
        }
      }
    }

    ## Fargate profile

    infra-fargate = {
      create_node          = false
      create_fargate       = true
      fargate_profile_name = "infra-fargate"
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
    }

    ## Self manager nodes

    infra-asg = {
      create_node           = false
      launch_create         = true
      asg_create            = true
      cluster_version       = "1.23"
      name_lt               = "lt-asg"
      desired_size          = 1
      max_size              = 2
      min_size              = 1
      instance_types_launch = "t3.medium"
      volume-size           = 20
      volume-type           = "gp3"
      taint_lt              = "--register-with-taints=dedicated=stg:NoSchedule"
      labels_lt             = "--node-labels=eks.amazonaws.com/nodegroup=infra"
      name_asg              = "infra"
      vpc_zone_identifier   = ["subnet-abacabc123","subnet-abacabc123","subnet-abcabac123"]
      asg_tags = [
        {
          key                 = "Environment"
          value               = "stg"
          propagate_at_launch = true
        },
        {
          key                 = "Name"
          value               = "infra"
          propagate_at_launch = true
        },
        {
          key                 = "kubernetes.io/cluster/k8s"
          value               = "owner"
          propagate_at_launch = true
        },
      ]
    } 
  }

  private_subnet = ["subnet-abcabc123","subnet-abcabc123","subnet-abcabc123"]

  tags = {
    Enviroment = "stg"
  }

}
```

## For other examples access 

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.72 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.10.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.21.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.72 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.21.1 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | ./modules/helm | n/a |
| <a name="module_asg"></a> [asg](#module\_asg) | ./modules/helm | n/a |
| <a name="module_core"></a> [core](#module\_core) | ./modules/addons | n/a |
| <a name="module_custom"></a> [custom](#module\_custom) | ./modules/helm | n/a |
| <a name="module_ebs"></a> [ebs](#module\_ebs) | ./modules/addons | n/a |
| <a name="module_ebs-helm"></a> [ebs-helm](#module\_ebs-helm) | ./modules/helm | n/a |
| <a name="module_external-dns"></a> [external-dns](#module\_external-dns) | ./modules/helm | n/a |
| <a name="module_iam-alb"></a> [iam-alb](#module\_iam-alb) | ./modules/iam | n/a |
| <a name="module_iam-asg"></a> [iam-asg](#module\_iam-asg) | ./modules/iam | n/a |
| <a name="module_iam-ebs"></a> [iam-ebs](#module\_iam-ebs) | ./modules/iam | n/a |
| <a name="module_metrics-server"></a> [metrics-server](#module\_metrics-server) | ./modules/helm | n/a |
| <a name="module_nodes"></a> [nodes](#module\_nodes) | ./modules/nodes | n/a |
| <a name="module_proxy"></a> [proxy](#module\_proxy) | ./modules/addons | n/a |
| <a name="module_rbac"></a> [rbac](#module\_rbac) | ./modules/rbac | n/a |
| <a name="module_vpc-cni"></a> [vpc-cni](#module\_vpc-cni) | ./modules/addons | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eks_cluster.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_iam_instance_profile.iam-node-instance-profile-eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_openid_connect_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_policy.amazon_eks_node_group_autoscaler_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.route53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.master](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.AmazonEKSClusterPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.AmazonEKSServicePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_nodes_autoscaler_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.route53_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [kubernetes_config_map.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map_v1_data.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1_data) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [tls_certificate.this](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws-autoscaler-controller"></a> [aws-autoscaler-controller](#input\_aws-autoscaler-controller) | Install release helm controller asg | `bool` | `false` | no |
| <a name="input_aws-ebs-csi-driver"></a> [aws-ebs-csi-driver](#input\_aws-ebs-csi-driver) | Install release helm controller ebs | `bool` | `false` | no |
| <a name="input_aws-load-balancer-controller"></a> [aws-load-balancer-controller](#input\_aws-load-balancer-controller) | Install release helm controller alb | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name cluster | `string` | `null` | no |
| <a name="input_create_aws_auth_configmap"></a> [create\_aws\_auth\_configmap](#input\_create\_aws\_auth\_configmap) | Create configmap aws-auth | `bool` | `false` | no |
| <a name="input_create_core"></a> [create\_core](#input\_create\_core) | Install addons core | `bool` | `false` | no |
| <a name="input_create_ebs"></a> [create\_ebs](#input\_create\_ebs) | Install addons ebs | `bool` | `false` | no |
| <a name="input_create_proxy"></a> [create\_proxy](#input\_create\_proxy) | Install addons proxy | `bool` | `false` | no |
| <a name="input_create_vpc_cni"></a> [create\_vpc\_cni](#input\_create\_vpc\_cni) | Install addons vpc\_cni | `bool` | `false` | no |
| <a name="input_custom_helm"></a> [custom\_helm](#input\_custom\_helm) | Custom a Release is an instance of a chart running in a Kubernetes cluster. | `map(any)` | `{}` | no |
| <a name="input_custom_values_alb"></a> [custom\_values\_alb](#input\_custom\_values\_alb) | Custom controler alb a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_custom_values_asg"></a> [custom\_values\_asg](#input\_custom\_values\_asg) | Custom controller asg a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_custom_values_ebs"></a> [custom\_values\_ebs](#input\_custom\_values\_ebs) | Custom controller ebs a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_custom_values_external-dns"></a> [custom\_values\_external-dns](#input\_custom\_values\_external-dns) | Custom external-dns a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_custom_values_metrics-server"></a> [custom\_values\_metrics-server](#input\_custom\_values\_metrics-server) | Custom metrics-server a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain used helm External dns | `string` | `""` | no |
| <a name="input_enabled_cluster_log_types"></a> [enabled\_cluster\_log\_types](#input\_enabled\_cluster\_log\_types) | List of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging. | `list(string)` | `[]` | no |
| <a name="input_endpoint_private_access"></a> [endpoint\_private\_access](#input\_endpoint\_private\_access) | Endpoint access private | `bool` | `false` | no |
| <a name="input_endpoint_public_access"></a> [endpoint\_public\_access](#input\_endpoint\_public\_access) | Endpoint access public | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Env tags | `string` | `null` | no |
| <a name="input_external-dns"></a> [external-dns](#input\_external-dns) | Install release helm external | `bool` | `false` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Version kubernetes | `string` | `"1.23"` | no |
| <a name="input_manage_aws_auth_configmap"></a> [manage\_aws\_auth\_configmap](#input\_manage\_aws\_auth\_configmap) | Manager configmap aws-auth | `bool` | `false` | no |
| <a name="input_mapAccounts"></a> [mapAccounts](#input\_mapAccounts) | List of accounts maps to add to the aws-auth configmap | `list(any)` | `[]` | no |
| <a name="input_mapRoles"></a> [mapRoles](#input\_mapRoles) | List of role maps to add to the aws-auth configmap | `list(any)` | `[]` | no |
| <a name="input_mapUsers"></a> [mapUsers](#input\_mapUsers) | List of user maps to add to the aws-auth configmap | `list(any)` | `[]` | no |
| <a name="input_master-role"></a> [master-role](#input\_master-role) | Role master | `string` | `""` | no |
| <a name="input_metrics-server"></a> [metrics-server](#input\_metrics-server) | Install release helm metrics-server | `bool` | `false` | no |
| <a name="input_node-role"></a> [node-role](#input\_node-role) | Role node | `string` | `null` | no |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | Custom controller ebs a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_private_subnet"></a> [private\_subnet](#input\_private\_subnet) | List subnet nodes | `list(any)` | `[]` | no |
| <a name="input_rbac"></a> [rbac](#input\_rbac) | Map rbac configuration | `any` | `{}` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Security group ids | `list(any)` | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet private | `list(any)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_cert"></a> [cluster\_cert](#output\_cluster\_cert) | n/a |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | n/a |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | n/a |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
| <a name="output_cluster_oidc"></a> [cluster\_oidc](#output\_cluster\_oidc) | n/a |
| <a name="output_cluster_version"></a> [cluster\_version](#output\_cluster\_version) | n/a |
| <a name="output_master-iam-arn"></a> [master-iam-arn](#output\_master-iam-arn) | n/a |
| <a name="output_master-iam-name"></a> [master-iam-name](#output\_master-iam-name) | n/a |
| <a name="output_node-iam-arn"></a> [node-iam-arn](#output\_node-iam-arn) | n/a |
| <a name="output_node-iam-name"></a> [node-iam-name](#output\_node-iam-name) | n/a |
| <a name="output_node-iam-name-profile"></a> [node-iam-name-profile](#output\_node-iam-name-profile) | n/a |
| <a name="output_oidc_arn"></a> [oidc\_arn](#output\_oidc\_arn) | n/a |
