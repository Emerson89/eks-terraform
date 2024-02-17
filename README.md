## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.9 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.10.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.20.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 4.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.9 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.20.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.4 |

Some of the addon/controller policies that are currently supported include:

- [EBS-CSI-DRIVER](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)
- [EFS-CSI-DRIVER](https://github.com/kubernetes-sigs/aws-efs-csi-driver)
- [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler)
- [External DNS](https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns)
- [Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/helm/aws-load-balancer-controller/README.md)
- [Metrics-Server](https://github.com/helm/charts/tree/master/stable/metrics-server)
- [Ingress-nginx](https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx)
- [Cert-manager](https://github.com/cert-manager/cert-manager/tree/master/deploy/charts/cert-manager)
- [Velero](https://github.com/vmware-tanzu/helm-charts/tree/main/charts/velero)
- [Karpenter](https://github.com/aws/karpenter-provider-aws/tree/main/charts/karpenter)

### Addons EKS 

- [kube-proxy](#kube-proxy)
- [vpc-cni](#vpc-cni)
- [core](#core)
- [ebs](#ebs)

#
## Usage
#
```hcl
module "eks" {
  source = "github.com/Emerson89/eks-terraform.git?ref=v1.0.6"

  cluster_name            = local.cluster_name
  kubernetes_version      = "1.24"
  subnet_ids              = concat(tolist(module.vpc.private_ids), tolist(module.vpc.public_ids))
  environment             = local.environment
  endpoint_private_access = true
  endpoint_public_access  = true

  ## Additional security-group cluster **Required karpenter**
  security_additional = false
  vpc_id              = module.vpc.vpc_id
  ## additional rules segurity group 
  ### additional_rules_security_group = {
  #   # Karpenter
  #   ingress_cluster_8443_webhook = {
  #     description                   = "Cluster API to node 8443/tcp webhook"
  #     protocol                      = "tcp"
  #     from_port                     = 8443
  #     to_port                       = 8443
  #     type                          = "ingress"
  #     source_cluster_security_group = true
  #   }
  #   # ALB controller, NGINX
  #   ingress_cluster_9443_webhook = {
  #     description                   = "Cluster API to node 9443/tcp webhook"
  #     protocol                      = "tcp"
  #     from_port                     = 9443
  #     to_port                       = 9443
  #     type                          = "ingress"
  #     source_cluster_security_group = true
  #   }
  # }

  private_subnet = module.vpc.private_ids

  tags = local.tags_eks

  ## Addons EKS
  create_ebs     = false
  create_core    = false
  create_vpc_cni = false
  create_proxy   = false
  
  ## Configuration custom values recommendation to use "set"

  ## Velero
  velero = false

  ## Controller ingress-nginx
  ingress-nginx = false

  ## Cert-manager
  cert-manager = false

  ## EFS controller
  aws-efs-csi-driver = false
  filesystem_id      = "fs-92107410"

  ## Controller EBS Helm
  aws-ebs-csi-driver = false

  ## Configuration custom values recommendation to use "set"
  # custom_values_ebs = {
  #   set = [
  #     {
  #       name  = "resources.requests.cpu"
  #       value = "10m"
  #     },
  #     {
  #       name  = "resources.requests.memory"
  #       value = "40Mi"
  #     }
  #   ]
  # }

  ## External DNS 
  external-dns = false

  ## Controller ASG
  aws-autoscaler-controller = false

  ## karpenter ASG test v1.24 k8s
  karpenter         = false
  version_karpenter = "v0.34.0"

  ## Controller ALB
  aws-load-balancer-controller = false

  ## Custom values
  custom_values_alb = {
    set = [
      {
        name  = "vpcId" ## Variable obrigatory for controller alb
        value = module.vpc.vpc_id
      },
      {
        name  = "tag"
        value = "v2.5.4"
      },
      # {
      #   name  = "nodeSelector.Environment"
      #   value = "hmg"
      # },
      # {
      #   name  = "tolerations[0].key"
      #   value = "environment"
      # },
      # {
      #   name  = "tolerations[0].operator"
      #   value = "Equal"
      # },
      # {
      #   name  = "tolerations[0].value"
      #   value = "hmg"
      # },
      # {
      #   name  = "tolerations[0].effect"
      #   value = "NoSchedule"
      # }
    ]
  }

  ## CUSTOM_HELM

  custom_helm = {
    aws-secrets-manager = {
      name             = "aws-secrets-manager"
      namespace        = "kube-system"
      repository       = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
      chart            = "secrets-store-csi-driver-provider-aws"
      version          = "0.3.4"
      create_namespace = false
      #values = file("${path.module}/values.yaml")
      values = []
    }
    secret-csi = {
      name             = "secret-csi"
      namespace        = "kube-system"
      repository       = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
      chart            = "secrets-store-csi-driver"
      version          = "v1.3.4"
      create_namespace = false
      #values = file("${path.module}/values.yaml")
      values = []
    }
  }

  ## GROUPS NODES
  nodes = {
    infra = {
      create_node             = false
      node_name               = "infra"
      cluster_version_manager = "1.24"
      desired_size            = 1
      max_size                = 3
      min_size                = 1
      instance_types          = ["t3.medium"]
      disk_size               = 20
      capacity_type           = "SPOT"
    }

    infra-lt = {
      create_node           = false
      launch_create         = false
      name_lt               = "lt"
      node_name             = "infra-lt"
      cluster_version       = "1.24"
      desired_size          = 1
      max_size              = 3
      min_size              = 1
      instance_types_launch = "t3.medium"
      volume-size           = 20
      volume-type           = "gp3"

      labels = {
        Environment = "${local.environment}"
      }

      taints = {
        dedicated = {
          key    = "environment"
          value  = "${local.environment}"
          effect = "NO_SCHEDULE"
        }
      }
    }

    infra-fargate = {
      create_node          = false
      create_fargate       = false
      fargate_auth         = false
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
    infra-asg = {
      create_node           = false
      launch_create         = false
      asg_create            = false
      cluster_version       = "1.24"
      name_lt               = "lt-asg"
      desired_size          = 1
      max_size              = 2
      min_size              = 1
      instance_types_launch = "t3.medium"
      volume-size           = 20
      volume-type           = "gp3"
      taints_lt             = "--register-with-taints=dedicated=${local.environment}:NoSchedule"
      labels_lt             = "--node-labels=eks.amazonaws.com/nodegroup=infra"
      name_asg              = "infra"
      vpc_zone_identifier   = "${module.vpc.private_ids}"
      asg_tags = [
        {
          key                 = "Environment"
          value               = "${local.environment}"
          propagate_at_launch = true
        },
        {
          key                 = "Name"
          value               = "${local.environment}"
          propagate_at_launch = true
        },
        {
          key                 = "kubernetes.io/cluster/${local.cluster_name}"
          value               = "owner"
          propagate_at_launch = true
        },
      ]
    }
  }

}
```

***Manager users, roles, accounts***

```hcl
  mapRoles = [
    {
      rolearn  = "arn:aws:iam::xxxxxxxxx:role/test"
      username = "test"
      groups   = ["system:masters"]
    }
  ]
  mapUsers = [
    {
      userarn  = "arn:aws:iam::xxxxxxxxxx:user/test"
      username = "test"
      groups   = ["system:masters"]
    }
  ]
  mapAccounts = [
    "777777777777",
  ]
```

***Manager rbac permissions***

```hcl
  mapRoles = [
    {
      rolearn  = "arn:aws:iam::xxxxxxxxx:role/test"
      username = "test"
      groups   = ["read-only"]
    }
  ]
  mapUsers = [
    {
      userarn  = "arn:aws:iam::xxxxxxxxxx:user/test"
      username = "test"
      groups   = ["adm"]
    }
  ]
  rbac = {
    admin = {
      metadata = [{
        name = "adm"
      }]
      rules = [{
        api_groups = ["*"]
        verbs      = ["*"]
        resources  = ["*"]
      }]
      subjects = [{
        kind = "Group"
        name = "adm"
      }]
    }
    read-only = {
      metadata = [{
        name = "read-only"
      }]
      rules = [{
        api_groups = ["*"]
        resources  = ["*"]
        verbs      = ["get", "list", "watch"]
      }]
      subjects = [{
        kind = "Group"
        name = "read-only"
      }]
    }
  }
```

*Service account*

```hcl
rbac = {
    ServiceAccount = {
      service-account-create = true
      metadata = [{
        name = "svcaccount"
      }]
      rules = [{
        api_groups = ["*"]
        resources  = ["*"]
        verbs      = ["get", "list", "watch"]
      }]
      subjects = [{
        kind      = "ServiceAccount"
        name      = "svcaccount"
        namespace = "kube-system"
      }]
    }
  }
```

***Only Self manager nodes***

```hcl
module "eks" {
  source = "github.com/Emerson89/eks-terraform.git?ref=v1.0.6"

  cluster_name            = "k8s"
  kubernetes_version      = "1.23"
  subnet_ids              = ["subnet-abcabc123","subnet-abcabc123","subnet-abcabc123"]
  environment             = "hmg"
  endpoint_private_access = true
  endpoint_public_access  = true
  
  ##Create aws-auth
  create_aws_auth_configmap = true ## Necessary for self-management nodes

  nodes = {
    infra-asg = {
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
}
```

***Karpenter ASG***

```hcl
module "eks" {
  source = "github.com/Emerson89/eks-terraform.git?ref=v1.0.6"

  ...
  ## Additional security-group cluster **Required karpenter**
  security_additional = true
  vpc_id              = module.vpc.vpc_id
  
  ## Add tags to subnets and security groups
  ## use the eks "tags" variable to add to the security group 
  
  tags_eks = {
    ## Required karpenter
    "karpenter.sh/discovery" = "<cluster_name>"
  }

  ## karpenter ASG test v1.24 k8s
  karpenter         = true
  version_karpenter = "v0.34.0"
  ...

}
``` 

- **Example of use**

```yaml
cat <<EOF | envsubst | kubectl apply -f -
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: node.kubernetes.io/instance-type
          operator: In
          values:
            - t3.micro
            - t3.small
            - t3.medium
      nodeClassRef:
        name: default
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 720h # 30 * 24h = 720h
---
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  # Required, resolves a default ami and userdata
  amiFamily: AL2 # Amazon Linux 2
  role: "<ROLE-NODE-NAME>" # replace with your cluster name
  # Required, discovers subnets to attach to instances
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "<CLUSTER_NAME>" # replace with your cluster name
  # Required, discovers security groups to attach to instances
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "<CLUSTER_NAME>" # replace with your cluster name
EOF

## https://karpenter.sh/v0.32/concepts/

## https://github.com/aws/karpenter-provider-aws/tree/main/examples/workloads
```

***Fargate profile***

```hcl
nodes = {
  infra-fargate = {
    create_fargate       = true
    fargate_auth         = true
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
}
```
#
## For update eks

```
terraform apply -target module.eks.aws_eks_cluster.eks_cluster
```
#
#
## For other examples access
#

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | ./modules/helm | n/a |
| <a name="module_asg"></a> [asg](#module\_asg) | ./modules/helm | n/a |
| <a name="module_cert-helm"></a> [cert-helm](#module\_cert-helm) | ./modules/helm | n/a |
| <a name="module_core"></a> [core](#module\_core) | ./modules/addons | n/a |
| <a name="module_custom"></a> [custom](#module\_custom) | ./modules/helm | n/a |
| <a name="module_ebs"></a> [ebs](#module\_ebs) | ./modules/addons | n/a |
| <a name="module_ebs-helm"></a> [ebs-helm](#module\_ebs-helm) | ./modules/helm | n/a |
| <a name="module_efs-helm"></a> [efs-helm](#module\_efs-helm) | ./modules/helm | n/a |
| <a name="module_external-dns"></a> [external-dns](#module\_external-dns) | ./modules/helm | n/a |
| <a name="module_iam-alb"></a> [iam-alb](#module\_iam-alb) | ./modules/iam | n/a |
| <a name="module_iam-asg"></a> [iam-asg](#module\_iam-asg) | ./modules/iam | n/a |
| <a name="module_iam-ebs"></a> [iam-ebs](#module\_iam-ebs) | ./modules/iam | n/a |
| <a name="module_iam-efs"></a> [iam-efs](#module\_iam-efs) | ./modules/iam | n/a |
| <a name="module_iam-karpenter"></a> [iam-karpenter](#module\_iam-karpenter) | ./modules/iam | n/a |
| <a name="module_iam-velero"></a> [iam-velero](#module\_iam-velero) | ./modules/iam | n/a |
| <a name="module_ingress-helm"></a> [ingress-helm](#module\_ingress-helm) | ./modules/helm | n/a |
| <a name="module_karpenter"></a> [karpenter](#module\_karpenter) | ./modules/helm | n/a |
| <a name="module_metrics-server"></a> [metrics-server](#module\_metrics-server) | ./modules/helm | n/a |
| <a name="module_nodes"></a> [nodes](#module\_nodes) | ./modules/nodes | n/a |
| <a name="module_proxy"></a> [proxy](#module\_proxy) | ./modules/addons | n/a |
| <a name="module_rbac"></a> [rbac](#module\_rbac) | ./modules/rbac | n/a |
| <a name="module_velero"></a> [velero](#module\_velero) | ./modules/helm | n/a |
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
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.AmazonEKSClusterPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.AmazonEKSFargatePodExecutionRolePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.AmazonEKSServicePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.AmazonEKSVPCResourceController](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.AmazonSSMManagedInstanceCore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ElasticLoadBalancingReadOnly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_nodes_autoscaler_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.route53_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.with_source_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [kubernetes_config_map.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map_v1_data.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1_data) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_ssm_parameter.eks_ami_release_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [tls_certificate.this](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_rules_security_group"></a> [additional\_rules\_security\_group](#input\_additional\_rules\_security\_group) | Rules extras security group | `any` | `{}` | no |
| <a name="input_aws-autoscaler-controller"></a> [aws-autoscaler-controller](#input\_aws-autoscaler-controller) | Install release helm controller asg | `bool` | `false` | no |
| <a name="input_aws-ebs-csi-driver"></a> [aws-ebs-csi-driver](#input\_aws-ebs-csi-driver) | Install release helm controller ebs | `bool` | `false` | no |
| <a name="input_aws-efs-csi-driver"></a> [aws-efs-csi-driver](#input\_aws-efs-csi-driver) | Install release helm controller efs | `bool` | `false` | no |
| <a name="input_aws-load-balancer-controller"></a> [aws-load-balancer-controller](#input\_aws-load-balancer-controller) | Install release helm controller alb | `bool` | `false` | no |
| <a name="input_cert-manager"></a> [cert-manager](#input\_cert-manager) | Install release helm controller cert-manager | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name cluster | `string` | `"k8s"` | no |
| <a name="input_create_aws_auth_configmap"></a> [create\_aws\_auth\_configmap](#input\_create\_aws\_auth\_configmap) | Create configmap aws-auth | `bool` | `false` | no |
| <a name="input_create_core"></a> [create\_core](#input\_create\_core) | Install addons core | `bool` | `false` | no |
| <a name="input_create_ebs"></a> [create\_ebs](#input\_create\_ebs) | Install addons ebs | `bool` | `false` | no |
| <a name="input_create_proxy"></a> [create\_proxy](#input\_create\_proxy) | Install addons proxy | `bool` | `false` | no |
| <a name="input_create_vpc_cni"></a> [create\_vpc\_cni](#input\_create\_vpc\_cni) | Install addons vpc\_cni | `bool` | `false` | no |
| <a name="input_custom_helm"></a> [custom\_helm](#input\_custom\_helm) | Custom a Release is an instance of a chart running in a Kubernetes cluster. | `map(any)` | `{}` | no |
| <a name="input_custom_values_alb"></a> [custom\_values\_alb](#input\_custom\_values\_alb) | Custom controler alb a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_custom_values_asg"></a> [custom\_values\_asg](#input\_custom\_values\_asg) | Custom controller asg a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_custom_values_cert_manager"></a> [custom\_values\_cert\_manager](#input\_custom\_values\_cert\_manager) | Custom controler cert-manager a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_custom_values_ebs"></a> [custom\_values\_ebs](#input\_custom\_values\_ebs) | Custom controller ebs a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_custom_values_efs"></a> [custom\_values\_efs](#input\_custom\_values\_efs) | Custom controler efs a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_custom_values_external-dns"></a> [custom\_values\_external-dns](#input\_custom\_values\_external-dns) | Custom external-dns a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_custom_values_karpenter"></a> [custom\_values\_karpenter](#input\_custom\_values\_karpenter) | Custom karpenter a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_custom_values_metrics-server"></a> [custom\_values\_metrics-server](#input\_custom\_values\_metrics-server) | Custom metrics-server a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_custom_values_nginx"></a> [custom\_values\_nginx](#input\_custom\_values\_nginx) | Custom controler ingress-nginx a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_custom_values_velero"></a> [custom\_values\_velero](#input\_custom\_values\_velero) | Custom velero a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain used helm External dns | `string` | `""` | no |
| <a name="input_enabled_cluster_log_types"></a> [enabled\_cluster\_log\_types](#input\_enabled\_cluster\_log\_types) | List of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging. | `list(string)` | `[]` | no |
| <a name="input_endpoint_private_access"></a> [endpoint\_private\_access](#input\_endpoint\_private\_access) | Endpoint access private | `bool` | `false` | no |
| <a name="input_endpoint_public_access"></a> [endpoint\_public\_access](#input\_endpoint\_public\_access) | Endpoint access public | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Env tags | `string` | `null` | no |
| <a name="input_external-dns"></a> [external-dns](#input\_external-dns) | Install release helm external | `bool` | `false` | no |
| <a name="input_fargate_auth"></a> [fargate\_auth](#input\_fargate\_auth) | Auth role fargate profile | `bool` | `false` | no |
| <a name="input_filesystem_id"></a> [filesystem\_id](#input\_filesystem\_id) | Filesystem used helm efs | `string` | `"fs-92107410"` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Boolean that indicates all objects (including any locked objects) should be deleted from the bucket when the bucket is destroyed so that the bucket can be destroyed without error | `bool` | `false` | no |
| <a name="input_ingress-nginx"></a> [ingress-nginx](#input\_ingress-nginx) | Install release helm controller ingress-nginx | `bool` | `false` | no |
| <a name="input_karpenter"></a> [karpenter](#input\_karpenter) | Install release helm karpenter | `bool` | `false` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Version kubernetes | `string` | `"1.23"` | no |
| <a name="input_manage_aws_auth_configmap"></a> [manage\_aws\_auth\_configmap](#input\_manage\_aws\_auth\_configmap) | Manager configmap aws-auth | `bool` | `true` | no |
| <a name="input_mapAccounts"></a> [mapAccounts](#input\_mapAccounts) | List of accounts maps to add to the aws-auth configmap | `list(any)` | `[]` | no |
| <a name="input_mapRoles"></a> [mapRoles](#input\_mapRoles) | List of role maps to add to the aws-auth configmap | `list(any)` | `[]` | no |
| <a name="input_mapUsers"></a> [mapUsers](#input\_mapUsers) | List of user maps to add to the aws-auth configmap | `list(any)` | `[]` | no |
| <a name="input_metrics-server"></a> [metrics-server](#input\_metrics-server) | Install release helm metrics-server | `bool` | `false` | no |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | Custom controller ebs a Release is an instance of a chart running in a Kubernetes cluster | `any` | `{}` | no |
| <a name="input_private_subnet"></a> [private\_subnet](#input\_private\_subnet) | List subnet nodes | `list(any)` | `[]` | no |
| <a name="input_rbac"></a> [rbac](#input\_rbac) | Map rbac configuration | `any` | `{}` | no |
| <a name="input_security_additional"></a> [security\_additional](#input\_security\_additional) | Additional security grupo cluster | `bool` | `false` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Security group ids | `list(any)` | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet private | `list(any)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource | `map(string)` | `{}` | no |
| <a name="input_velero"></a> [velero](#input\_velero) | Install release helm velero | `bool` | `false` | no |
| <a name="input_version_karpenter"></a> [version\_karpenter](#input\_version\_karpenter) | Install release helm karpenter | `string` | `"v0.34.0"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC id | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_cert"></a> [cluster\_cert](#output\_cluster\_cert) | n/a |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | n/a |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | n/a |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
| <a name="output_cluster_oidc"></a> [cluster\_oidc](#output\_cluster\_oidc) | n/a |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | n/a |
| <a name="output_cluster_version"></a> [cluster\_version](#output\_cluster\_version) | n/a |
| <a name="output_master-iam-arn"></a> [master-iam-arn](#output\_master-iam-arn) | n/a |
| <a name="output_master-iam-name"></a> [master-iam-name](#output\_master-iam-name) | n/a |
| <a name="output_node-iam-arn"></a> [node-iam-arn](#output\_node-iam-arn) | n/a |
| <a name="output_node-iam-name"></a> [node-iam-name](#output\_node-iam-name) | n/a |
| <a name="output_node-iam-name-profile"></a> [node-iam-name-profile](#output\_node-iam-name-profile) | n/a |
| <a name="output_oidc_arn"></a> [oidc\_arn](#output\_oidc\_arn) | n/a |
