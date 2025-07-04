## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.100.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | = 2.17.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.20.0 |
| <a name="requirement_spotinst"></a> [spotinst](#requirement\_spotinst) | >= 1.96.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 4.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.84.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.35.1 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
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

### Inputs

- [Node](https://github.com/Emerson89/eks-terraform/blob/main/modules/nodes/README.md)
- [Node-Spotinst](https://github.com/Emerson89/eks-terraform/blob/main/modules/nodes-spot/README.md) 

#
## Usage
#

**For basic execution go to examples/basic**

```hcl
module "eks" {
  source = "github.com/Emerson89/eks-terraform.git?ref=v2.0.0"

  cluster_name            = local.cluster_name
  kubernetes_version      = "1.33"
  subnet_ids              = concat(tolist(module.vpc.private_ids), tolist(module.vpc.public_ids))
  environment             = local.environment
  endpoint_private_access = true
  endpoint_public_access  = true
  
  public_access_cidrs = ["182.168.43.32/32"]
  
  private_subnet = [module.vpc.private_ids[0]]

  tags = local.tags_eks

  ## Controller ASG
  aws-autoscaler-controller = true
  
  ## Access Entry Configurations for an EKS Cluster.
  eks_access_entry = {
     test = {
       principal_arn = "arn:aws:iam::xxxxxxxxxxxx:user/test-user"
       type          = "STANDARD"

       policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

       access_scope = {
         test = {
           type = "cluster"
         }
       }
     }
  }

  ## GROUPS NODES
  nodes = {
    infra = {
      create_node             = true
      node_name               = "infra"
      cluster_version_manager = "1.33"
      desired_size            = 1
      max_size                = 5
      min_size                = 1
      instance_types          = ["t3.medium", "t3a.medium"]
      disk_size               = 20
      capacity_type           = "SPOT"
      ami_type                = "AL2023_x86_64_STANDARD"
    }
  }
}
```
#

**For complete execution go to examples/complete**

```hcl
module "eks" {
  source = "github.com/Emerson89/eks-terraform.git?ref=v2.0.0"
  
  ## Config provider spotinst
  enabled_provider_spotinst = true
  account_spotinst          = ""
  token                     = ""
  
  cluster_name            = local.cluster_name
  kubernetes_version      = "1.33"
  subnet_ids              = concat(tolist(module.vpc.private_ids), tolist(module.vpc.public_ids))
  environment             = local.environment
  endpoint_private_access = true
  endpoint_public_access  = true

  ## create_aws_auth_configmap **Required Self manager nodes and Spotinst**
  create_aws_auth_configmap = false
  manage_aws_auth_configmap = true

  authentication_mode                         = "CONFIG_MAP"
  bootstrap_cluster_creator_admin_permissions = true

  create_access_entry = false

  ## Additional security-group cluster **Required Spotinst**
  security_additional = true
  vpc_id              = module.vpc.vpc_id
  # additional_rules_security_group = {
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
  velero             = false
  create_bucket      = false           ## bucket name used by velero if "true" conflicts with bucket_name_velero
  #bucket_name_velero = "velero-123456" ## Bucket name already created for use in velero conflicts with create_bucket

  ## Controller ingress-nginx
  ingress-nginx = false
  ## Enable Snippet and internal
  # custom_values_nginx = {
  #   set = [
  #     {
  #       name  = "controller.service.type"
  #       value = "LoadBalancer"
  #     },
  #     {
  #       name  = "controller.allowSnippetAnnotations"
  #       value = "true"
  #     },
  #     {
  #       name  = "controller.service.external.enabled"
  #       value = "false"
  #     },
  #     {
  #       name  = "controller.service.internal.enabled"
  #       value = "true"
  #     },
  #     {
  #       name  = "controller.service.internal.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-internal"
  #       value = "true"
  #     }
  #   ]
  # }

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
  version_karpenter = "1.5.0"
  webhook_enabled   = true

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

  # custom_helm = {
  #   aws-secrets-manager = {
  #     name             = "aws-secrets-manager"
  #     namespace        = "kube-system"
  #     repository       = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  #     chart            = "secrets-store-csi-driver-provider-aws"
  #     version          = "0.3.4"
  #     create_namespace = false
  #     #values = file("${path.module}/values.yaml")
  #     values = []
  #   }
  #   secret-csi = {
  #     name             = "secret-csi"
  #     namespace        = "kube-system"
  #     repository       = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  #     chart            = "secrets-store-csi-driver"
  #     version          = "v1.3.4"
  #     create_namespace = false
  #     #values = file("${path.module}/values.yaml")
  #     values = []
  #   }
  # }

  ## GROUPS NODES
  nodes = {
    infra = {
      create_node             = false
      node_name               = "infra"
      cluster_version_manager = "1.33"
      desired_size            = 1
      max_size                = 5
      min_size                = 1
      instance_types          = ["t3.medium", "t3a.medium"]
      disk_size               = 20
      capacity_type           = "SPOT"
      release_version         = "1.28.5-20240227" ## If empty, update ami if available
      ami_type                = "AL2023_x86_64_STANDARD"
    }

    infra-lt = {
      create_node           = false
      launch_create         = false
      name_lt               = "lt"
      node_name             = "infra-lt"
      cluster_version       = "1.33"
      desired_size          = 1
      max_size              = 3
      min_size              = 1
      instance_types_launch = "t3.medium"
      volume-size           = 20
      volume-type           = "gp3"
      image_id              = "ami-0df33cb954c3f5200" ## If empty, update ami if available
      ami_type              = "AL2023_x86_64_STANDARD"

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
      cluster_version       = "1.28"
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

  nodes_spot = {

    spotinst = {
      create_node_spotinst = false

      node_name                    = "spotinst"
      cluster_version              = "1.28"
      desired_size                 = 1
      max_size                     = 3
      min_size                     = 1
      preferred_availability_zones = ["us-east-1c"]
      instance_types_spot          = ["t3.medium", "t3a.medium"]
      spot_percentage              = 100
      taints_lt                    = "--register-with-taints=dedicated=${local.environment}:NoSchedule"
      labels_lt                    = "--node-labels=eks.amazonaws.com/nodegroup=spotinst"
      image_id                     = "ami-0df33cb954c3f5200" ## If empty, update ami if available
      ebs_block_device = [
        {
          volume_type = "gp3"
          volume_size = 20
        },
      ]
      spotinst_tags = [
        {
          key   = "Environment"
          value = "${local.environment}"
        }
      ]
    }
  }
}
```
#

**Addon Velero**

*If you want to create a bucket, just use the variable **create_bucket=true***

```
velero             = true
create_bucket      = true ## bucket name used by velero if "true" conflicts with bucket_name_velero
```

*If you want to use a bucket that has already been created, just use the variable **bucket_name_velero** conflicts with create_bucket*.

``` 
bucket_name_velero = "velero-123456" ## Bucket name already created for use in velero conflicts with create_bucket
```
#
**Manager users, roles, accounts**

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

**Manager rbac permissions**

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
#
***Only Self manager nodes***

```hcl
module "eks" {
  source = "github.com/Emerson89/eks-terraform.git?ref=v2.0.0"

  cluster_name            = "k8s"
  kubernetes_version      = "1.28"
  subnet_ids              = ["subnet-abcabc123","subnet-abcabc123","subnet-abcabc123"]
  environment             = "hmg"
  endpoint_private_access = true
  endpoint_public_access  = true
  
  ##Create aws-auth
  create_aws_auth_configmap = true ## Necessary for self-management nodes
  manage_aws_auth_configmap = false
  
  create_access_entry                         = false
  authentication_mode                         = "CONFIG_MAP"
  bootstrap_cluster_creator_admin_permissions = true

  security_additional = true ## Necessary for self-management nodes
  vpc_id              = module.vpc.vpc_id

  nodes = {
    infra-asg-spot = {
      launch_create              = false
      asg_create                 = false
      cluster_version            = "1.32"
      name_lt                    = "lt-asg"
      desired_size               = 1
      max_size                   = 2
      min_size                   = 1
      instance_types_launch      = "t3.medium"
      volume-size                = 20
      volume-type                = "gp3"
      taints_lt                  = "--register-with-taints=dedicated=${local.environment}:NoSchedule"
      labels_lt                  = "--node-labels=eks.amazonaws.com/nodegroup=infra"
      name_asg                   = "infra"
      vpc_zone_identifier        = module.vpc.private_ids
      capacity_rebalance         = true
      default_cooldown           = 300
      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 0
          spot_allocation_strategy                 = "price-capacity-optimized"
          spot_instance_pools                      = 0
        }
        override = [
          {
            instance_type = "t3.micro"
          },
          {
            instance_type = "t3a.micro"
          }
        ]

      }

      termination_policies = ["AllocationStrategy", "OldestLaunchTemplate", "OldestInstance"]
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
#
***Karpenter ASG***

```hcl
module "eks" {
  source = "github.com/Emerson89/eks-terraform.git?ref=v1.0.11"

  ...
  ## karpenter ASG test v1.24 k8s
  karpenter         = true
  version_karpenter = "v0.34.0"
  ...

}
``` 

- **Example of use < 0.36**

```yaml
cat <<EOF | envsubst | kubectl apply -f -
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    metadata:
      labels:
        Environment: "aplication"
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
      taints:
        - key: "environment"
          effect: "NoSchedule" 
          value: "aplication"  
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
        #karpenter.sh/discovery: "<CLUSTER_NAME>" # replace with your cluster name
        kubernetes.io/cluster/<CLUSTER_NAME>: shared
  # Required, discovers security groups to attach to instances
  securityGroupSelectorTerms:
    - tags:
        #karpenter.sh/discovery: "<CLUSTER_NAME>" # replace with your cluster name
        aws:eks:cluster-name: "<CLUSTER_NAME>"
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
**Only Self manager nodes spotinst require create account https://console.spotinst.com/spt/auth/signIn**
***Configuration provider https://registry.terraform.io/providers/spotinst/spotinst/latest/docs***

- Set provider

```hcl
provider "spotinst" {
  enabled = true ##Boolean value to enable or disable the provider.

  token   = ""
  account = ""
}
```
#
```hcl
module "eks" {
  source = "github.com/Emerson89/eks-terraform.git?ref=v2.0.0"

  cluster_name            = "k8s"
  kubernetes_version      = "1.32"
  subnet_ids              = ["subnet-abcabc123","subnet-abcabc123","subnet-abcabc123"]
  environment             = "hmg"
  endpoint_private_access = true
  endpoint_public_access  = true
  
  ##Create aws-auth
  create_aws_auth_configmap = true ## Necessary for self-management nodes and spotinst
  manage_aws_auth_configmap = false

  create_access_entry                         = false
  authentication_mode                         = "CONFIG_MAP"
  bootstrap_cluster_creator_admin_permissions = true


  security_additional = true ## Necessary for self-management nodes and spotinst
  vpc_id              = module.vpc.vpc_id

  ## GROUPS NODES
  nodes_spot = {

    spotinst = {
      create_node_spotinst = true

      node_name                    = "spotinst"
      cluster_version              = "1.24"
      desired_size                 = 1
      max_size                     = 3
      min_size                     = 1
      preferred_availability_zones = ["us-east-1c"]
      instance_types_spot          = ["t3.medium", "t3a.medium"]
      spot_percentage              = 100
      taints_lt                    = "--register-with-taints=dedicated=${local.environment}:NoSchedule"
      labels_lt                    = "--node-labels=eks.amazonaws.com/nodegroup=spotinst"
      image_id                     = "ami-0df33cb954c3f5200" ## If empty, update ami if available
      ebs_block_device = [
        {
          volume_type = "gp3"
          volume_size = 20
        },
      ]
      spotinst_tags = [
        {
          key   = "Environment"
          value = "${local.environment}"
        }
      ]
    }
  }
}  
```
#
## For update eks *Resolvido na v1.0.11*
#
```
terraform apply -target module.eks.aws_eks_cluster.eks_cluster
```
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
| <a name="module_node-spot"></a> [node-spot](#module\_node-spot) | ./modules/nodes-spot | n/a |
| <a name="module_nodes"></a> [nodes](#module\_nodes) | ./modules/nodes | n/a |
| <a name="module_proxy"></a> [proxy](#module\_proxy) | ./modules/addons | n/a |
| <a name="module_rbac"></a> [rbac](#module\_rbac) | ./modules/rbac | n/a |
| <a name="module_velero"></a> [velero](#module\_velero) | ./modules/helm | n/a |
| <a name="module_vpc-cni"></a> [vpc-cni](#module\_vpc-cni) | ./modules/addons | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eks_access_entry.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_policy_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_eks_cluster.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_iam_instance_profile.iam-node-instance-profile-eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_openid_connect_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_policy.amazon_eks_node_group_autoscaler_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.route53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.master](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.AmazonEC2RoleforSSM](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
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
| [kubernetes_annotations.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/annotations) | resource |
| [kubernetes_config_map_v1.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_config_map_v1_data.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1_data) | resource |
| [null_resource.wait_for_cluster](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_session_context.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_session_context) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [tls_certificate.this](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_spotinst"></a> [account\_spotinst](#input\_account\_spotinst) | n/a | `string` | `""` | no |
| <a name="input_additional_rules_security_group"></a> [additional\_rules\_security\_group](#input\_additional\_rules\_security\_group) | Rules extras security group | `any` | `{}` | no |
| <a name="input_authentication_mode"></a> [authentication\_mode](#input\_authentication\_mode) | The authentication mode for the cluster. Valid values are CONFIG\_MAP, API or API\_AND\_CONFIG\_MAP | `string` | `"API_AND_CONFIG_MAP"` | no |
| <a name="input_aws-autoscaler-controller"></a> [aws-autoscaler-controller](#input\_aws-autoscaler-controller) | Install release helm controller asg | `bool` | `false` | no |
| <a name="input_aws-ebs-csi-driver"></a> [aws-ebs-csi-driver](#input\_aws-ebs-csi-driver) | Install release helm controller ebs | `bool` | `false` | no |
| <a name="input_aws-efs-csi-driver"></a> [aws-efs-csi-driver](#input\_aws-efs-csi-driver) | Install release helm controller efs | `bool` | `false` | no |
| <a name="input_aws-load-balancer-controller"></a> [aws-load-balancer-controller](#input\_aws-load-balancer-controller) | Install release helm controller alb | `bool` | `false` | no |
| <a name="input_bootstrap_cluster_creator_admin_permissions"></a> [bootstrap\_cluster\_creator\_admin\_permissions](#input\_bootstrap\_cluster\_creator\_admin\_permissions) | Whether or not to bootstrap the access config values to the cluster | `bool` | `false` | no |
| <a name="input_bucket_name_velero"></a> [bucket\_name\_velero](#input\_bucket\_name\_velero) | Bucket name already created for use in velero conflicts with create\_bucket | `string` | `""` | no |
| <a name="input_cert-manager"></a> [cert-manager](#input\_cert-manager) | Install release helm controller cert-manager | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name cluster | `string` | `"k8s"` | no |
| <a name="input_create_access_entry"></a> [create\_access\_entry](#input\_create\_access\_entry) | Whether or not to bootstrap the access config values to the cluster | `bool` | `true` | no |
| <a name="input_create_aws_auth_configmap"></a> [create\_aws\_auth\_configmap](#input\_create\_aws\_auth\_configmap) | Create configmap aws-auth | `bool` | `false` | no |
| <a name="input_create_bucket"></a> [create\_bucket](#input\_create\_bucket) | Bucket use for velero conflicts with bucket\_name\_velero | `bool` | `false` | no |
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
| <a name="input_eks_access_entry"></a> [eks\_access\_entry](#input\_eks\_access\_entry) | Create Access Entry Configurations for an EKS Cluster | `any` | `{}` | no |
| <a name="input_enabled_cluster_log_types"></a> [enabled\_cluster\_log\_types](#input\_enabled\_cluster\_log\_types) | List of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging. | `list(string)` | `[]` | no |
| <a name="input_enabled_provider_spotinst"></a> [enabled\_provider\_spotinst](#input\_enabled\_provider\_spotinst) | n/a | `bool` | `false` | no |
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
| <a name="input_nodes"></a> [nodes](#input\_nodes) | Nodes general | `any` | `{}` | no |
| <a name="input_nodes_spot"></a> [nodes\_spot](#input\_nodes\_spot) | Nodes spotinst | `any` | `{}` | no |
| <a name="input_private_subnet"></a> [private\_subnet](#input\_private\_subnet) | List subnet nodes | `list(any)` | `[]` | no |
| <a name="input_public_access_cidrs"></a> [public\_access\_cidrs](#input\_public\_access\_cidrs) | List of CIDR blocks. Indicates which CIDR blocks can access the Amazon EKS public API server endpoint when enabled. EKS defaults this to a list with 0.0.0.0/0. | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_rbac"></a> [rbac](#input\_rbac) | Map rbac configuration | `any` | `{}` | no |
| <a name="input_security_additional"></a> [security\_additional](#input\_security\_additional) | Additional security grupo cluster | `bool` | `false` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Security group ids | `list(any)` | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet private | `list(any)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resource | `map(string)` | `{}` | no |
| <a name="input_token"></a> [token](#input\_token) | n/a | `string` | `""` | no |
| <a name="input_velero"></a> [velero](#input\_velero) | Install release helm velero | `bool` | `false` | no |
| <a name="input_version_chart_alb"></a> [version\_chart\_alb](#input\_version\_chart\_alb) | Version chart alb | `string` | `"1.7.1"` | no |
| <a name="input_version_chart_asg"></a> [version\_chart\_asg](#input\_version\_chart\_asg) | Version chart asg | `string` | `"9.37.0"` | no |
| <a name="input_version_chart_cert"></a> [version\_chart\_cert](#input\_version\_chart\_cert) | Version chart cert-manager | `string` | `"v1.14.4"` | no |
| <a name="input_version_chart_ebs"></a> [version\_chart\_ebs](#input\_version\_chart\_ebs) | Version chart ebs | `string` | `"2.31.0"` | no |
| <a name="input_version_chart_efs"></a> [version\_chart\_efs](#input\_version\_chart\_efs) | Version chart efs | `string` | `"3.0.3"` | no |
| <a name="input_version_chart_external_dns"></a> [version\_chart\_external\_dns](#input\_version\_chart\_external\_dns) | Version chart dns | `string` | `"1.14.4"` | no |
| <a name="input_version_chart_karpenter"></a> [version\_chart\_karpenter](#input\_version\_chart\_karpenter) | Install release helm karpenter | `string` | `"v0.34.0"` | no |
| <a name="input_version_chart_nginx"></a> [version\_chart\_nginx](#input\_version\_chart\_nginx) | Version chart nginx | `string` | `"4.10.0"` | no |
| <a name="input_version_chart_velero"></a> [version\_chart\_velero](#input\_version\_chart\_velero) | Version chart velero | `string` | `"6.1.0"` | no |
| <a name="input_version_image_velero"></a> [version\_image\_velero](#input\_version\_image\_velero) | Image version velero | `string` | `"v1.13.1"` | no |
| <a name="input_version_plugin_aws"></a> [version\_plugin\_aws](#input\_version\_plugin\_aws) | Image version velero | `string` | `"1.7.0"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC id | `string` | `""` | no |
| <a name="input_webhook_enabled"></a> [webhook\_enabled](#input\_webhook\_enabled) | webhook karpenter | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_auth"></a> [cluster\_auth](#output\_cluster\_auth) | n/a |
| <a name="output_cluster_cert"></a> [cluster\_cert](#output\_cluster\_cert) | n/a |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | n/a |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | n/a |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | n/a |
| <a name="output_cluster_oidc"></a> [cluster\_oidc](#output\_cluster\_oidc) | n/a |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | n/a |
| <a name="output_cluster_service_cidr"></a> [cluster\_service\_cidr](#output\_cluster\_service\_cidr) | n/a |
| <a name="output_cluster_version"></a> [cluster\_version](#output\_cluster\_version) | n/a |
| <a name="output_master-iam-arn"></a> [master-iam-arn](#output\_master-iam-arn) | n/a |
| <a name="output_master-iam-name"></a> [master-iam-name](#output\_master-iam-name) | n/a |
| <a name="output_node-iam-arn"></a> [node-iam-arn](#output\_node-iam-arn) | n/a |
| <a name="output_node-iam-name"></a> [node-iam-name](#output\_node-iam-name) | n/a |
| <a name="output_node-iam-name-profile"></a> [node-iam-name-profile](#output\_node-iam-name-profile) | n/a |
| <a name="output_oidc_arn"></a> [oidc\_arn](#output\_oidc\_arn) | n/a |
| <a name="output_oidc_url"></a> [oidc\_url](#output\_oidc\_url) | n/a |
