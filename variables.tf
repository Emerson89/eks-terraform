variable "token" {
  type    = string
  default = ""
}

variable "account_spotinst" {
  type    = string
  default = ""
}

variable "enabled_provider_spotinst" {
  type    = bool
  default = false
}

variable "nodes" {
  description = "Nodes general"
  type        = any
  default     = {}
}

variable "nodes_spot" {
  description = "Nodes spotinst"
  type        = any
  default     = {}
}

variable "domain" {
  description = "Domain used helm External dns"
  type        = string
  default     = ""
}

variable "custom_values_cert_manager" {
  description = "Custom controler cert-manager a Release is an instance of a chart running in a Kubernetes cluster"
  type        = any
  default     = {}
}

variable "custom_values_nginx" {
  description = "Custom controler ingress-nginx a Release is an instance of a chart running in a Kubernetes cluster"
  type        = any
  default     = {}
}

variable "custom_helm" {
  description = "Custom a Release is an instance of a chart running in a Kubernetes cluster."
  type        = map(any)
  default     = {}
}

variable "custom_values_alb" {
  description = "Custom controler alb a Release is an instance of a chart running in a Kubernetes cluster"
  type        = any
  default     = {}
}

variable "custom_values_ebs" {
  description = "Custom controller ebs a Release is an instance of a chart running in a Kubernetes cluster"
  type        = any
  default     = {}
}

variable "custom_values_asg" {
  description = "Custom controller asg a Release is an instance of a chart running in a Kubernetes cluster"
  type        = any
  default     = {}
}

variable "custom_values_external-dns" {
  description = "Custom external-dns a Release is an instance of a chart running in a Kubernetes cluster"
  type        = any
  default     = {}
}

variable "custom_values_metrics-server" {
  description = "Custom metrics-server a Release is an instance of a chart running in a Kubernetes cluster"
  type        = any
  default     = {}
}

variable "velero" {
  description = "Install release helm velero "
  type        = bool
  default     = false
}

variable "create_bucket" {
  description = "Bucket use for velero conflicts with bucket_name_velero"
  type        = bool
  default     = false
}

variable "bucket_name_velero" {
  description = "Bucket name already created for use in velero conflicts with create_bucket"
  type        = string
  default     = ""
}

variable "version_image_velero" {
  description = "Image version velero"
  type        = string
  default     = "v1.13.1"
}

variable "custom_values_velero" {
  description = "Custom velero a Release is an instance of a chart running in a Kubernetes cluster"
  type        = any
  default     = {}
}

variable "karpenter" {
  description = "Install release helm karpenter "
  type        = bool
  default     = false
}

variable "version_chart_karpenter" {
  description = "Install release helm karpenter "
  type        = string
  default     = "v0.34.0"
}

variable "custom_values_karpenter" {
  description = "Custom karpenter a Release is an instance of a chart running in a Kubernetes cluster"
  type        = any
  default     = {}
}

variable "force_destroy" {
  description = "Boolean that indicates all objects (including any locked objects) should be deleted from the bucket when the bucket is destroyed so that the bucket can be destroyed without error"
  type        = bool
  default     = false
}

variable "aws-ebs-csi-driver" {
  description = "Install release helm controller ebs"
  type        = bool
  default     = false
}

variable "ingress-nginx" {
  description = "Install release helm controller ingress-nginx"
  type        = bool
  default     = false
}

variable "cert-manager" {
  description = "Install release helm controller cert-manager"
  type        = bool
  default     = false
}

variable "aws-load-balancer-controller" {
  description = "Install release helm controller alb"
  type        = bool
  default     = false
}

variable "external-dns" {
  description = "Install release helm external"
  type        = bool
  default     = false
}

variable "metrics-server" {
  description = "Install release helm metrics-server"
  type        = bool
  default     = false
}

variable "aws-autoscaler-controller" {
  description = "Install release helm controller asg"
  type        = bool
  default     = false
}

variable "private_subnet" {
  description = "List subnet nodes"
  type        = list(any)
  default     = []
}
## Clusters

variable "environment" {
  description = "Env tags"
  type        = string
  default     = null
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "Name cluster"
  type        = string
  default     = "k8s"
}

variable "kubernetes_version" {
  description = "Version kubernetes"
  type        = string
  default     = "1.23"
}

variable "endpoint_public_access" {
  description = "Endpoint access public"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Endpoint access private"
  type        = bool
  default     = false
}

variable "security_group_ids" {
  description = "Security group ids"
  type        = list(any)
  default     = []
}

variable "subnet_ids" {
  description = "Subnet private"
  type        = list(any)
  default     = []
}

variable "enabled_cluster_log_types" {
  description = "List of the desired control plane logging to enable. For more information, see Amazon EKS Control Plane Logging."
  type        = list(string)
  default     = []
}

variable "create_ebs" {
  description = "Install addons ebs"
  type        = bool
  default     = false
}

variable "create_core" {
  description = "Install addons core"
  type        = bool
  default     = false
}

variable "create_vpc_cni" {
  description = "Install addons vpc_cni"
  type        = bool
  default     = false
}

variable "create_proxy" {
  description = "Install addons proxy"
  type        = bool
  default     = false
}

variable "mapRoles" {
  description = "List of role maps to add to the aws-auth configmap"
  type        = list(any)
  default     = []
}

variable "mapUsers" {
  description = "List of user maps to add to the aws-auth configmap"
  type        = list(any)
  default     = []
}

variable "mapAccounts" {
  description = "List of accounts maps to add to the aws-auth configmap"
  type        = list(any)
  default     = []
}

variable "create_aws_auth_configmap" {
  description = "Create configmap aws-auth"
  type        = bool
  default     = false
}

variable "manage_aws_auth_configmap" {
  description = "Manager configmap aws-auth"
  type        = bool
  default     = true
}

variable "filesystem_id" {
  description = "Filesystem used helm efs"
  type        = string
  default     = "fs-92107410"
}

variable "custom_values_efs" {
  description = "Custom controler efs a Release is an instance of a chart running in a Kubernetes cluster"
  type        = any
  default     = {}
}

variable "aws-efs-csi-driver" {
  description = "Install release helm controller efs"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC id"
  type        = string
  default     = ""
}

variable "security_additional" {
  description = "Additional security grupo cluster"
  type        = bool
  default     = false
}

variable "additional_rules_security_group" {
  description = "Rules extras security group"
  type        = any
  default     = {}
}

variable "fargate_auth" {
  description = "Auth role fargate profile"
  type        = bool
  default     = false
}

variable "rbac" {
  description = "Map rbac configuration"
  type        = any
  default     = {}
}

variable "version_chart_velero" {
  description = "Version chart velero"
  type        = string
  default     = "6.1.0"
}

variable "version_plugin_aws" {
  description = "Image version velero"
  type        = string
  default     = "1.7.0"
}

variable "version_chart_nginx" {
  description = "Version chart nginx"
  type        = string
  default     = "4.10.0"
}

variable "version_chart_cert" {
  description = "Version chart cert-manager"
  type        = string
  default     = "v1.14.4"
}

variable "version_chart_efs" {
  description = "Version chart efs"
  type        = string
  default     = "3.0.3"
}

variable "version_chart_ebs" {
  description = "Version chart ebs"
  type        = string
  default     = "2.31.0"
}

variable "version_chart_alb" {
  description = "Version chart alb"
  type        = string
  default     = "1.7.1"
}

variable "version_chart_asg" {
  description = "Version chart asg"
  type        = string
  default     = "9.37.0"
}

variable "version_chart_external_dns" {
  description = "Version chart dns"
  type        = string
  default     = "1.14.4"
}

variable "authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are CONFIG_MAP, API or API_AND_CONFIG_MAP"
  type        = string
  default     = "API_AND_CONFIG_MAP"
}

variable "create_access_entry" {
  description = "Whether or not to bootstrap the access config values to the cluster"
  type        = bool
  default     = true
}

variable "eks_access_entry" {
  description = "Create Access Entry Configurations for an EKS Cluster"
  type        = any
  default     = {}
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Whether or not to bootstrap the access config values to the cluster"
  type        = bool
  default     = false
}
